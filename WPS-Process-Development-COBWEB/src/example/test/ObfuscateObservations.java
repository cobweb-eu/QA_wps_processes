package example.test;

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
import org.n52.wps.server.AbstractAlgorithm;
import org.n52.wps.server.ExceptionReport;
import org.opengis.feature.IllegalAttributeException;
import org.opengis.feature.Property;
import org.opengis.feature.simple.SimpleFeature;
import org.opengis.feature.simple.SimpleFeatureType;
import org.opengis.feature.type.GeometryDescriptor;
import org.opengis.feature.type.GeometryType;
import org.opengis.feature.type.Name;
import org.opengis.feature.type.PropertyType;
import org.opengis.filter.identity.Identifier;
import org.opengis.geometry.BoundingBox;
import org.opengis.referencing.crs.CoordinateReferenceSystem;

import com.vividsolutions.jts.geom.Geometry;
import com.vividsolutions.jts.geom.MultiPolygon;

public class ObfuscateObservations extends AbstractAlgorithm{
Logger LOG = Logger.getLogger(ObfuscateObservations.class);

	@Override
	public Map<String, IData> run(Map<String, List<IData>> inputData)
			throws ExceptionReport {
		List <IData> inputObs = inputData.get("inputObservations");
		List <IData> inputAuth = inputData.get("inputPolygons");
		
		
		LOG.warn("+++++++++HERE+++++++++++");
		FeatureCollection obsFc = ((GTVectorDataBinding) inputObs.get(0)).getPayload();
		FeatureCollection authFc = ((GTVectorDataBinding) inputAuth.get(0)).getPayload();
		
		
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
			
			if(!valueClass.getName().equalsIgnoreCase("com.vividsolutions.jts.geom.Point")){
			
				resultTypeBuilder.add(name, valueClass);
		
			}
			
			

			LOG.warn ("Obs property " + name + " " + valueClass + " " +type.toString());
			}
			catch (Exception e){
				LOG.error("property error " + e);
			}
		}
		
		//add DQ_Field
		
		resultTypeBuilder.add("geometry", Geometry.class);
		SimpleFeatureType typeF = resultTypeBuilder.buildFeatureType();
		LOG.warn("Get Spatial Accuracy Feature Type " + typeF.toString());
		
		SimpleFeatureBuilder resultFeatureBuilder = new SimpleFeatureBuilder(typeF);
		ArrayList<SimpleFeature> resultArrayList = new ArrayList<SimpleFeature>(); 
		
		
		SimpleFeatureIterator obsIt = (SimpleFeatureIterator) obsFc.features();
		
		obsIt.close();
		
		SimpleFeatureIterator obsIt2 = (SimpleFeatureIterator) obsFc.features();
		
		int within = 0;
		
		while (obsIt2.hasNext()==true){
			within = 0;
			SimpleFeature tempSf = obsIt2.next();	
			
			Geometry obsGeom = (Geometry) tempSf.getDefaultGeometry();
			
			for (Property obsProperty : tempSf.getProperties()){

				
				String name = obsProperty.getName().toString();
				Object value = obsProperty.getValue();
				
				resultFeatureBuilder.set(name, value);
				
			}
			
			SimpleFeatureIterator authIt = (SimpleFeatureIterator) authFc.features();
			
			Geometry authGeom = null;
			
			Geometry geom = null;
			while (authIt.hasNext()==true){
				
				SimpleFeature tempAuth = authIt.next();
				authGeom = (Geometry) tempAuth.getDefaultGeometry();
				
				if (obsGeom.within(authGeom)){
					
					within = 1;
					LOG.warn("Is within " + within + " " + authGeom.getGeometryType());
					geom  = authGeom;
					resultFeatureBuilder.set("geometry", geom);
					LOG.warn("get multi " + resultFeatureBuilder.getFeatureType().getGeometryDescriptor().getName());
				
					
				}
				
			
			}
			
		
			SimpleFeature result = resultFeatureBuilder.buildFeature(tempSf.getID());
		
			result.setDefaultGeometry(geom);
			LOG.warn("simpleFeature " + result.getDefaultGeometry().getClass().getName());
			
			resultArrayList.add(result);
			
			authIt.close();
		
			
			
			
		}
		obsIt2.close();
		FeatureCollection resultFeatureCollection = new ListFeatureCollection(typeF, resultArrayList);
		
		
		LOG.warn("Feature Collection Size " + resultFeatureCollection.size());
		
		
		HashMap<String, IData> results = new HashMap<String, IData>();
		results.put("result", new GTVectorDataBinding((FeatureCollection)resultFeatureCollection));
		
		
		
		
		
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
		if(id.equalsIgnoreCase("inputPolygons")){
			return GTVectorDataBinding.class;
		}
		
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
