package pillar.cleaning;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.log4j.Logger;
import org.geotools.data.collection.ListFeatureCollection;
import org.geotools.data.simple.SimpleFeatureIterator;
import org.geotools.feature.FeatureCollection;
import org.n52.wps.io.data.IData;
import org.n52.wps.io.data.binding.complex.GTVectorDataBinding;
import org.n52.wps.io.data.binding.complex.GenericFileDataBinding;
import org.n52.wps.io.data.binding.literal.LiteralBooleanBinding;
import org.n52.wps.io.data.binding.literal.LiteralStringBinding;
import org.n52.wps.server.AbstractAlgorithm;
import org.n52.wps.server.ExceptionReport;
import org.opengis.feature.Property;
import org.opengis.feature.simple.SimpleFeature;
import org.opengis.feature.simple.SimpleFeatureType;

public class FilterOnAttribute extends AbstractAlgorithm{
	Logger LOG = Logger.getLogger(FilterOnAttribute.class);
	private final String inputObservations = "inputObservations";
	private final String fieldName = "fieldName";
	private final String featureName = "featureName";
	private final String include = "include";
	
	@Override
	public Class<?> getInputDataType(String identifier) {
		if (identifier.equalsIgnoreCase("inputObservations")){
			return GTVectorDataBinding.class;
		}
		if(identifier.equalsIgnoreCase("fieldName")){
			return LiteralStringBinding.class;
		}
		if(identifier.equalsIgnoreCase("featureName")){
			return GTVectorDataBinding.class;
		}
		if(identifier.equalsIgnoreCase("include")){
			return LiteralBooleanBinding.class;
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
		if(identifier.equalsIgnoreCase("metadata")){
			return GenericFileDataBinding.class;
		}
		return null;
	}

	@Override
	public Map<String, IData> run(Map<String, List<IData>> inputData)
			throws ExceptionReport {
		
		List obsList = inputData.get("inputObservations");
		List fieldList = inputData.get("fieldName");
		List featureList = inputData.get("featureName");
		List incList = inputData.get("include");
		
		FeatureCollection obsFc = ((GTVectorDataBinding)obsList.get(0)).getPayload();
		String fieldN = ((LiteralStringBinding) fieldList.get(0)).getPayload();
		String featureN = ((LiteralStringBinding) featureList.get(0)).getPayload();
		boolean includeB = ((LiteralBooleanBinding) incList.get(0)).getPayload();
		LOG.warn("inlcudeB " + includeB);
		
		ArrayList<SimpleFeature> resultList = new ArrayList<SimpleFeature>(); 
		
		SimpleFeatureIterator obsIt = (SimpleFeatureIterator) obsFc.features();
		
		SimpleFeatureType typeF = null;
		
		while (obsIt.hasNext()){
			
			
			
			SimpleFeature tempFeature = obsIt.next();
			
			typeF = tempFeature.getFeatureType();
			String tempProp = tempFeature.getProperty(fieldN).getValue().toString();
			
			LOG.warn("tempProp " + tempProp);
			
			if(includeB == true){
			
				if (tempProp.equalsIgnoreCase(featureN)){
					
					LOG.warn("Here 1 " + tempProp + " " + includeB);
					resultList.add(tempFeature);
				
				}
			}
			
			if(includeB == false){
				
				if (!tempProp.equalsIgnoreCase(featureN)){
					LOG.warn("Here 2 " + includeB + " " + featureN + " " + tempProp);
					resultList.add(tempFeature);
				}
				
				
			}
			
		}
		
		obsIt.close();
		
		ListFeatureCollection resultFc = new ListFeatureCollection(typeF, resultList);
		
		Map<String, IData> results = new HashMap<String, IData>();
		
		results.put("result", new GTVectorDataBinding (obsFc));
		results.put("qual_result", new GTVectorDataBinding (resultFc));
		results.put("metadata", new GenericFileDataBinding (null));
		
		
		
		
		
		
		return results;
	}
	@Override
	public List<String> getErrors() {
		// TODO Auto-generated method stub
		return null;
	}

}
