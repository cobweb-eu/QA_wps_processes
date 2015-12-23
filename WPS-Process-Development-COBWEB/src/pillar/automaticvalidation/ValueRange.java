package pillar.automaticvalidation;

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
import org.n52.wps.io.data.IData;
import org.n52.wps.io.data.binding.complex.GTVectorDataBinding;
import org.n52.wps.io.data.binding.literal.LiteralDoubleBinding;
import org.n52.wps.io.data.binding.literal.LiteralStringBinding;
import org.n52.wps.server.AbstractAlgorithm;
import org.n52.wps.server.ExceptionReport;
import org.opengis.feature.Property;
import org.opengis.feature.simple.SimpleFeature;
import org.opengis.feature.simple.SimpleFeatureType;
import org.opengis.feature.type.PropertyType;
import org.opengis.referencing.crs.CoordinateReferenceSystem;

import com.vividsolutions.jts.geom.Geometry;

import eu.cobwebproject.qa.automaticvalidation.ValRange;

public class ValueRange extends AbstractAlgorithm {
	/**
	 * @author Sam Meek (Modified by Sebastian Clarke - Environment Systems)
	 * Process to assess the range of an attribute given a minimum and maximum threshold
	 * Output is the metadata field "DQ_ValueRange" which is 1 for pass criteria and 0 for not passing
	 * result is observations with 1 or 0
	 * qual_result is observations with only metadata 1s are returned
	 */
	
	Logger LOG = Logger.getLogger(ValueRange.class);

	@Override
	public Class<?> getInputDataType(String identifier) {
		if(identifier.equalsIgnoreCase("inputObservations")){
			return GTVectorDataBinding.class;
		}
		if(identifier.equalsIgnoreCase("attributeName")){
			return LiteralStringBinding.class;
		}
		if(identifier.equalsIgnoreCase("maxRange")){
			return LiteralDoubleBinding.class;
		}
		if(identifier.equalsIgnoreCase("minRange")){
			return LiteralDoubleBinding.class;
		}
		return null;
	}

	@Override
	public Class<?> getOutputDataType(String identifier) {
		if(identifier.equalsIgnoreCase("result")){
			return GTVectorDataBinding.class;
		}
		if(identifier.equalsIgnoreCase("qual_result")){
			return GTVectorDataBinding.class;
		}
		
		return null;
	}

	@Override
	/**
	 * inputData a HashMap of the input data:
	 * @param inputObservations: the observations
	 * @param attributeName: the field name containing the values 
	 * @param maxRange: the maximum number for the range
	 * @param minRange: the minimum number for the range
	 * results a HashpMap of the results:
	 * @result result: the input data with the "Obs_Usability" with a 1 or a 0
	 * @result qual_result: the "Obs_Usability" 1s are returned
	 */
	public Map<String, IData> run(Map<String, List<IData>> inputData)
			throws ExceptionReport {

		// Get attributes from WPS Call (as lists for some reason)
		List<IData> obsList = inputData.get("inputObservations");
		List<IData> maxList = inputData.get("maxRange");
		List<IData> minList = inputData.get("minRange");
		List<IData> attributeNameList = inputData.get("attributeName");
		
		// Dereference these lists to get at the actual value (not sure why we have to do this)
		FeatureCollection obsFc = ((GTVectorDataBinding)obsList.get(0)).getPayload();
		double maxRange = ((LiteralDoubleBinding)maxList.get(0)).getPayload();
		double minRange = ((LiteralDoubleBinding)minList.get(0)).getPayload();
		String nameString = ((LiteralStringBinding)attributeNameList.get(0)).getPayload();
		
		// Get the coordinate system of the input observations
		CoordinateReferenceSystem inputObsCrs = obsFc.getSchema().getCoordinateReferenceSystem();
		
		// Use the first feature from the feature collection as template for output...
		SimpleFeatureIterator sfi = (SimpleFeatureIterator) obsFc.features();
		SimpleFeature tempPropFeature = null;		// temporary feature from which to extract properties
		
		try {		
			tempPropFeature = sfi.next();
		} finally {
			// ensure we release resources to the OS
			sfi.close();			
		}
		
		// Get the properties of the first feature to act as template
		Collection<Property> obsProp = tempPropFeature.getProperties();
	
		// Set up the type builder for the results
		SimpleFeatureTypeBuilder resultTypeBuilder = new SimpleFeatureTypeBuilder();
		resultTypeBuilder.setName("typeBuilder");
		resultTypeBuilder.setCRS(inputObsCrs);
		
		// Iterate through the properties, adding them to the type builder
		Iterator<Property> pItObs = obsProp.iterator();
		while (pItObs.hasNext()) {
			try {
				Property tempProp = pItObs.next();
			
				PropertyType type = tempProp.getType();
				String name = type.getName().getLocalPart();
				Class<?> valueClass = (Class<?>)tempProp.getType().getBinding();
				
				resultTypeBuilder.add(name, valueClass);
				
				LOG.warn ("Obs property " + " name " +  name + " class<?> " + valueClass +
						" type " + type + " tempProp.getValue() " + tempProp.getValue() );
			}
			catch (Exception e){
				LOG.error("property error " + e);
			}
		}
		
		// add DQ_Field (to store success status)
		resultTypeBuilder.add("DQ_ValueRange", Double.class);
		// Build the FeatureType
		SimpleFeatureType typeF = resultTypeBuilder.buildFeatureType();
		
		LOG.warn("++++++++++++++ HERE +++++++++++++");
		LOG.warn("obsFc " + obsFc.size());
		LOG.warn("maxRange " + maxRange);
		LOG.warn("minRange " + minRange);
		LOG.warn("nameString " + nameString);
		
		// Make a result feature builder from the FeatureType
		SimpleFeatureBuilder resultFeatureBuilder = new SimpleFeatureBuilder(typeF);
		// Lists for the two result lists
		ArrayList<SimpleFeature> resultArrayList = new ArrayList<SimpleFeature>(); 
		ArrayList<SimpleFeature> qual_resultArrayList = new ArrayList<SimpleFeature>();	
		
		LOG.warn("Attribute Range Feature Type " + typeF.toString() );
		
		// Now go through the observations and actually do the check
		SimpleFeatureIterator obsIt2 = (SimpleFeatureIterator) obsFc.features();
		try {
			while (obsIt2.hasNext()) {
				boolean within;
				SimpleFeature tempSf = obsIt2.next();
				
				// Copy feature properties to include in output
				for (Property obsProperty : tempSf.getProperties()) {	
					String name = obsProperty.getName().toString();
					Object value = obsProperty.getValue();
					resultFeatureBuilder.set(name, value);
				}
				
				// Now calculate and set the DQ value (do the check!)
				double tempAttributeValue = Double.parseDouble(tempSf.getProperty(nameString).getValue().toString());
				if(ValRange.valueInRange(tempAttributeValue, minRange, maxRange)) {
					within = true;
					resultFeatureBuilder.set("DQ_ValueRange", 1);
				} else {
					within = false;
					resultFeatureBuilder.set("DQ_ValueRange", 0);
				}
				
				// Build the completed feature and set its geometry from the input feature
				SimpleFeature tempResult = resultFeatureBuilder.buildFeature(tempSf.getID());
				Geometry tempGeom = (Geometry) tempSf.getDefaultGeometry();
				tempResult.setDefaultGeometry(tempGeom);
				
				// add the feature to qual_result if it passes the test
				if(within) {
					qual_resultArrayList.add(tempResult);
				}
				// add it it to the results with its DQ set anyway
				resultArrayList.add(tempResult);
			}
		} finally {
			// safely release resources back to the OS
			obsIt2.close();
		}
		
		// Make feature collections from the lists of features
		FeatureCollection resultFeatureCollection = new ListFeatureCollection(typeF, resultArrayList);
		FeatureCollection qual_resultFeatureCollection = new ListFeatureCollection(typeF, qual_resultArrayList);

		// Add them to the result hash map
		HashMap<String, IData> results = new HashMap<String, IData>();
		results.put("result", new GTVectorDataBinding((FeatureCollection)resultFeatureCollection));
		results.put("qual_result", new GTVectorDataBinding((FeatureCollection)qual_resultFeatureCollection));
		
		return results;
	}
	
	@Override
	public List<String> getErrors() {
		// TODO Auto-generated method stub
		return null;
	}
}


