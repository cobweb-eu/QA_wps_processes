package pillar.lbs;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import org.apache.commons.math3.distribution.NormalDistribution;
import org.apache.commons.math3.random.RandomGenerator;
import org.apache.commons.math3.random.Well44497b;
import org.apache.log4j.Logger;
import org.geotools.data.collection.ListFeatureCollection;
import org.geotools.data.simple.SimpleFeatureIterator;
import org.geotools.feature.FeatureCollection;
import org.geotools.feature.simple.SimpleFeatureBuilder;
import org.geotools.feature.simple.SimpleFeatureTypeBuilder;
import org.geotools.referencing.crs.DefaultGeographicCRS;
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
import org.opengis.referencing.crs.CoordinateReferenceSystem;

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
 * @author Julian Rosser - UNott - Julian.Rosser@nottingham.ac.uk
 */
public class GetLineOfSight extends AbstractAlgorithm {
	
	/*
	public static void main(String[] args) {
		double obsDistance = 4; //ie. will be the mean in distribution test.   
		double CEP68_SDev = 2;  // ie. the accuracy of the mobile phone.
		double XYAccuracyOfDem_SDev = 2; //ie. the horiz accuracy of the DEM. 
		double thresholdLoSDistance= 0.2; // threshold for stat test.		
		double[] accuracyMedata = computeAccuracyMetadata(obsDistance,CEP68_SDev,XYAccuracyOfDem_SDev,thresholdLoSDistance);
	}*/
	
	
	public double DQ_UsabilityElement = (double) -999;
	public double DQ_TopologicalConsistency = (double) -999;
	public double DQ_AbsoluteExternalPositionalAccuracy = (double)-999; 		
	
	
	
	public static final String INPUT_OBS = "inputObservations";
	public static final String INPUT_SURFACEMODEL = "inputSurfaceModel";
	public static final String INPUT_BEARINGNAME = "inputBearingFieldName";
	public static final String INPUT_TILTNAME = "inputTiltFieldName";
	public static final String INPUT_USERHEIGHT = "inputUserHeight";
	
	Logger LOGGER = Logger.getLogger(GetLineOfSight.class);
	
	private ArrayList<String> errorList;
	
	public GetLineOfSight() {
		super();
		this.errorList = new ArrayList<String>();
	}

	@Override
	public Map<String, IData> run(Map<String, List<IData>> inputData) throws ExceptionReport {
		System.setProperty("org.geotools.referencing.forceXY", "true");
		
		LOGGER.debug("Starting web process...");
		
		
		// hold inputs from WPS
		FeatureCollection pointInputs;
		GenericFileData surfaceModel;
		String bearingFieldName, tiltFieldName;
		double userHeight = 1.5;
		
		
		//Default, test values
		double obsDistance = 4; //ie. will be the mean in distribution test.   
		double CEP68_SDev = 2;  // ie. the accuracy of the mobile phone.
		double XYAccuracyOfDem_SDev = 2; //ie. the horiz accuracy of the DEM. 
		double thresholdLoSDistance= 0.2; // threshold for stat test.
		
		
		
		LOGGER.warn("Getting web process params...");
		LOGGER.warn("surfaceModel:");
		LOGGER.warn(inputData.get(INPUT_SURFACEMODEL).get(0).toString());
		LOGGER.warn(inputData.get(INPUT_SURFACEMODEL).toString());
		LOGGER.warn(inputData.toString());
		LOGGER.warn(inputData.get(INPUT_SURFACEMODEL));
		LOGGER.warn(inputData.get(INPUT_SURFACEMODEL).get(0).getPayload());
		LOGGER.warn(inputData.get(INPUT_SURFACEMODEL).get(0).getPayload().toString());
		
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
		
	
		//CoordinateReferenceSystem inputCRS = outType.getCoordinateReferenceSystem();
		//System.out.println("Input points CRS: " + inputCRS.toWKT());
		
		
		// Get ready to loop through all features
		SimpleFeatureIterator iterator = (SimpleFeatureIterator) pointInputs.features();
		ArrayList<SimpleFeature> featureList = new ArrayList<SimpleFeature>();
		LineOfSight los = new LineOfSight(heightMap, 0, 0, 0, 0, userHeight);
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
				double horizontalDistance;								

				try {
					los.setBearing(compass);
					los.setTilt(tilt);
					los.setCurrentEasting(position.x);
					los.setCurrentNorthing(position.y);
					
					double[] result = los.calculateLOS();

					easting = result[2];
					northing = result[3];
					horizontalDistance = result[0];
					
					
					//Set the metadata values
					double[] accuracyMedata = computeAccuracyMetadata(horizontalDistance,CEP68_SDev,XYAccuracyOfDem_SDev,thresholdLoSDistance);
					DQ_UsabilityElement = accuracyMedata[0];
					DQ_TopologicalConsistency = accuracyMedata[1];
					DQ_AbsoluteExternalPositionalAccuracy =accuracyMedata[2]; 						
					
				} catch(IntersectionException e) {
					LOGGER.warn("No intersection with heightmap (" + e.getClass().getSimpleName() + "): " + e.getMessage());
					easting = -1;
					northing = -1;
					
					horizontalDistance = -1;										
					
					//Set the metadata values  
					DQ_UsabilityElement = 0;
					DQ_TopologicalConsistency = 0;
					DQ_AbsoluteExternalPositionalAccuracy = 0;
				}
				
				// Set results as result feature geometry
				GeometryFactory gf = new GeometryFactory();
				Point point = gf.createPoint(new Coordinate(easting, northing));
				
				SimpleFeature feature = builder.buildFeature(String.valueOf(counter));
				feature.setDefaultGeometry(point);
				feature.setAttribute("DQ_UsabilityElement", DQ_UsabilityElement);
				feature.setAttribute("DQ_TopologicalConsistency", DQ_TopologicalConsistency);
				feature.setAttribute("DQ_AbsoluteExternalPositionalAccuracy", DQ_AbsoluteExternalPositionalAccuracy );
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

		
		//Need to make sure we define the CRS properly. 
		//GeoTools will try and default to WGS84 but we need to have the same output as input (e.g. projected coords). 
        if (inputs.getSchema().getCoordinateReferenceSystem() == null) { 
        		System.out.println("CRS not defined. Defaulting to WGS84");
	            builder.setCRS(DefaultGeographicCRS.WGS84); 
	    } else { 	    		
	            builder.setCRS(inputs.getSchema().getCoordinateReferenceSystem());
	            System.out.println("CRS defined. Defining with: " + inputs.getSchema().getCoordinateReferenceSystem().toWKT());
	    } 

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
			
			System.out.println("Building feature from property: " + name);			
			Class<String> valueClass = (Class<String>) tempProp.getType().getBinding();			
			builder.add(name, valueClass);			
		}
		
		builder.add("easting", Double.class);
		builder.add("northing", Double.class);
		
		//Metadata elements
		builder.add("DQ_UsabilityElement", Double.class);
		builder.add("DQ_TopologicalConsistency", Double.class);
		builder.add("DQ_AbsoluteExternalPositionalAccuracy", Double.class);
						
		return builder.buildFeatureType();
	}
	

	
	/**
	 * Compute accuracy details for metadata
	 * 
	 * Uses the observed distance from los, device accuracy (CEP68), 
	 * dem planimetric acc, and a user defined threshold for determining accuracy metadata.
	 * To do: DQ_TopologicalConsistency value  
	 * @param observedDistance, phoneAccuracy (CEP68), DEM accuracy, threshold.
	 * @return some accuracy metadata to get bunged in with the obs:
	 * 				array(Dq_usability,  DQ_TopologicalConsistency, DQ_AbsoluteExternalPositionalAccuracy)
	 * 
	 */
	private static double[] computeAccuracyMetadata(double obsDistance,double CEP68_SDev, double XYAccuracyOfDem_SDev,double thresholdLoSDistance) {		
		/* prototype R code
		DQUsa = 1-p
				where
				p = P(D>t)
				and where D = N(Obs, Du)
				and t =0.10 (user defined)
				E.g.
				pnorm(t = 0.10,mean=Obs,sd= Du ,lower.tail=FALSE)
				*/				
		System.out.println("testing...");
		
		//Compute the uncertainty of the LoS point. Intuitively, a function of the sensor and the DEM horizontal accuracies)
		double LoS_uncert= Math.sqrt(Math.pow(CEP68_SDev,2)+Math.pow(XYAccuracyOfDem_SDev,2));
		
		//Compute the uncertainty of the LoS distance. Intuitively, a function of the sensor and the LoS accuracy).
		double Dist_uncert = Math.sqrt(Math.pow(CEP68_SDev,2)+Math.pow(LoS_uncert,2));
			
		System.out.println(LoS_uncert);
		System.out.println(Dist_uncert);
		
		//Construct a normal dist of the observed distance (mu) with the dist uncert (sigma).   
		NormalDistribution d = new NormalDistribution(obsDistance, Dist_uncert, NormalDistribution.DEFAULT_INVERSE_ABSOLUTE_ACCURACY);
		double cumulPrb = 1-d.cumulativeProbability(thresholdLoSDistance);
		System.out.println("cumnulPrb: ");
		System.out.println(cumulPrb);				

		double[] currentResult = new double[]{cumulPrb, 0, LoS_uncert}; 
		return currentResult;			
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
