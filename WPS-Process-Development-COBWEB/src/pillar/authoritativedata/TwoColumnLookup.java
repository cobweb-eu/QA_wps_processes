package pillar.authoritativedata;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.URL;
import java.net.URLConnection;
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
import org.n52.wps.io.data.binding.literal.LiteralStringBinding;
import org.n52.wps.server.AbstractAlgorithm;
import org.n52.wps.server.ExceptionReport;
import org.opengis.feature.Property;
import org.opengis.feature.simple.SimpleFeature;
import org.opengis.feature.simple.SimpleFeatureType;
import org.opengis.feature.type.PropertyType;

public class TwoColumnLookup extends AbstractAlgorithm{
	
	/**
	 * @author Sam Meek
	 * Process to match the observations to an authoritative polygon dataset
	 * Output is the metadata field "DQ_Match" which is 1 for pass criteria and 0 for not passing
	 * result is observations with 1 or 0
	 * qual_result is observations with only metadata 1s are returned
	 */

	Logger LOG = Logger.getLogger(TwoColumnLookup.class);
	
	@Override
	/**
	 * inputData a HashMap of the input data:
	 * @param inputObservations: the observations
	 * @param obsFieldName1: the fieldName to match from the observations
	 * @param obsFieldName2: the fieldName to match from the authoritative list
	 * @param inputAuthoritativeData: the path to an authoritative CSV file
	 * results a HashpMap of the results:
	 * @result result: the input data with the "DQ_Match" with a 1 or a 0
	 * @result qual_result: the "DQ_Match" 1s are returned
	 */
	public Map<String, IData> run(Map<String, List<IData>> inputData)
			throws ExceptionReport {
		
		List<IData> obsList = inputData.get("inputObservations");
		List<IData> fName1 = inputData.get("obsFieldName1");
		List<IData> fName2 = inputData.get("obsFieldName2");
		List<IData> authList = inputData.get("inputAuthoritativeData");
		
		
		
		FeatureCollection obsFc = ((GTVectorDataBinding)obsList.get(0)).getPayload();
		String fieldName1 = ((LiteralStringBinding)fName1.get(0)).getPayload();
		String fieldName2 = ((LiteralStringBinding)fName2.get(0)).getPayload();
		String authData = ((LiteralStringBinding)authList.get(0)).getPayload();
		
		LOG.warn("fieldName1 " + fieldName1);
		LOG.warn("fieldName2 " + fieldName2);
		LOG.warn("authData " + authData);
		
		ArrayList<SimpleFeature> resultArrayList = new ArrayList<SimpleFeature>();
		ArrayList<SimpleFeature> qualArrayList = new ArrayList<SimpleFeature>();
		
		//Parse CSV file
		//File authDataFile = new File(authData);
		
		ArrayList<String[]> authString = new ArrayList<String[]>();
		
		
		try {
			
			 URL url12  = new URL(authData);
		     URLConnection urlConn = url12.openConnection();
		     InputStreamReader inStream = new InputStreamReader(urlConn.getInputStream());
		     
		     
			BufferedReader br = new BufferedReader(inStream);
			
		    String line;
			
			while ((line = br.readLine())!=null){
				
				LOG.warn("line " + line);
				
				String [] tempString = new String[2];
				
				tempString = line.split(",");
				
				authString.add(tempString);
				
			}
			br.close();
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		SimpleFeatureIterator sfi = (SimpleFeatureIterator) obsFc.features();
		SimpleFeature tempPropFeature = sfi.next();
		
		Collection<Property> obsProp = tempPropFeature.getProperties();
		
		
		//SimpleFeatureType typeF = tempPropFeature.getType();
		
		SimpleFeatureTypeBuilder resultTypeBuilder = new SimpleFeatureTypeBuilder();
		resultTypeBuilder.setName("typeBuilder");
		
		
		Iterator<Property> pItObs = obsProp.iterator();
		sfi.close();
		while (pItObs.hasNext()==true){
			
			try{
				
			Property tempProp = pItObs.next();
			PropertyType type = tempProp.getDescriptor().getType();
			String name = type.getName().getLocalPart();
			Class<String> valueClass = (Class<String>)tempProp.getType().getBinding();
			
			resultTypeBuilder.add(name, valueClass);
			

			LOG.warn ("Obs property " + name + " " + valueClass);
			}
			catch (Exception e){
				LOG.error("property error " + e);
			}
		}
		sfi.close();
		
		
		//add DQ_Field
		
		resultTypeBuilder.add("DQ_Match", Double.class);
		
		SimpleFeatureType typeF = resultTypeBuilder.buildFeatureType();
		
		SimpleFeatureBuilder resultFeatureBuilder = new SimpleFeatureBuilder(typeF);
		
		SimpleFeatureIterator obs2 = (SimpleFeatureIterator) obsFc.features();
		
		while (obs2.hasNext()==true){
			
			SimpleFeature tempFeature = obs2.next();
			
			for (Property obsProperty : tempFeature.getProperties()){

				
				String name = obsProperty.getName().toString();
				Object value = obsProperty.getValue();
				
				resultFeatureBuilder.set(name, value);
				
			}
			
			Property obsFieldProp1 = tempFeature.getProperty(fieldName1);
			Property obsFieldProp2 = tempFeature.getProperty(fieldName2);
			
			String obsString1 = (String) obsFieldProp1.getValue();
			String obsString2 = (String) obsFieldProp2.getValue();
			
			
			int match = 0;
			
			for (int i = 0; i < authString.size(); i++){
				
				if (obsString1.equalsIgnoreCase(authString.get(i)[0])){
					
					if(obsString2.equalsIgnoreCase(authString.get(i)[1])){
						match = 1;
						
						
						
					}
					
				}
				
				
			}
			
			resultFeatureBuilder.set("DQ_Match", match);
			
			SimpleFeature tempResult = resultFeatureBuilder.buildFeature(tempFeature.getID());
			
			tempResult.setDefaultGeometry(tempFeature.getDefaultGeometry());
			
			resultArrayList.add(tempResult);
			
			if (match == 1){
				qualArrayList.add(tempResult);
			}
		
		}
		
		obs2.close();
		
		FeatureCollection resultFeatureCollection = new ListFeatureCollection(typeF, resultArrayList);
		FeatureCollection qual_resultFeatureCollection = new ListFeatureCollection(typeF, qualArrayList);
		
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

	@Override
	public Class<?> getInputDataType(String id) {
		if(id.equalsIgnoreCase("inputObservations")){
			return GTVectorDataBinding.class;
		}
		if(id.equalsIgnoreCase("obsFieldName1")){
			return LiteralStringBinding.class;
		}
		if(id.equalsIgnoreCase("obsFieldName2")){
			return LiteralStringBinding.class;
		}
		if(id.equalsIgnoreCase("inputAuthoritativeData")){
			return LiteralStringBinding.class;
		}
		return null;
	}

	@Override
	public Class<?> getOutputDataType(String id) {
		if(id.equalsIgnoreCase("result")){
			return GTVectorDataBinding.class;
		}
		if(id.equalsIgnoreCase("qual_result")){
			return GTVectorDataBinding.class;
		}
		return null;
	}

}
