package pillar.lbs;

import java.io.File;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Calendar;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.xml.namespace.QName;

import org.apache.log4j.Logger;
import org.apache.xmlbeans.XmlObject;
import org.apache.xmlbeans.XmlOptions;
import org.geotools.data.simple.SimpleFeatureIterator;
import org.geotools.feature.FeatureCollection;
import org.geoviqua.gmd19157.DQDataQualityType;
import org.geoviqua.qualityInformationModel.x40.GVQDataQualityType;
import org.geoviqua.qualityInformationModel.x40.GVQDiscoveredIssueType;
import org.geoviqua.qualityInformationModel.x40.GVQMetadataDocument;
import org.geoviqua.qualityInformationModel.x40.GVQMetadataType;
import org.n52.wps.io.data.IData;
import org.n52.wps.io.data.binding.complex.GTVectorDataBinding;
import org.n52.wps.io.data.binding.literal.LiteralStringBinding;
import org.n52.wps.server.AbstractAlgorithm;
import org.n52.wps.server.ExceptionReport;
import org.opengis.feature.simple.SimpleFeature;

public class GetDatasetSpatialAccuracy extends AbstractAlgorithm {
	/**
	 * @author Sam Meek
	 * Process designed to access the spatial accuracy of a dataset, means outputting metadata to GeoNetwork
	 * Process unfinished
	 * 
	 */
Logger LOGGER = Logger.getLogger(GetDatasetSpatialAccuracy.class);
	@Override
	public Map<String, IData> run(Map<String, List<IData>> inputData)
			throws ExceptionReport {
		List <IData> inputObs = inputData.get("inputObservations");		
		List <IData> inputSatField = inputData.get("satNumField");
		List <IData> inputAccField = inputData.get("accuracyField");
		List <IData> inputID = inputData.get("datasetID");
		List <IData> inputURL = inputData.get("catalogURL");
		
		
		FeatureCollection<?, ?> inputObservations = ((GTVectorDataBinding)inputObs.get(0)).getPayload();
		String satField = ((LiteralStringBinding)inputSatField).getPayload();
		String accField = ((LiteralStringBinding)inputAccField).getPayload();
		String datasetID = ((LiteralStringBinding)inputID).getPayload();
		String catalogURL = ((LiteralStringBinding)inputURL).getPayload();
		
		SimpleFeatureIterator obsIt = (SimpleFeatureIterator) inputObservations.features();

		
		double sumAcc = 0;
		double sumSat = 0;
		int accCounter = 0;
		int satCounter = 0;
		
		while (obsIt.hasNext()==true){
			
			SimpleFeature tempFeature = obsIt.next();
			

			if(tempFeature.getProperty(satField).getValue()!=null && 
					(Double)tempFeature.getProperty(satField).getValue()!=0){
				double satValue = (Double) tempFeature.getProperty(satField).getValue();
				sumSat = sumSat + satValue;
				satCounter ++;
			}
			
			if(tempFeature.getProperty(accField).getValue()!=null && 
					(Double)tempFeature.getProperty(accField).getValue()!=0){
				double accValue = (Double) tempFeature.getProperty(satField).getValue();
				sumSat = sumAcc + accValue;
				accCounter ++;
			}
					
		}
		
		double accAv = sumAcc/accCounter;
		double satAv = sumSat/satCounter;
		

        Database db = new Database();
        
        
        createMetadataRecord record = db.getRecord(datasetID);

        // create GVQ document
        GVQMetadataDocument doc = GVQMetadataDocument.Factory.newInstance();
        GVQMetadataType gvqMetadata = doc.addNewGVQMetadata();
        gvqMetadata.addNewLanguage().setCharacterString(record.language);
        gvqMetadata.addNewMetadataStandardName().setCharacterString(record.standard);
        gvqMetadata.addNewMetadataStandardVersion().setCharacterString(record.standardVersion);
        gvqMetadata.addNewDateStamp().setDate(record.date);
        DQDataQualityType quality = gvqMetadata.addNewDataQualityInfo2().addNewDQDataQuality();
        GVQDataQualityType gvqQuality = (GVQDataQualityType) quality.substitute(new QName("http://www.geoviqua.org/QualityInformationModel/4.0",
                                                                                          "GVQ_DataQuality"),
                                                                                GVQDataQualityType.type);
        GVQDiscoveredIssueType issue = gvqQuality.addNewDiscoveredIssue().addNewGVQDiscoveredIssue();
        issue.addNewKnownProblem().setCharacterString(record.quality.issue);
        issue.addNewWorkAround().setCharacterString(record.quality.solution);

        // validate schema conformity
        boolean isValid = doc.validate();
        if ( !isValid)
            System.out.println(Arrays.toString(validationErrors.toArray()));

        // print out as XML
        System.out.println(doc.xmlText(options));

        // store in catalog
        new CatalogClient(catalogURL).store(doc);
		
		
		return null;
	}

	@Override
	public List<String> getErrors() {
		
		return null;
	}
	
	@Override
	public Class<?> getOutputDataType(String id) {
		return null;
	}

	@Override
	public Class<?> getInputDataType(String id) {
		if(id.equalsIgnoreCase("inputObservations")){
			return GTVectorDataBinding.class;
		}
		if(id.equalsIgnoreCase("satNumField")){
			return LiteralStringBinding.class;
		}
		if(id.equalsIgnoreCase("accuracyField")){
			return LiteralStringBinding.class;
		}
		if(id.equalsIgnoreCase("datasetID")){
			return LiteralStringBinding.class;
		}
		if(id.equalsIgnoreCase("catalogURL")){
			return LiteralStringBinding.class;
		}
		return null;
	}
	
	public static class createMetadataRecord {
				public String id;
		        
				public String language;
		
		        public String standard;
		
		        public String standardVersion;
		
		        public MetadataQuality quality;
		
		        public Calendar date;
		
		
	}
   public static class MetadataQuality {
		
		        public String scope;
		
		        public String issue;
		
		        public String solution;
		
   }
   public static class CatalogClient {
	   
	           public CatalogClient(String url) {
	               //
	           }
	   
	           public boolean store(XmlObject record) {
	               return true;
	           }
	   
	       }



	 public static class Database {
		 
		 public createMetadataRecord getRecord(String id) {
		             createMetadataRecord mr = new createMetadataRecord();
		             mr.id = "c0dc2fd0-88fd-11da-a88f-000d939bc5d8";
		             mr.language = "eng";
		             mr.date = Calendar.getInstance();
		             mr.date.set(2011, 1, 17, 0, 0, 42);// "2011-02-17T00:00:42";
		             mr.standard = "GeoViQua-QIM";
		             mr.standardVersion = "4.0";
		             mr.quality = new MetadataQuality();
		             mr.quality.issue = "There is no provenance for this dataset.";
		             mr.quality.solution = "Contact the provider directly for informal inquiries.";
		 
		             return mr;
		         }
		     }

	 private static XmlOptions options;
	 
	     private static ArrayList< ? > validationErrors = new ArrayList<Object>();
	 
	     static {
	         options = new XmlOptions();
	         options.setSavePrettyPrint();
	         options.setSaveAggressiveNamespaces();
	 
	         HashMap<String, String> suggestedPrefixes = new HashMap<String, String>();
	         suggestedPrefixes.put("http://www.geoviqua.org/QualityInformationModel/4.0", "gvq");
	         options.setSaveSuggestedPrefixes(suggestedPrefixes);
	 
	         options.setErrorListener(validationErrors);
	    }
}

