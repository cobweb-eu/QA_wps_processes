package pillar.bigdata;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.ListIterator;
import java.util.Map;

import org.apache.log4j.Logger;
import org.geotools.data.simple.SimpleFeatureCollection;
import org.geotools.data.simple.SimpleFeatureIterator;
import org.geotools.feature.FeatureCollection;
import org.geotools.feature.FeatureCollections;
import org.geotools.feature.simple.SimpleFeatureBuilder;
import org.geotools.feature.simple.SimpleFeatureTypeBuilder;
import org.n52.wps.io.data.IData;
import org.n52.wps.io.data.binding.complex.GTVectorDataBinding;
import org.n52.wps.io.data.binding.complex.GenericFileDataBinding;
import org.n52.wps.io.data.binding.literal.LiteralDoubleBinding;
import org.n52.wps.server.AbstractAlgorithm;
import org.n52.wps.server.ExceptionReport;
import org.opengis.feature.simple.SimpleFeature;
import org.opengis.feature.simple.SimpleFeatureType;

import com.vividsolutions.jts.geom.Coordinate;
import com.vividsolutions.jts.geom.Geometry;


public class PositionDistanceRange extends AbstractAlgorithm {
	Logger LOGGER = Logger.getLogger(PositionDistanceRange.class);
	
	public List<String> getErrors() {
		// TODO Auto-generated method stub
		return null;
	}

	public Class<?> getInputDataType(String identifier) {
		if(identifier.equalsIgnoreCase( "inputObservations")){
			return GTVectorDataBinding.class;
		}
		
		if (identifier.equalsIgnoreCase("minDistance")){
			return LiteralDoubleBinding.class;
		}
		if (identifier.equalsIgnoreCase("maxDistance")){
			return LiteralDoubleBinding.class;
		}
		if (identifier.equalsIgnoreCase("score")){
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
		// Get the inputData values
		List <IData> inputObs = inputData.get("inputObservations");
		
		FeatureCollection obsFcW = ((GTVectorDataBinding) inputObs.get(0)).getPayload();
		
		double minVal = ((LiteralDoubleBinding)(inputData.get("minDistance").get(0))).getPayload(); 
		double maxVal = ((LiteralDoubleBinding)(inputData.get("maxDistance").get(0))).getPayload(); 
		double score = ((LiteralDoubleBinding)(inputData.get("score").get(0))).getPayload(); 
		
		SimpleFeatureIterator obsIt2 = (SimpleFeatureIterator) obsFcW.features();
		
		// Create an array list of geometries for checking purposes
		ArrayList<Geometry> geomChecks = new ArrayList<Geometry>(); 

		
		// Loop through the observations a first time to retrieve the list of geometries 
		while (obsIt2.hasNext()==true)
		{
			SimpleFeature tempSf = obsIt2.next();	

			Geometry obsGeom = (Geometry) tempSf.getDefaultGeometry();
			geomChecks.add(obsGeom);
			
		}
		
		
		SimpleFeature tempSfCheck = null;
		Geometry obsGeomCheck = null;
		
		boolean allInRange = false;
		
		// Create another instance of a simple feature iterator as the observations should be looped through again
		SimpleFeatureIterator obsIt3 = (SimpleFeatureIterator) obsFcW.features();
		
		while (obsIt3.hasNext()==true)
		{
			
			tempSfCheck = obsIt3.next();	
			
			obsGeomCheck = (Geometry) tempSfCheck.getDefaultGeometry();
			
			
			
			// Create an iterator to loop through the list of geometries
			ListIterator litr = geomChecks.listIterator();
		    while(litr.hasNext()) 
		    {
		    
		         Geometry element = (Geometry) litr.next();
		         
		         // Check if the geometry of the observation is within the maximum or minimum distance allowed
		         if (obsGeomCheck.isWithinDistance(element, minVal) && obsGeomCheck.isWithinDistance(element, maxVal))
		         {
		        	 // Falls within an acceptable range
		        	 allInRange = true;
		         }
		         else
		         {
		        	 // The feature does not fall within an acceptable range of other observations, break the loop and return false
		        	 allInRange = false;
		        	 break;
		         }
		         
		      }
			
			
		}
		
		SimpleFeatureCollection resultColl = FeatureCollections.newCollection();
		
		if (allInRange)
		{
			LOGGER.warn("all coords are in range so set ISO profiles");
			SimpleFeatureType sft  = (SimpleFeatureType)obsFcW.getSchema();
			SimpleFeatureTypeBuilder stb = new SimpleFeatureTypeBuilder();
			stb.init(sft);
			stb.setName("newFeatureType");
			
			// Add the new attributes
			stb.add("ISO19157.DomainConsistency", Double.class);
			stb.add("Stakeholder.Validity", String.class);
			stb.add("GeoviQua.Feedback", Double.class);
				
			SimpleFeatureType newFeatureType = stb.buildFeatureType();
			
			SimpleFeatureBuilder sfb = new SimpleFeatureBuilder(newFeatureType);
			sfb.addAll(tempSfCheck.getAttributes());
			sfb.set("ISO19157.DomainConsistency", score); 
			sfb.set("Stakeholder.Validity", "yes"); 
			sfb.set("GeoviQua.Feedback", 1.0); 
			
			SimpleFeature newFeature = sfb.buildFeature(null);
		            
		    newFeature.setDefaultGeometry(obsGeomCheck);
		    resultColl.add(newFeature);
		}
		
	
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
