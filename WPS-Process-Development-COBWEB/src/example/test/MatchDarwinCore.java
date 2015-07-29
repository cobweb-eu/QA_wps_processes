package example.test;

import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.URL;
import java.net.URLConnection;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import org.apache.log4j.Logger;
import org.geotools.data.simple.SimpleFeatureIterator;
import org.geotools.feature.FeatureCollection;
import org.geotools.feature.simple.SimpleFeatureBuilder;
import org.geotools.feature.simple.SimpleFeatureTypeBuilder;
import org.n52.wps.io.data.IData;
import org.n52.wps.io.data.binding.complex.GTVectorDataBinding;
import org.n52.wps.io.data.binding.literal.LiteralStringBinding;
import org.n52.wps.server.AbstractAlgorithm;
import org.n52.wps.server.ExceptionReport;
import org.opengis.feature.Property;
import org.opengis.feature.simple.SimpleFeature;
import org.opengis.feature.simple.SimpleFeatureType;
import org.opengis.feature.type.PropertyType;
import org.opengis.referencing.crs.CoordinateReferenceSystem;

import com.vividsolutions.jts.geom.Geometry;

public class MatchDarwinCore extends AbstractAlgorithm{

	Logger LOG = Logger.getLogger(MatchDarwinCore.class);
	
	@Override
	public Map<String, IData> run(Map<String, List<IData>> inputData)
			throws ExceptionReport {
		List <IData> inputObs = inputData.get("inputObservations");
		List <IData> inputList = inputData.get("darwinCoreListURL");
		List <IData> inputName = inputData.get("darwinCoreName");
		
		FeatureCollection obsFc = ((GTVectorDataBinding) inputObs.get(0)).getPayload();
		
		String darwinCoreType = ((LiteralStringBinding) inputName.get(0)).getPayload();
		
		String darwinCoreListURL = ((LiteralStringBinding)inputList.get(0)).getPayload();
		

		SimpleFeatureIterator sfi = (SimpleFeatureIterator) obsFc.features();
		SimpleFeature tempPropFeature = sfi.next();
		CoordinateReferenceSystem inputObsCrs = obsFc.getSchema().getCoordinateReferenceSystem();
		
		Collection<Property> obsProp = tempPropFeature.getProperties();
		
		
		//SimpleFeatureType typeF = tempPropFeature.getType();
		
		SimpleFeatureTypeBuilder resultTypeBuilder = new SimpleFeatureTypeBuilder();
		resultTypeBuilder.setName("typeBuilder");
		resultTypeBuilder.setCRS(inputObsCrs);
		String geometryName = null;
		Iterator<Property> pItObs = obsProp.iterator();
		
	
		
		sfi.close();
		while (pItObs.hasNext()==true){
			
			try{
				
			Property tempProp = pItObs.next();
			PropertyType type = tempProp.getDescriptor().getType();
			String name = type.getName().getLocalPart();
			Class<String> valueClass = (Class<String>)tempProp.getType().getBinding();
			
			
			

			LOG.warn ("Obs property " + name + " " + valueClass + " " +type.toString());
			}
			catch (Exception e){
				LOG.error("property error " + e);
			}
		}
		
		//add DQ_Field
		
		resultTypeBuilder.add("DW_name", String.class);
		resultTypeBuilder.add("DW_tax", String.class);
		SimpleFeatureType typeF = resultTypeBuilder.buildFeatureType();
		LOG.warn("Get Spatial Accuracy Feature Type " + typeF.toString());
		
		SimpleFeatureBuilder resultFeatureBuilder = new SimpleFeatureBuilder(typeF);
		ArrayList<SimpleFeature> resultArrayList = new ArrayList<SimpleFeature>(); 
		
		
		ArrayList<String[]> authString = new ArrayList<String[]>();
		
		
		try {
			
			 URL url12  = new URL(darwinCoreListURL);
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
		
		//match list to featues here:
		
		String latinString = null;
		
		for (int i = 0; i < authString.size(); i++){
			String nameString = authString.get(i)[0];
			
			
			if(nameString.equalsIgnoreCase(darwinCoreType)){
				latinString = authString.get(i)[1];
			}
			
			
		}

		SimpleFeatureIterator obsIt = (SimpleFeatureIterator) obsFc.features();
		
		while (obsIt.hasNext()==true){
			
		SimpleFeature tempSf = obsIt.next();	
		
			
			for (Property obsProperty : tempSf.getProperties()){	
				
		
			
				resultFeatureBuilder.set(obsProperty.getName(), obsProperty.getValue());
			
			}
			resultFeatureBuilder.set("DW_name", darwinCoreType);
			resultFeatureBuilder.set("DW_tax", latinString);
			SimpleFeature result = resultFeatureBuilder.buildFeature(tempSf.getID());
			resultArrayList.add(result);
		}
		obsIt.close();
		
		
		
		
		
		
		return null;
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
		if(id.equalsIgnoreCase("darwinCoreName")){
			return LiteralStringBinding.class;
		}
		if(id.equalsIgnoreCase("darwinCoreListURL")){
			return LiteralStringBinding.class;
		}
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public Class<?> getOutputDataType(String id) {
		if(id.equalsIgnoreCase("result")){
			return GTVectorDataBinding.class;
		}
		return null;
	}

}
