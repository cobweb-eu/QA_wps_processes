package pillar.authoritativedata;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Calendar;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.xml.namespace.QName;

import org.apache.log4j.Logger;
import org.apache.xmlbeans.XmlOptions;
import org.geotools.data.collection.ListFeatureCollection;
import org.geotools.data.simple.SimpleFeatureIterator;
import org.geotools.data.store.ReprojectingFeatureCollection;
import org.geotools.feature.FeatureCollection;
import org.geotools.referencing.CRS;
import org.geoviqua.gmd19157.DQDataQualityType;
import org.geoviqua.qualityInformationModel.x40.GVQDataQualityType;
import org.geoviqua.qualityInformationModel.x40.GVQDiscoveredIssueType;
import org.geoviqua.qualityInformationModel.x40.GVQMetadataDocument;
import org.geoviqua.qualityInformationModel.x40.GVQMetadataType;
import org.n52.wps.io.data.GenericFileData;
import org.n52.wps.io.data.IData;
import org.n52.wps.io.data.binding.complex.GTVectorDataBinding;
import org.n52.wps.io.data.binding.complex.GenericFileDataBinding;
import org.n52.wps.io.data.binding.literal.LiteralDoubleBinding;
import org.n52.wps.server.AbstractAlgorithm;
import org.n52.wps.server.ExceptionReport;
import org.opengis.feature.simple.SimpleFeature;
import org.opengis.feature.simple.SimpleFeatureType;
import org.opengis.referencing.FactoryException;
import org.opengis.referencing.NoSuchAuthorityCodeException;
import org.opengis.referencing.crs.CRSAuthorityFactory;
import org.opengis.referencing.crs.CoordinateReferenceSystem;

import com.vividsolutions.jts.geom.Geometry;


//Does not work in JBPM Workflow:

/** Caused by: java.lang.NullPointerException: source crs
	at org.geotools.data.store.ReprojectingFeatureCollection.&lt;init>(ReprojectingFeatureCollection.java:111)
	at org.geotools.data.store.ReprojectingFeatureCollection.&lt;init>(ReprojectingFeatureCollection.java:94)
	at org.geotools.data.store.ReprojectingFeatureCollection.&lt;init>(ReprojectingFeatureCollection.java:90)
	at pillar.authoritativedata.PointInBuffer.run(PointInBuffer.java:108)
	at org.n52.wps.server.request.ExecuteRequest.call(ExecuteRequest.java:685)**/

//to solve, get input data, test for CRS, if null create a new featurecollection with
//simplefeaturetype of inputcollection and set srs on the simplefeaturetype
//maybe put all this on a start process that checks data integrity?

public class PointInBuffer extends AbstractAlgorithm{

	Logger LOG = Logger.getLogger(PointInBuffer.class);
	
	private final String inputObservations = "inputObservations";
	private final String inputAuthoritativeData = "inputAuthoritativeData";
	private final String inputBufferDistance = "inputBufferDistance";
	
	@Override
	public Class<?> getInputDataType(String identifier) {
		if(identifier.equalsIgnoreCase( "inputObservations")){
			return GTVectorDataBinding.class;
		}
		if (identifier.equalsIgnoreCase("inputAuthoritativeData")){
			return GTVectorDataBinding.class;
		}
		if(identifier.equalsIgnoreCase("inputBufferDistance")){
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
		if(identifier.equalsIgnoreCase("metadata")){
			return GenericFileDataBinding.class;
		}
		
		return null;
	}

	@Override
	public Map<String, IData> run(Map<String, List<IData>> inputData)
			throws ExceptionReport {
		
		List <IData> inputObs = inputData.get("inputObservations");
		List <IData> inputAuth = inputData.get("inputAuthoritativeData");
		List <IData> inputDis = inputData.get("inputBufferDistance");
		
		LOG.warn("+++++++++HERE+++++++++++");
		FeatureCollection obsFcW = ((GTVectorDataBinding) inputObs.get(0)).getPayload();
		FeatureCollection authFcW = ((GTVectorDataBinding) inputAuth.get(0)).getPayload();
		double bufferDistance = ((LiteralDoubleBinding) inputDis.get(0)).getPayload();
		
		
		
		CoordinateReferenceSystem sourceCRS = null;
		
		CoordinateReferenceSystem projectCRS = null;
		
		CRSAuthorityFactory   factory = CRS.getAuthorityFactory(true);
		try {
			sourceCRS = factory.createCoordinateReferenceSystem("EPSG:4326");
			projectCRS = factory.createCoordinateReferenceSystem("EPSG:27700");
		} catch (NoSuchAuthorityCodeException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		} catch (FactoryException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		}
		
		FeatureCollection obsFc = new ReprojectingFeatureCollection(obsFcW, projectCRS);
		FeatureCollection authFc = new ReprojectingFeatureCollection(authFcW, projectCRS);
		
		
		
		ArrayList<SimpleFeature> resultArrayList = new ArrayList<SimpleFeature>(); 
		
		SimpleFeatureIterator obsIt = (SimpleFeatureIterator) obsFc.features();
		SimpleFeatureType typeF = obsIt.next().getType();
		
		obsIt.close();
		
		SimpleFeatureIterator obsIt2 = (SimpleFeatureIterator) obsFc.features();
		
		while (obsIt2.hasNext()==true){
			
			SimpleFeature tempSf = obsIt2.next();	
			
			Geometry obsGeom = (Geometry) tempSf.getDefaultGeometry();
			
			SimpleFeatureIterator authIt = (SimpleFeatureIterator) authFc.features();
			
			while (authIt.hasNext()==true){
				
				SimpleFeature tempAuth = authIt.next();
				Geometry authGeom = (Geometry) tempAuth.getDefaultGeometry();
				Geometry bufferGeom = (Geometry) obsGeom.buffer(bufferDistance);
				
				if (bufferGeom.intersects(authGeom)==true){
					resultArrayList.add(tempSf);
				}
				
			}
			
			authIt.close();
		
			
			
			
		}
		obsIt2.close();
		FeatureCollection resultFeatureCollection = new ListFeatureCollection(typeF, resultArrayList);
		FeatureCollection returnFeatureCollection = new ReprojectingFeatureCollection(resultFeatureCollection, sourceCRS);
		
	
		
		LOG.warn("Feature Collection Size " + resultFeatureCollection.size());
		
		GenericFileData fd = null;
		
		HashMap<String, Object> metadataElements = new HashMap<String,Object>();
		
		metadataElements.put("element1", "elementReturn");
		
		File file = createXMLMetadata(metadataElements);
		
		
			
		
		
		try {
			
			
			fd = new GenericFileData(file, "text/xml");
			LOG.warn("mimeType " + fd.getMimeType());
			
		
			} catch (IOException e) {
			// TODO Auto-generated catch block
			LOG.warn("IOException " + e);
		
			} 
		
		HashMap<String, IData> results = new HashMap<String, IData>();
		results.put("result", new GTVectorDataBinding((FeatureCollection)obsFcW));
		results.put("qual_result", new GTVectorDataBinding((FeatureCollection)returnFeatureCollection));
		results.put("metadata", new GenericFileDataBinding(fd));
		
		
		
		return results;
	}
	
	@Override
	public List<String> getErrors() {
		// TODO Auto-generated method stub
		return null;
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
	    issue.addNewKnownProblem().setCharacterString(inputs.get("element1").toString());
	    issue.addNewWorkAround().setCharacterString("solution");

	        // validate schema conformity
	        boolean isValid = doc.validate();
	        if ( !isValid)
	            System.out.println(Arrays.toString(validationErrors.toArray()));

	        // print out as XML
	        System.out.println(doc.xmlText(options));
	        

		
		try {
			 File tempFile = File.createTempFile("wpsMetdataTempFile", "txt");
			 
			 doc.save(tempFile);
		
		
		return tempFile;
		
		}
		catch(Exception e){
			
			LOG.error("createXMLMetadataError " + e);
			
		}
		return null;

}
	
	
}
