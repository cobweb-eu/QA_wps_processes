package pillar.automaticvalidation;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.StringWriter;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLConnection;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.commons.io.IOUtils;
import org.apache.log4j.Logger;
import org.geotools.data.DataStore;
import org.geotools.data.DataStoreFinder;
import org.geotools.data.FileDataStoreFactorySpi;
import org.geotools.data.GmlObjectStore;
import org.geotools.data.simple.SimpleFeatureCollection;
import org.geotools.data.simple.SimpleFeatureIterator;
import org.geotools.data.simple.SimpleFeatureSource;
import org.geotools.data.store.ReprojectingFeatureCollection;
import org.geotools.factory.CommonFactoryFinder;
import org.geotools.factory.GeoTools;
import org.geotools.factory.Hints;
import org.geotools.feature.FeatureCollection;
import org.geotools.feature.FeatureCollections;
import org.geotools.feature.simple.SimpleFeatureBuilder;
import org.geotools.feature.simple.SimpleFeatureTypeBuilder;
import org.geotools.geojson.feature.FeatureJSON;
import org.geotools.geometry.jts.JTS;
import org.geotools.referencing.CRS;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.n52.wps.io.data.GenericFileData;
import org.n52.wps.io.data.IData;
import org.n52.wps.io.data.binding.complex.GTVectorDataBinding;
import org.n52.wps.io.data.binding.complex.GenericFileDataBinding;
import org.n52.wps.io.data.binding.literal.LiteralDoubleBinding;
import org.n52.wps.io.data.binding.literal.LiteralStringBinding;
import org.n52.wps.server.AbstractAlgorithm;
import org.n52.wps.server.ExceptionReport;
import org.opengis.feature.simple.SimpleFeature;
import org.opengis.feature.simple.SimpleFeatureType;
import org.opengis.filter.FilterFactory2;
import org.opengis.filter.identity.GmlObjectId;
import org.opengis.geometry.MismatchedDimensionException;
import org.opengis.referencing.FactoryException;
import org.opengis.referencing.NoSuchAuthorityCodeException;
import org.opengis.referencing.crs.CRSAuthorityFactory;
import org.opengis.referencing.crs.CoordinateReferenceSystem;
import org.opengis.referencing.operation.MathTransform;
import org.opengis.referencing.operation.TransformException;

import com.vividsolutions.jts.geom.Coordinate;
import com.vividsolutions.jts.geom.CoordinateArrays;
import com.vividsolutions.jts.geom.Geometry;
import com.vividsolutions.jts.geom.Point;



public class PositionDistanceRange extends AbstractAlgorithm {
	/**
	 * @author Frances Moore
	 * Javadoc needs completing.
	 */
	Logger LOGGER = Logger.getLogger(PositionDistanceRange.class);
	/**
	 * @param args
	 */
	public static void main(String[] args) {
		// TODO Auto-generated method stub

	}

	public List<String> getErrors() {
		// TODO Auto-generated method stub
		return null;
	}

	public Class<?> getInputDataType(String identifier) {
		if(identifier.equalsIgnoreCase( "inputObservations")){
			return GTVectorDataBinding.class;
		}
		if (identifier.equalsIgnoreCase("inputAuthoritativeData")){
			return GenericFileDataBinding.class;
		}
		if (identifier.equalsIgnoreCase("minDistance")){
			return LiteralDoubleBinding.class;
		}
		if (identifier.equalsIgnoreCase("maxDistance")){
			return LiteralDoubleBinding.class;
		}
		if (identifier.equalsIgnoreCase("lowUsabilityScore")){
			return LiteralDoubleBinding.class;
		}
		if (identifier.equalsIgnoreCase("highUsabilityScore")){
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
		List <IData> inputAuth = inputData.get("inputAuthoritativeData");
		 
		// Cast the input observations as a FeatureCollection
		FeatureCollection obsFcW = ((GTVectorDataBinding) inputObs.get(0)).getPayload();
		
		// Set some variables to perform checks
		int featureTest = 0;
		String checkResponse = "";
		
		// Create a new FeatureCollection to hold the authoritative data
		FeatureCollection authFc = FeatureCollections.newCollection();

		// Cast what has been supplied for authoritative data to a GenericFileDataBinding
		// This has been done to allow for no features provided at authoritative level
		GenericFileDataBinding file = (GenericFileDataBinding) inputAuth.get(0);
		// Retrieve the data
		GenericFileData fData = file.getPayload();
		
		// Get the required literal inputs
		double minVal = ((LiteralDoubleBinding)(inputData.get("minDistance").get(0))).getPayload(); 
		double maxVal = ((LiteralDoubleBinding)(inputData.get("maxDistance").get(0))).getPayload(); 
		double score = ((LiteralDoubleBinding)(inputData.get("highUsabilityScore").get(0))).getPayload();
		
		// Create a SimpleFeatureCollection to hold the results
		SimpleFeatureCollection resultColl = FeatureCollections.newCollection();
	
		// Create an InputStream from the authoritative source to read
		InputStream inputStream = fData.getDataStream();
		// Create a StringWriter to hold the information returned from the stream
		StringWriter writer = new StringWriter();
		try 
		{
			// Copy the information from the authoritative stream to the StringWriter
			IOUtils.copy(inputStream, writer, null);
		} 
		catch (IOException e) 
		{
			e.printStackTrace();
		}
		        
		// Allocate the value to a variable for checking
		checkResponse = writer.toString();
		
		// Create a new instance of FeatureJSON class to check the returned string
		FeatureJSON fjson = new FeatureJSON();
		// Create a new SimpleFeature
		SimpleFeature feature;
		try 
		{
			// Read the json provided to check if a feature is present
			feature = fjson.readFeature(checkResponse);
			
			// Allocate the featureTest variable so it can be used to check
			featureTest = feature.getAttributeCount();
			
			// Check on featureTest value
			if (featureTest > 0)
			{
				// The feature has attributes, therefore a valid feature is found and authoritative data has been provided
				// Allocate the features to the authoritative collection
				authFc = new FeatureJSON().readFeatureCollection(checkResponse);
				LOGGER.warn("authFC working " + authFc.size());
			}
		} 
		catch (IOException e1) 
		{
			e1.printStackTrace();
		}
		
		// Set up a feature iterator so the observations can be checked
		SimpleFeatureIterator obsIt2 = (SimpleFeatureIterator) obsFcW.features();
		
		while (obsIt2.hasNext()==true)
		{
			SimpleFeature tempSf = obsIt2.next();	
			
			Geometry obsGeom = (Geometry) tempSf.getDefaultGeometry();
		
			try
			{
			
				// Check is made if authoritative data was found
				if (featureTest == 0)
				{
					// Authoritative dataset not present,so gazetteer to be used
					
					// Set up URL to call
					URL proxyUrl = new URL("http://wggt-addressproxy-staging.azurewebsites.net/AddressingService.svc/FindAddressByCoordinateREST?lat=" + obsGeom.getCoordinate().y + "&lon=" + obsGeom.getCoordinate().x);
					// Open the connection to the resource
					URLConnection connection = proxyUrl.openConnection();
					// Create a BufferedReader to read the data from the URL
			        BufferedReader inNotAuth = new BufferedReader(new InputStreamReader(connection.getInputStream()));
	
			        StringBuilder response = new StringBuilder();
			        String inputLine;
	
			        while ((inputLine = inNotAuth.readLine()) != null) 
			            response.append(inputLine);
	
			        inNotAuth.close();

			        String proxyResponse = response.toString();
		        
			        // A check is made on whether the coordinates provided with the observation fall within the allowed area
			        if (proxyResponse.contains("AdminAreaName") && proxyResponse.contains("Powys"))
				    {
			   	    	// Creates a feature to be added to the result list to be returned
						SimpleFeature newFeature = BuildNewResultFeature(obsFcW, tempSf, obsGeom, score);
			            // Add the result to the collection 
						resultColl.add(newFeature); 
				     }
				}
				else
				{
				
					// Authoritative dataset present, so this can be checked against the observation
					// Create a feature iterator to loop through the authoritative features
					SimpleFeatureIterator authIt = (SimpleFeatureIterator) authFc.features();
				
					while (authIt.hasNext()==true)
					{
						
						SimpleFeature tempAuth = authIt.next();
						Geometry authGeom = (Geometry) tempAuth.getDefaultGeometry();
						
						
						FilterFactory2 ff = CommonFactoryFinder.getFilterFactory2(GeoTools.getDefaultHints());
					
						if (inputData.get("minDistance") != null)
				    	{
						
							// Check if the distance of the observation is between the maximum and minimum allowed values provided
							if (obsGeom.isWithinDistance(authGeom, minVal) && obsGeom.isWithinDistance(authGeom, maxVal))
							{
								// The observation is within the allowed limits
								// Create a new feature to add to the results
								 SimpleFeature newFeature = BuildNewResultFeature(obsFcW, tempSf, obsGeom, score);
					            //  Add the new feature to the result collection    
					            resultColl.add(newFeature); 
							}
							
				    	}
					
					
				}
			}
		}
		catch(Exception e)
		{
			LOGGER.warn("input auth not working" + e.getMessage());
			e.printStackTrace();
		}
		
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
	
	
	// Function to create a new feature from an existing feature, with the additional user feedback fields required
	private SimpleFeature BuildNewResultFeature(FeatureCollection fc, SimpleFeature tempSf, Geometry obsGeom, double score)
	{
		SimpleFeatureType sft  = (SimpleFeatureType)fc.getSchema();
		SimpleFeatureTypeBuilder stb = new SimpleFeatureTypeBuilder();
		stb.init(sft);
		stb.setName("newFeatureType");
		//Add the new usability score attribute
		stb.add("ISO19157.Usability", Double.class);
		//Add the new stakeholder reliability attribute
		stb.add("User.Stakeholder.Reliability", Double.class);
		//Add the new GeoviQua feedback attribute
		stb.add("GeoviQua.Feedback", Double.class);

	    SimpleFeatureType newFeatureType = stb.buildFeatureType();
		
	    SimpleFeatureBuilder sfb = new SimpleFeatureBuilder(newFeatureType);
		sfb.addAll(tempSf.getAttributes());
		sfb.set("ISO19157.Usability", score); 
		sfb.set("User.Stakeholder.Reliability", 1.0); 
		sfb.set("GeoviQua.Feedback", 20.0); 
		
		 SimpleFeature newFeature = sfb.buildFeature(null);
            
           newFeature.setDefaultGeometry(obsGeom);
           
           return newFeature;
	}

}
