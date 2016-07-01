package pillar4.authoritativedata;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.log4j.Logger;
import org.geotools.data.simple.SimpleFeatureCollection;
import org.geotools.data.simple.SimpleFeatureIterator;
import org.geotools.factory.CommonFactoryFinder;
import org.geotools.factory.GeoTools;
import org.geotools.feature.FeatureCollection;
import org.geotools.feature.FeatureCollections;
import org.geotools.feature.simple.SimpleFeatureBuilder;
import org.geotools.feature.simple.SimpleFeatureTypeBuilder;
import org.geotools.geometry.jts.JTS;
import org.geotools.referencing.CRS;
import org.geotools.referencing.GeodeticCalculator;
import org.n52.wps.io.data.IData;
import org.n52.wps.io.data.binding.complex.GTVectorDataBinding;
import org.n52.wps.io.data.binding.complex.GenericFileDataBinding;
import org.n52.wps.io.data.binding.literal.LiteralDoubleBinding;
import org.n52.wps.server.AbstractAlgorithm;
import org.n52.wps.server.ExceptionReport;
import org.opengis.feature.simple.SimpleFeature;
import org.opengis.feature.simple.SimpleFeatureType;
import org.opengis.filter.FilterFactory2;
import org.opengis.referencing.FactoryException;
import org.opengis.referencing.NoSuchAuthorityCodeException;
import org.opengis.referencing.crs.CRSAuthorityFactory;
import org.opengis.referencing.crs.CoordinateReferenceSystem;
import org.opengis.referencing.operation.TransformException;

import com.vividsolutions.jts.awt.PointShapeFactory.Point;
import com.vividsolutions.jts.geom.Coordinate;
import com.vividsolutions.jts.geom.Geometry;
import com.vividsolutions.jts.geom.GeometryFactory;


public class PositionDistanceRange extends AbstractAlgorithm {
	
	/**
	 * @author Frances Moore
	 * Javadoc needs completing.
	 */
	
	Logger LOGGER = Logger.getLogger(PositionDistanceRange.class);
	
	public List<String> getErrors() {
		// TODO Auto-generated method stub
		return null;
	}

	public Class<?> getInputDataType(String identifier) {
		if(identifier.equalsIgnoreCase("inputObservations")){
			return GTVectorDataBinding.class;
		}
		if (identifier.equalsIgnoreCase("inputAuthoritativeData")){
			return GTVectorDataBinding.class;
		}
		if (identifier.equalsIgnoreCase("minDistance")){
			return LiteralDoubleBinding.class;
		}
		if (identifier.equalsIgnoreCase("maxDistance")){
			return LiteralDoubleBinding.class;
		}
		
		return null;
	}

	public Class<?> getOutputDataType(String identifier) {
		if(identifier.equalsIgnoreCase("result")){
			return GTVectorDataBinding.class;
		}
		return null;
	}
	
	public Map<String, IData> run(Map<String, List<IData>> inputData)
			throws ExceptionReport {
		
		List <IData> inputObs = inputData.get("inputObservations");
		List <IData> inputAuth = inputData.get("inputAuthoritativeData");
		 
		// Cast the input observations as a FeatureCollection
		FeatureCollection obsFcW = ((GTVectorDataBinding) inputObs.get(0)).getPayload();
		FeatureCollection authFc = ((GTVectorDataBinding) inputAuth.get(0)).getPayload();
		
		double avgDist = 0;
		
		double minVal = ((LiteralDoubleBinding)(inputData.get("minDistance").get(0))).getPayload(); 
		double maxVal = ((LiteralDoubleBinding)(inputData.get("maxDistance").get(0))).getPayload(); 
		
		SimpleFeatureIterator obsIt2 = (SimpleFeatureIterator) obsFcW.features();
		
		SimpleFeatureCollection resultColl = FeatureCollections.newCollection();
		
		while (obsIt2.hasNext()==true)
		{
			
			SimpleFeature tempSf = obsIt2.next();	
			
			Geometry obsGeom = (Geometry) tempSf.getDefaultGeometry();
			
			SimpleFeatureIterator authIt = (SimpleFeatureIterator) authFc.features();
			
			while (authIt.hasNext()==true)
			{
				SimpleFeature tempAuth = authIt.next();
				
				Geometry authGeom = (Geometry) tempAuth.getDefaultGeometry();
				
				
				FilterFactory2 ff = CommonFactoryFinder.getFilterFactory2(GeoTools.getDefaultHints());
				
				LOGGER.warn("obsgeom point is " + obsGeom.getCoordinate().x + " " + obsGeom.getCoordinate().y);
				LOGGER.warn("authgeom point is " + authGeom.getCoordinate().x + " " + authGeom.getCoordinate().y);
				
				CoordinateReferenceSystem sourceCRS = null;
				
				CoordinateReferenceSystem projectCRS = null;
				
				CRSAuthorityFactory   factory = CRS.getAuthorityFactory(true);
				try 
				{
					sourceCRS = factory.createCoordinateReferenceSystem("EPSG:4326");
					projectCRS = factory.createCoordinateReferenceSystem("EPSG:27700");
				} 
				catch (NoSuchAuthorityCodeException e1) 
				{
					// TODO Auto-generated catch block
					e1.printStackTrace();
				} 
				catch (FactoryException e1) 
				{
					// TODO Auto-generated catch block
					e1.printStackTrace();
				}
		
				// Create the coordinates for observation and authoritative feature set so the distance between the two can be calculated
				Coordinate coord = obsGeom.getCoordinate();
				Coordinate authCoord = authGeom.getCoordinate();
				   
				GeodeticCalculator gc = new GeodeticCalculator(sourceCRS);
			    
				try 
				{
					// Set the start and destination position to check
					gc.setStartingPosition( JTS.toDirectPosition( coord, sourceCRS ) );
					gc.setDestinationPosition( JTS.toDirectPosition( authCoord, sourceCRS ) );
					// Get the distance
					double distance = gc.getOrthodromicDistance();
				    avgDist += distance;
				    
				    LOGGER.warn("distance between the two is " + distance);
				    LOGGER.warn("average distance is " + avgDist);
				   
				    // Check that the distance is between the maximum and minimum "expert" range
				    if (distance >= minVal && distance <= maxVal)
				    {
				    	// Distance is within the range
				    	LOGGER.warn("distance is in an acceptable range " + distance);
				  
				    	// Create a new feature to add to the result collection, with the additional ISO fields added
				    	SimpleFeatureType sft  = (SimpleFeatureType)obsFcW.getSchema();
						SimpleFeatureTypeBuilder stb = new SimpleFeatureTypeBuilder();
						stb.init(sft);
						stb.setName("newFeatureType");
						
						// Add the new Relative Accuracy attribute
						stb.add("ISO19157.SpatialAccuracy.RelativeAccuracy", String.class);
						// Add the new stakeholder reliability attribute
						stb.add("ISO19157.ThematicAccuracy.NonQuantitativeAttributeCorrectness", String.class);
							
						SimpleFeatureType newFeatureType = stb.buildFeatureType();
							
						SimpleFeatureBuilder sfb = new SimpleFeatureBuilder(newFeatureType);
						sfb.addAll(tempSf.getAttributes());
						// Currently commented out - not sure which field from the authoritative dataset to take
						//sfb.set("ISO19157.SpatialAccuracy.RelativeAccuracy", tempAuth.getAttribute("relative auth field to go here")); 
						sfb.set("ISO19157.ThematicAccuracy.NonQuantitativeAttributeCorrectness", tempAuth.getAttribute("fieldcon_1")); 
							
						SimpleFeature newFeature = sfb.buildFeature(null);
					            
					    newFeature.setDefaultGeometry(obsGeom);
					    resultColl.add(newFeature);
				    }
				    
				} catch (TransformException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
					LOGGER.warn(e.getMessage());
				}
				
			}
		
		}
		
		avgDist = avgDist / obsFcW.size();
		
		LOGGER.warn("final avg dist is " + avgDist);
		
		 
		    
		
		HashMap<String, IData> results = new HashMap<String, IData>();
		// Check if the criteria to apply feedback ratings etc. was met
		if (resultColl.isEmpty())
		{
			// The results feature collection was populated, so the critera was met
			// Extra fields have been added to the feature collection, return this one
			results.put("result", new GTVectorDataBinding((FeatureCollection)obsFcW));
		}
		else
		{
			// Criteria not met, return original observations without metadata
			results.put("result", new GTVectorDataBinding((FeatureCollection)resultColl));
		}
		return results;
	}
	
}
	

