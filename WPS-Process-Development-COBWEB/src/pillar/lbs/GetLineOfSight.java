package pillar.lbs;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import org.apache.log4j.Logger;
import org.geotools.data.collection.ListFeatureCollection;
import org.geotools.data.simple.SimpleFeatureIterator;
import org.geotools.feature.FeatureCollection;
import org.geotools.feature.simple.SimpleFeatureBuilder;
import org.geotools.feature.simple.SimpleFeatureTypeBuilder;
import org.n52.wps.io.data.GenericFileData;
import org.n52.wps.io.data.IData;
import org.n52.wps.io.data.binding.complex.GTVectorDataBinding;
import org.n52.wps.io.data.binding.complex.GenericFileDataBinding;
import org.n52.wps.io.data.binding.literal.LiteralDoubleBinding;
import org.n52.wps.io.data.binding.literal.LiteralStringBinding;
import org.n52.wps.server.AbstractAlgorithm;
import org.n52.wps.server.ExceptionReport;
import org.opengis.feature.Property;
import org.opengis.feature.simple.SimpleFeature;
import org.opengis.feature.simple.SimpleFeatureType;

import com.vividsolutions.jts.geom.Coordinate;
import com.vividsolutions.jts.geom.Geometry;
import com.vividsolutions.jts.geom.GeometryFactory;
import com.vividsolutions.jts.geom.Point;

import eu.cobwebproject.qa.lbs.IntersectionException;
import eu.cobwebproject.qa.lbs.LineOfSight;
import eu.cobwebproject.qa.lbs.Raster;

/**
 * WPS Process to integrate with the cobweb-qa line of sight functionality
 * 
 * @author Sebastian Clarke - Environment Systems - sebastian.clarke@envsys.co.uk
 */
public class GetLineOfSight extends AbstractAlgorithm {
	
	public static final String INPUT_OBS = "inputObservations";
	public static final String INPUT_SURFACEMODEL = "inputSurfaceModel";
	public static final String INPUT_BEARINGNAME = "inputBaringFieldName";
	public static final String INPUT_TILTNAME = "inputTiltFieldName";
	public static final String INPUT_USERHEIGHT = "inputUserHeight";
	
	Logger LOGGER = Logger.getLogger(LineOfSightCoordinates.class);
	
	private ArrayList<String> errorList;
	
	public GetLineOfSight() {
		super();
		this.errorList = new ArrayList<String>();
	}

	@Override
	public Map<String, IData> run(Map<String, List<IData>> inputData) throws ExceptionReport {
		System.setProperty("org.geotools.referencing.forceXY", "true");
		
		// hold inputs from WPS
		FeatureCollection pointInputs;
		GenericFileData surfaceModel;
		String bearingFieldName, tiltFieldName;
		double userHeight;
		
		// get params from WPS
		pointInputs = ((GTVectorDataBinding) inputData.get(INPUT_OBS).get(0)).getPayload();
		surfaceModel = ((GenericFileDataBinding) inputData.get(INPUT_SURFACEMODEL).get(0)).getPayload();
		bearingFieldName = ((LiteralStringBinding) inputData.get(INPUT_BEARINGNAME).get(0)).getPayload();
		tiltFieldName = ((LiteralStringBinding) inputData.get(INPUT_TILTNAME).get(0)).getPayload();
		userHeight = ((LiteralDoubleBinding) inputData.get(INPUT_USERHEIGHT).get(0)).getPayload();
		
		// Try and read the raster
		Raster heightMap = null;
		try {
			heightMap = new Raster(surfaceModel.getBaseFile(true).getAbsolutePath());
		} catch (IOException e) {
			LOGGER.error("Could not read from provided surface model", e);
			throw new ExceptionReport("Could not read from provided surface model: " + e.getMessage(), "IOException", e.getCause());
		}
		
		// Create FeatureBuilder for features based on provided features
		SimpleFeatureType outType = buildFeatureType(pointInputs);
		SimpleFeatureBuilder builder = new SimpleFeatureBuilder(outType);
		
		// Get ready to loop through all features
		SimpleFeatureIterator iterator = (SimpleFeatureIterator) pointInputs.features();
		ArrayList<SimpleFeature> featureList = new ArrayList<SimpleFeature>();
		LineOfSight los = new LineOfSight(heightMap, 0, 0, 0, 0, 1.5);
		int counter = 0;
		
		try {
			while(iterator.hasNext()) {
				SimpleFeature inputFeature = iterator.next();

				// copy existing properties to new feature
				for (Property obsProperty : inputFeature.getProperties()){
					builder.set(obsProperty.getName().toString(), obsProperty.getValue());
				}
				
				// Get position and orientation from feature
				Coordinate position = ((Geometry) inputFeature.getDefaultGeometry()).getCoordinate();
				double tilt = Double.valueOf(inputFeature.getAttribute(tiltFieldName).toString());
				double compass = Double.valueOf(inputFeature.getAttribute(bearingFieldName).toString());
				
				// Run line of sight calculation for position defined in feature
				double easting, northing;
				try {
					los.setBearing(compass);
					los.setTilt(tilt);
					los.setCurrentEasting(position.x);
					los.setCurrentNorthing(position.y);
					
					double[] result = los.calculateLOS();
					easting = result[2];
					northing = result[3];
				} catch(IntersectionException e) {
					LOGGER.warn("No intersection with heightmap: " + e.getMessage());
					easting = -1;
					northing = -1;
				}
				
				// Set results as result feature geometry
				GeometryFactory gf = new GeometryFactory();
				Point point = gf.createPoint(new Coordinate(easting, northing));
				
				SimpleFeature feature = builder.buildFeature(String.valueOf(counter));
				feature.setDefaultGeometry(point);
				
				// add to feature list
				featureList.add(feature);
				counter++;
			}
		} finally {
			iterator.close();
		}
		
		// return outputs as FeatureCollection
		FeatureCollection returnOutput = new ListFeatureCollection(outType, featureList);
		HashMap<String, IData> result = new HashMap<String, IData>();
		result.put("result", new GTVectorDataBinding(returnOutput));
		
		return result;
	}
	
	/**
	 * Builds output SimpleFeatureType from a sample list of input features
	 * 
	 * Uses the first feature in the list as a template, and adds output fields
	 * @param inputs
	 * @return SimpleFeatureType representing our output features
	 */
	private SimpleFeatureType buildFeatureType(FeatureCollection inputs) {
		
		SimpleFeatureTypeBuilder builder = new SimpleFeatureTypeBuilder();
		builder.setName("LineOfSight Output");

		// Get sample feature from collection
		SimpleFeatureIterator sfi = (SimpleFeatureIterator) inputs.features();
		SimpleFeature sample = null;
		try {
			sample = sfi.next();
		} finally {
			sfi.close();
		}
	
		// Get the properties from sample feature
		Collection<Property> properties = sample.getProperties();	
		Iterator<Property> propertiesIter = properties.iterator();
		
		while (propertiesIter.hasNext()) {
			Property tempProp = propertiesIter.next();
			String name = tempProp.getDescriptor().getType().getName().getLocalPart();
			Class<String> valueClass = (Class<String>) tempProp.getType().getBinding();
			
			builder.add(name, valueClass);
			LOGGER.warn ("Obs property " + name + " " + valueClass);	
		}
		
		builder.add("easting", Double.class);
		builder.add("northing", Double.class);
		
		return builder.buildFeatureType();
	}
	

	@Override
	public Class<?> getInputDataType(String identifier) {
		if(identifier.equalsIgnoreCase(INPUT_OBS))
			return GTVectorDataBinding.class;
		if(identifier.equalsIgnoreCase(INPUT_SURFACEMODEL))
			return GenericFileDataBinding.class;
		if(identifier.equalsIgnoreCase(INPUT_BEARINGNAME))
			return LiteralStringBinding.class;
		if(identifier.equalsIgnoreCase(INPUT_TILTNAME))
			return LiteralStringBinding.class;
		if(identifier.equalsIgnoreCase(INPUT_USERHEIGHT))
			return LiteralDoubleBinding.class;
		return null;
	}

	@Override
	public Class<?> getOutputDataType(String identifier) {
		if(identifier.equalsIgnoreCase("result")){
			return GTVectorDataBinding.class;
		}

		return null;
	}

	@Override
	public List<String> getErrors() {
		return errorList;
	}
	
	
	
}
