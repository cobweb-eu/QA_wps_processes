package pillar4.authoritativedata;

import java.io.File;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Calendar;
import java.util.Collection;
import java.util.HashMap;
import java.util.Iterator;

import javax.xml.namespace.QName;

import org.apache.log4j.Logger;
import org.apache.xmlbeans.XmlOptions;
import org.geotools.data.collection.ListFeatureCollection;
import org.geotools.data.simple.SimpleFeatureIterator;
import org.geotools.feature.DefaultFeatureCollections;
import org.geotools.feature.FeatureCollection;
import org.geotools.feature.simple.SimpleFeatureBuilder;
import org.geotools.feature.simple.SimpleFeatureTypeBuilder;
import org.geoviqua.gmd19157.DQDataQualityType;
import org.geoviqua.qualityInformationModel.x40.GVQDataQualityType;
import org.geoviqua.qualityInformationModel.x40.GVQDiscoveredIssueType;
import org.geoviqua.qualityInformationModel.x40.GVQMetadataDocument;
import org.geoviqua.qualityInformationModel.x40.GVQMetadataType;
import org.n52.wps.algorithm.annotation.Algorithm;
import org.n52.wps.algorithm.annotation.ComplexDataInput;
import org.n52.wps.algorithm.annotation.ComplexDataOutput;
import org.n52.wps.algorithm.annotation.Execute;
import org.n52.wps.algorithm.annotation.LiteralDataInput;
import org.n52.wps.io.data.binding.complex.GTVectorDataBinding;
import org.n52.wps.io.data.binding.complex.GenericFileDataBinding;
import org.n52.wps.io.data.binding.literal.LiteralStringBinding;
import org.n52.wps.server.AbstractAnnotatedAlgorithm;
import org.n52.wps.io.data.GenericFileData;
import org.opengis.feature.Property;
import org.opengis.feature.simple.SimpleFeature;
import org.opengis.feature.simple.SimpleFeatureType;
import org.opengis.feature.type.PropertyType;
import com.vividsolutions.jts.geom.Geometry;

@Algorithm(version = "1.0.0", abstrakt = "Checks for an intersection between a buffered observation and an authoritative dataset")
public class BufferAuthoritativeDataComparison extends AbstractAnnotatedAlgorithm{
	

	/**
	 * @author Sam Meek
	 * Process to compare observations with authoritative polygon data with a buffer (point in polygon)
	 * Output is the observations with the fields of the matched buffered authoritative data (point in polygon)
	 * 
	 */
	
	
	public BufferAuthoritativeDataComparison(){
		super();
	}
	
	Logger LOGGER = Logger.getLogger(BufferAuthoritativeDataComparison.class);
	private FeatureCollection resultFeatureCollection;
	private FeatureCollection listFeatureCollection;
	private FeatureCollection qualityAugmentedResult;
	private FeatureCollection obsFC;
	private FeatureCollection authFC;
	private File metadataFile;
	private String bufferSize;
	private ArrayList<SimpleFeature> list = new ArrayList<SimpleFeature>();
	private HashMap<String, Object> metadataMap = new HashMap<String,Object>();
	
	@ComplexDataOutput(identifier = "metadata", abstrakt = "metadata return", binding = GenericFileDataBinding.class)
		public File getMetadata(){
			return metadataFile;
		}
	
	@ComplexDataOutput(identifier = "result", abstrakt = "observations returned with attributes from intersected authoritative data", binding = GTVectorDataBinding.class)
	    public FeatureCollection getResult() {
	        return listFeatureCollection;
	}
	
	@ComplexDataOutput(identifier = "qual_result", abstrakt = "input observations returned", binding = GTVectorDataBinding.class)
	 	public FeatureCollection getQualResult(){
			return qualityAugmentedResult;
	}
	
	
	 
	@ComplexDataInput(identifier = "inputObservations", abstrakt = "input observations, must be a point", binding = GTVectorDataBinding.class)
		 public void setObservations (FeatureCollection observations){
			 this.obsFC = observations;		 
	}
	 
	@ComplexDataInput(identifier = "inputAuthoritativeData", abstrakt="input authoritative data, must be a set of polygons", binding = GTVectorDataBinding.class)
	 	public void setAuthoritativeData (FeatureCollection authoritativeData){
		 this.authFC = authoritativeData;
	}
 
	@LiteralDataInput(identifier = "bufferSize", abstrakt="Is a string", binding = LiteralStringBinding.class)
	 	public void setBufferSize (String bufferSize){
		 this.bufferSize = bufferSize;
		 
	 }
	  
	 @Execute
	 /**
		 * inputData a HashMap of the input data:
		 * @param inputObservations: the observations
		 * @param inputAuthoritativeData: the polygons
		 * @param bufferSize: the size of the buffer in the same units as the input data (degrees for lat/long)
		 * results a HashpMap of the results:
		 * @result result: the input data with the polygon attributes attached, null values for no match
		 * @result qual_result: the matched input only data with polygon attributes attached
		 * @result metadata: an unused output that was supposed to return an XML document for GeoNetwork
		 */
	 public void runBuffer(){
		 
		 Logger LOGGER = Logger.getLogger(BufferAuthoritativeDataComparison.class);
		 
		 	
		 
			SimpleFeatureIterator obsIt = (SimpleFeatureIterator) obsFC.features();
			
			SimpleFeatureIterator authIt = (SimpleFeatureIterator) authFC.features();
			
			
			//setup result feature
			
			SimpleFeature obsItFeat = obsIt.next();
			
			SimpleFeature obsItAuth = authIt.next();
			
			Collection<Property> property = obsItFeat.getProperties();
			Collection<Property> authProperty = obsItAuth.getProperties();
			
			//setup result type builder
			SimpleFeatureTypeBuilder resultTypeBuilder = new SimpleFeatureTypeBuilder();
			resultTypeBuilder.setName("typeBuilder");
			
			
			
			Iterator<Property> pItObs = property.iterator();
			Iterator<Property> pItAuth = authProperty.iterator();
			
			
			metadataMap.put("element", "elementBufferedMetadata");
			metadataFile = createXMLMetadata(metadataMap);
			
			while (pItObs.hasNext()==true){
				
				try{
				Property tempProp = pItObs.next();
				
				PropertyType type = tempProp.getDescriptor().getType();
				String name = type.getName().getLocalPart();
				Class<String> valueClass = (Class<String>)tempProp.getType().getBinding();
			
				resultTypeBuilder.add(name, valueClass);
				
			
				}
				catch (Exception e){
					LOGGER.error("property error " + e);
				}
				
			}
			int i = 0;
			while (pItAuth.hasNext()==true){
				try{
				Property tempProp = pItAuth.next();
				
				PropertyType type = tempProp.getDescriptor().getType();
				String name = type.getName().getLocalPart();
				Class<String> valueClass = (Class<String>)tempProp.getType().getBinding();
				
				if(i > 3){
				
					resultTypeBuilder.add(name, valueClass);
				
				}
				
				i++;
			
				}
				catch (Exception e){
					LOGGER.error("property error " + e);
				}
				
			}
			
			obsIt.close();
			authIt.close();
			resultTypeBuilder.add("withinBuffer", Integer.class);
			
			// set up result feature builder
			
			SimpleFeatureType type = resultTypeBuilder.buildFeatureType();
			SimpleFeatureBuilder resultFeatureBuilder = new SimpleFeatureBuilder(type);
			
			// process data here:
			
			SimpleFeatureIterator obsIt2 = (SimpleFeatureIterator) obsFC.features();
			
			
			int within = 0;
					
			resultFeatureCollection = DefaultFeatureCollections.newCollection();	
			
			while (obsIt2.hasNext() == true){
				within = 0;
				SimpleFeature tempObs = obsIt2.next();
				Geometry obsGeom = (Geometry) tempObs.getDefaultGeometry();
				
				
				
				for (Property obsProperty : tempObs.getProperties()){
					
					String name = obsProperty.getName().getLocalPart();
					Object value = obsProperty.getValue();
					
					
					resultFeatureBuilder.set(name, value);
					//LOGGER.warn("obs Property set " + name);
				}
				
				double bufferSizeDouble = Double.parseDouble(bufferSize);
				
				
				Geometry bufferGeom = obsGeom.buffer(bufferSizeDouble);
				
			
				int j = 0;
				SimpleFeatureIterator authIt2 = (SimpleFeatureIterator) authFC.features();
				while (authIt2.hasNext() == true){
					
					SimpleFeature tempAuth = authIt2.next();
					Geometry authGeom = (Geometry) tempAuth.getDefaultGeometry();
					
					
					if(bufferGeom.intersects(authGeom) == true){
						within = 1;
						j=0;
						
						LOGGER.warn("Intersection = true");
						for (Property authProperty1 : tempAuth.getProperties()){
							
							String name = authProperty1.getName().getLocalPart();
							Object value = authProperty1.getValue();
							//Class valueClass = (Class<String>)authProperty1.getType().getBinding();
							
					//		LOGGER.warn("Auth property " + name);
							if (j > 3){
								resultFeatureBuilder.set(name, value);
							//	LOGGER.warn("Auth property set " + name);
								
							}
							
							j++;
							
			
							
						}
						
					}
					
				}
				resultFeatureBuilder.set("withinBuffer", within);
					
				
				
				SimpleFeature resultFeature = resultFeatureBuilder.buildFeature(tempObs.getName().toString());
				Geometry geom = (Geometry) tempObs.getDefaultGeometry();
				resultFeature.setDefaultGeometry(geom);
				
				
				list.add(resultFeature);
				
				//resultFeatureCollection.add(resultFeature);
				//LOGGER.warn("RESULT FEATURE " + resultFeatureCollection.getSchema().toString());
				//resultFeatureCollection = obsFC;
			}
			
			
			listFeatureCollection = new ListFeatureCollection(type, list);
			LOGGER.warn("Result Feature Size " + listFeatureCollection.size());
		 
		 
	 }
	 private File createXMLMetadata(HashMap<String,Object> inputs){
			
			
			ArrayList< ? > validationErrors = new ArrayList<Object>();
			XmlOptions options; 
			options = new XmlOptions();
			options.setSavePrettyPrint();
			options.setSaveAggressiveNamespaces();

			HashMap<String, String> suggestedPrefixes = new HashMap<String, String>();
			suggestedPrefixes.put("http://www.geoviqua.org/QualityInformationModel/4.0", "gvq");
			options.setSaveSuggestedPrefixes(suggestedPrefixes);

			options.setErrorListener(validationErrors);

			
			GVQMetadataDocument doc = GVQMetadataDocument.Factory.newInstance();
			GVQMetadataType gvqMetadata = doc.addNewGVQMetadata();
			gvqMetadata.addNewLanguage().setCharacterString("en");
		    gvqMetadata.addNewMetadataStandardName().setCharacterString("GVQ");
		    gvqMetadata.addNewMetadataStandardVersion().setCharacterString("1.0.0");
		    gvqMetadata.addNewDateStamp().setDate(Calendar.getInstance());
		    DQDataQualityType quality = gvqMetadata.addNewDataQualityInfo2().addNewDQDataQuality();
		    GVQDataQualityType gvqQuality = (GVQDataQualityType) quality.substitute(new QName("http://www.geoviqua.org/QualityInformationModel/4.0",
		                                                                                          "GVQ_DataQuality"),
		                                                                                GVQDataQualityType.type);
		    GVQDiscoveredIssueType issue = gvqQuality.addNewDiscoveredIssue().addNewGVQDiscoveredIssue();
		    
		    issue.addNewKnownProblem().setCharacterString(inputs.get("element").toString());
		    issue.addNewWorkAround().setCharacterString("solution");

		        // validate schema conformity
		        boolean isValid = doc.validate();
		        if ( !isValid)
		            System.out.println(Arrays.toString(validationErrors.toArray()));

		        // print out as XML
		        System.out.println(doc.xmlText(options));
		        

			
			try {
				 File tempFile = File.createTempFile("wpsMetdataTempFile", "xml");
				 
				 doc.save(tempFile);
			
			
			return tempFile;
			
			}
			catch(Exception e){
				
				LOGGER.error("createXMLMetadataError " + e);
				
			}
			return null;
		}

	 

}


