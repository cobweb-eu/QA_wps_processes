package pillar.authoritativedata;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Calendar;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.media.jai.operator.MinDescriptor;
import javax.xml.namespace.QName;

import org.apache.log4j.Logger;
import org.apache.xmlbeans.SchemaType;
import org.apache.xmlbeans.XmlOptions;
import org.geotools.data.collection.ListFeatureCollection;
import org.geotools.data.simple.SimpleFeatureIterator;
import org.geotools.data.store.ReprojectingFeatureCollection;
import org.geotools.factory.CommonFactoryFinder;
import org.geotools.factory.GeoTools;
import org.geotools.factory.Hints;
import org.geotools.feature.FeatureCollection;
import org.geotools.gml3.bindings.IntegerListBinding;
import org.geotools.referencing.CRS;
import org.geotools.referencing.ReferencingFactoryFinder;
import org.geotools.util.IntegerList;
import org.geoviqua.gmd19157.AbstractDQCompletenessDocument;
import org.geoviqua.gmd19157.AbstractDQElementDocument;
import org.geoviqua.gmd19157.AbstractDQElementType;
import org.geoviqua.gmd19157.DQCompletenessCommissionDocument;
import org.geoviqua.gmd19157.DQCompletenessOmissionType;
import org.geoviqua.gmd19157.DQDataQualityType;
import org.geoviqua.gmd19157.DQElementPropertyType;
import org.geoviqua.gmd19157.DQElementType;
import org.geoviqua.gmd19157.DQMeasureReferenceDocument;
import org.geoviqua.gmd19157.DQQuantitativeResultType;
import org.geoviqua.gmd19157.DQResultPropertyType;
import org.geoviqua.gmd19157.impl.DQDataQualityTypeImpl;
import org.geoviqua.gmd19157.impl.DQMeasureReferenceDocumentImpl;
import org.geoviqua.qualityInformationModel.x40.GVQDataQualityPropertyType;
import org.geoviqua.qualityInformationModel.x40.GVQDataQualityType;
import org.geoviqua.qualityInformationModel.x40.GVQDiscoveredIssueType;
import org.geoviqua.qualityInformationModel.x40.GVQFeedbackCollectionDocument;
import org.geoviqua.qualityInformationModel.x40.GVQFeedbackCollectionPropertyType;
import org.geoviqua.qualityInformationModel.x40.GVQFeedbackCollectionType;
import org.geoviqua.qualityInformationModel.x40.GVQFeedbackItemType;
import org.geoviqua.qualityInformationModel.x40.GVQMetadataDocument;
import org.geoviqua.qualityInformationModel.x40.GVQMetadataType;
import org.geoviqua.qualityInformationModel.x40.GVQPublicationType;
import org.geoviqua.qualityInformationModel.x40.GVQRatingType;
import org.isotc211.x2005.gmd.MDDataIdentificationDocument;
import org.isotc211.x2005.gmd.MDDataIdentificationPropertyType;
import org.isotc211.x2005.gmd.MDDataIdentificationType;
import org.isotc211.x2005.gmd.MDMetadataDocument;
import org.isotc211.x2005.gmd.MDMetadataType;
import org.n52.wps.io.data.GenericFileData;
import org.n52.wps.io.data.IData;
import org.n52.wps.io.data.binding.complex.GTVectorDataBinding;
import org.n52.wps.io.data.binding.complex.GenericFileDataBinding;
import org.n52.wps.io.data.binding.literal.LiteralDoubleBinding;
import org.n52.wps.server.AbstractAlgorithm;
import org.n52.wps.server.ExceptionReport;
import org.opengis.feature.Property;
import org.opengis.feature.simple.SimpleFeature;
import org.opengis.feature.simple.SimpleFeatureType;
import org.opengis.filter.FilterFactory2;
import org.opengis.referencing.FactoryException;
import org.opengis.referencing.NoSuchAuthorityCodeException;
import org.opengis.referencing.crs.CRSAuthorityFactory;
import org.opengis.referencing.crs.CoordinateReferenceSystem;

import com.vividsolutions.jts.geom.Geometry;


public class DistanceTokthNeighbourFeature extends AbstractAlgorithm {
	
	Logger LOG = Logger.getLogger(DistanceTokthNeighbourFeature.class);
	
	private final String inputObservations = "inputObservations";
	private final String inputAuthoritativeData = "inputAuthoritativeData";
	
	
	
	public Class<?> getInputDataType(String identifier) {
		if(identifier.equalsIgnoreCase("inputObservations")){
			return GTVectorDataBinding.class;
		}
		if (identifier.equalsIgnoreCase("inputAuthoritativeData")){
			return GTVectorDataBinding.class;
		}
		if (identifier.equalsIgnoreCase("maxDistCriterion")){
			return double.class;
		}
		if (identifier.equalsIgnoreCase("minDistCriterion")){
			return double.class;
		}
		if (identifier.equalsIgnoreCase("omissionRate")){
			return double.class;
		}
		if (identifier.equalsIgnoreCase("commissionRate")){
			return double.class;
		}
		return null;
	}
	

	public Class<?> getOutputDataType(String identifier) {
		if(identifier.equalsIgnoreCase("result")){
			return GTVectorDataBinding.class;
		}
		if(identifier.equalsIgnoreCase("qual_result")){
			return GTVectorDataBinding.class;
		}
		
		return null;
	}
	
	
	public List<String> getErrors() {
		// TODO Auto-generated method stub
		return null;
	}

	private FeatureCollection ConvertCoordinates(FeatureCollection origColl)
	{
		CoordinateReferenceSystem sourceCRS = null;
		CoordinateReferenceSystem projectCRS = null;
		
		CRSAuthorityFactory factory = CRS.getAuthorityFactory(true);
		
		try
		{
			sourceCRS = factory.createCoordinateReferenceSystem("EPSG:4326");
			sourceCRS = factory.createCoordinateReferenceSystem("EPSG:27700");
		}
		catch (NoSuchAuthorityCodeException el)
		{
			el.printStackTrace();
		}
		catch (FactoryException ex)
		{
			ex.printStackTrace();
		}
		
		FeatureCollection obsFC = new ReprojectingFeatureCollection(origColl, projectCRS);
		return obsFC;
	}
	
	public Map<String, IData> run(Map<String, List<IData>> inputData)
			throws ExceptionReport {
		
		List <IData> inputObs = inputData.get("inputObservations");
		List <IData> inputAuth = inputData.get("inputAuthoritativeData");
		
		FeatureCollection obsFc = ((GTVectorDataBinding) inputObs.get(0)).getPayload();
		FeatureCollection authFc = ((GTVectorDataBinding) inputAuth.get(0)).getPayload();
	
		


		
		ArrayList<SimpleFeature> resultArrayList = new ArrayList<SimpleFeature>(); 
		
		HashMap<String, Object> metadataElements = new HashMap<String,Object>();
		
		SimpleFeatureIterator obsIt = (SimpleFeatureIterator) obsFc.features();
		SimpleFeatureType typeF = obsIt.next().getType();
		
		obsIt.close();
		
		SimpleFeatureIterator obsIt2 = (SimpleFeatureIterator) obsFc.features();
		
		while (obsIt2.hasNext()==true){
			
			
			SimpleFeature tempSf = obsIt2.next();	
			
			Geometry obsGeom = (Geometry) tempSf.getDefaultGeometry();
			
			
			SimpleFeatureIterator authIt = (SimpleFeatureIterator) authFc.features();
			
		
			
			while (authIt.hasNext()==true){
				boolean distCheck = false;	
				SimpleFeature tempAuth = authIt.next();
			
				Geometry authGeom = (Geometry) tempAuth.getDefaultGeometry();
				
				
				FilterFactory2 ff = CommonFactoryFinder.getFilterFactory2(GeoTools.getDefaultHints());
				//LOG.warn("keys are :" + inputData.keySet());
				//LOG.warn("omissionRate is:" + inputData.get("omissionRate").get(0).getPayload());
				double omissionRate = ((LiteralDoubleBinding)(inputData.get("omissionRate").get(0))).getPayload();
				double commissionRate = ((LiteralDoubleBinding)(inputData.get("commissionRate").get(0))).getPayload();
				
				
				
				if (inputData.get("minDistCriterion") != null)
		    	{
					//LOG.warn("minDist is not null");
					double minVal = ((LiteralDoubleBinding)(inputData.get("minDistCriterion").get(0))).getPayload(); 
				
			
				//	LOG.warn("minDist is:" + minVal);
					// dISTance value is in degrees - relates to co-ordinate ref system
					
					if (obsGeom.isWithinDistance(authGeom, minVal))
					{
						distCheck = true;
						resultArrayList.add(tempSf);
						
					}
					
					if (distCheck)
			    	{
			    		LOG.warn("distance check is true");
			    		// In here we now need to do some tests on omission and commission
			    		if (omissionRate < 33)
			    		{
			    			// Omission is low
			    			// Density about right and context of relatively good auth
			    			// Obs.ISO19157 Thematic Accuracy
			    			// NonQuantitativeAttributeCorrectness = Auth value
			    			// Auth.GeoViQuaFeedback + 1 (tempAuth.GeoViQuaFeedback?)
			    			metadataElements.put("auth.geoviquafeedback", "1");
			    			// Auth.Omission rate is decreased (tempAuth.Omisson?)
			    			// Obs.Stakeholder judgement value + 1 (obsGeom.StakeholderJudgement?)
			    		}
			    		else if (omissionRate > 66)
			    		{
			    			// Omission is high
			    			// Density about right but auth quality not so good.
			    			// Obs.ISO19157 Thematic Accuracy
			    			// NonQuantitativeAttributeCorrectness = Auth value + e
			    			// Auth.GeoViQuaFeedback + 1 (tempAuth.GeoViQuaFeedback?)
			    			metadataElements.put("auth.geoviquafeedback", "1");
			    			// Auth.Omission rate decreased (tempAuth.Omisson?)
			    			// Obs.Stakeholder Judgement + 1 (obsGeom.StakeholderJudgement?)
			    		}
			    		else
			    		{
			    			// Omission is middle
			    		}
			    		
			    		if (commissionRate < 33)
			    		{
			    			// Commission is low
			    			// Density about right and context of relatively good auth
			    			// Obs.ISO19157 Thematic Accuracy
			    			// NonQuantitativeAttributeCorrectness = Auth value 
			    			// Auth.GeoViQuaFeedback + 1 (tempAuth.GeoViQuaFeedback?)
			    			metadataElements.put("auth.geoviquafeedback", "1");
			    			// Auth.Omission rate is decreased (tempAuth.Omisson?)
			    			// Obs.Stakeholder Judgement + 1 (obsGeom.StakeholderJudgement?)
			    		}
			    		else if (commissionRate > 66)
			    		{
			    			// Commission is high
			    			// Density about right but auth quality not so good
			    			// Obs.ISO19157 Thematic Accuracy
			    			// NonQuantitativeAttributeCorrectness = Auth value 
			    			// Auth.GeoViQuaFeedback + 2 (tempAuth.GeoViQuaFeedback?)
			    			metadataElements.put("auth.geoviquafeedback", "2");
			    			// Auth.Commission rate is the same (tempAuth.Commisson?)
			    			// Obs.Stakeholder Judgement + 1 (obsGeom.StakeholderJudgement?)
			    			
			    		}
			    		else
			    		{
			    			// Commission is middle
			    		}
			    	}
					else
					{
						LOG.warn("distance check is false");
						// In here we now need to do some tests on omission and commission
						
						if (omissionRate < 33)
			    		{
			    			// Omission is low
							// Density not right and auth quality good
							// Obs.ISO19157 Thematic Accuracy
			    			// NonQuantitativeAttributeCorrectness = Auth value decreased
			    			// Auth.GeoViQuaFeedback - 1 (tempAuth.GeoViQuaFeedback?)
							metadataElements.put("auth.geoviquafeedback", "-1");
			    			// Obs.Stakeholder Judgement - 1 (obsGeom.StakeholderJudgement?)
			    		}
			    		else if (omissionRate > 66)
			    		{
			    			// Omission is high
			    			// Density not right and auth quality not so good
			    			// Obs.ISO19157 Thematic Accuracy
			    			// NonQuantitativeAttributeCorrectness = Auth value decreased
			    			// Auth.GeoViQuaFeedback + 2 (tempAuth.GeoViQuaFeedback?)
			    			metadataElements.put("auth.geoviquafeedback", "2");
			    			// Obs.Stakeholder Judgement + 2 (obsGeom.StakeholderJudgement?)
			    		}
			    		else
			    		{
			    			// Omission is middle
			    		}
			    		
			    		if (commissionRate < 33)
			    		{
			    			// Commission is low
			    			// Density not right and auth quality good
			    			// Obs.ISO19157 Thematic Accuracy
			    			// NonQuantitativeAttributeCorrectness = Auth value 
			    			// Auth.GeoViQuaFeedback - 1 (tempAuth.GeoViQuaFeedback?)
			    			metadataElements.put("auth.geoviquafeedback", "-1");
			    			// Obs.Stakeholder Judgement - 1 (obsGeom.StakeholderJudgement?)
			    		}
			    		else if (commissionRate > 66)
			    		{
			    			// Commission is high
			    			// Density not right and auth quality not so good, but agreement of quality
			    			// Obs.ISO19157 Thematic Accuracy
			    			// NonQuantitativeAttributeCorrectness = Auth value + e
			    			// Auth.GeoViQuaFeedback + 1 (tempAuth.GeoViQuaFeedback?)
			    			metadataElements.put("auth.geoviquafeedback", "1");
			    			// Auth.Commission + e (tempAuth.Commission?)
			    			// Obs.Stakeholder Judgement - 1 (obsGeom.StakeholderJudgement?)

			    		}
			    		else
			    		{
			    			// Commission is middle
			    		}
					}
		    	}
		    	
				
		    	if (inputData.get("maxDistCriterion") != null)
		    	{
		    	//	LOG.warn("maxdist is not null");
		    		double maxVal = ((LiteralDoubleBinding)(inputData.get("maxDistCriterion").get(0))).getPayload(); 

				//	LOG.warn("maxDist is:" + maxVal);
					if (obsGeom.isWithinDistance(authGeom, maxVal))
					{
						distCheck = true;
						resultArrayList.add(tempSf);
						
					}
					
					if (distCheck)
			    	{
			    		LOG.warn("distance check is true");
			    		// In here we now need to do some tests on omission and commission
			    		if (omissionRate < 33)
			   		{
			    			// Omission is low
			    			// Density about right and context of relatively good auth
			    			// Obs.ISO19157 Thematic Accuracy
			    			// NonQuantitativeAttributeCorrectness = Auth value 
			    			// Auth.GeoViQuaFeedback + 1 (tempAuth.GeoViQuaFeedback?)
			    			metadataElements.put("auth.geoviquafeedback", "1");
			    			// Auth.Omission rate is decreased (tempAuth.Omission?)
			    			// Obs.Stakeholder judgement value + 1 (obsGeom.StakeholderJudgement?)
			    		}
			    		else if (omissionRate > 66)
			    		{
			    			// Omission is high
			    			// Density about right but auth quality not so good
			    			// Obs.ISO19157 Thematic Accuracy
			    			// NonQuantitativeAttributeCorrectness = Auth value + e
			    			// Auth.GeoViQuaFeedback + 1 (tempAuth.GeoViQuaFeedback?)
			    			metadataElements.put("auth.geoviquafeedback", "1");
			    			// Auth.Omission rate is decreased (tempAuth.Omission?)
			    			// Obs.Stakeholder judgement value + 1 (obsGeom.StakeholderJudgement?)
			    		}
			    		else
			    		{
			    			// Omission is middle
			    		}
			    		
			    		if (commissionRate < 33)
			    		{
			    			// Commission is low
			    			// Density about right and context of relatively good auth
			    			// Obs.ISO19157 Thematic Accuracy
			    			// NonQuantitativeAttributeCorrectness = Auth value 
			    			// Auth.GeoViQuaFeedback + 1 (tempAuth.GeoViQuaFeedback?)
			    			metadataElements.put("auth.geoviquafeedback", "1");
			    			// Auth.Omission rate is decreased (tempAuth.Omission?)
			    			// Obs.Stakeholder judgement value + 1 (obsGeom.StakeholderJudgement?)
			    		}
			    		else if (commissionRate > 66)
			    		{
			    			// Commission is high
			    			// Density about right but auth quality not so good
			    			// Obs.ISO19157 Thematic Accuracy
			    			// NonQuantitativeAttributeCorrectness = Auth value 
			    			// Auth.GeoViQuaFeedback + 1 (tempAuth.GeoViQuaFeedback?)
			    			metadataElements.put("auth.geoviquafeedback", "1");
			    			// Auth.Commission rate is the same (tempAuth.Commission?)
			    			// Obs.Stakeholder judgement value + 1 (obsGeom.StakeholderJudgement?)
			    		}
			    		else
			    		{
			    			// Commission is middle
			    		}
			    	}
					else
					{
						LOG.warn("distance check is false");
						// In here we now need to do some tests on omission and commission
						if (omissionRate < 33)
			    		{
			    			// Omission is low
							// Density not right and auth quality good
			    			// Obs.ISO19157 Thematic Accuracy
			    			// NonQuantitativeAttributeCorrectness = Auth value increased
			    			// Auth.GeoViQuaFeedback + 1 (tempAuth.GeoViQuaFeedback?)
							metadataElements.put("auth.geoviquafeedback", "1");
			    			// Obs.Stakeholder judgement value + 1  (obsGeom.StakeholderJudgement?)
			    		}
			    		else if (omissionRate > 66)
			    		{
			    			// Omission is high
			    			// Density not right and auth quality not so good
			    			// Obs.ISO19157 Thematic Accuracy
			    			// NonQuantitativeAttributeCorrectness = Auth value increased
			    			// Auth.GeoViQuaFeedback - 1 (tempAuth.GeoViQuaFeedback?)
			    			metadataElements.put("auth.geoviquafeedback", "-1");
			    			// Obs.Stakeholder judgement value + 1 (obsGeom.StakeholderJudgement?)
			    		}
			    		else
			    		{
			    			// Omission is middle
			    		}
			    		
			    		if (commissionRate < 33)
			    		{
			    			// Commission is low
			    			// Density not right and auth quality good
			    			// Obs.ISO19157 Thematic Accuracy
			    			// NonQuantitativeAttributeCorrectness = Auth value + e
			    			// Auth.GeoViQuaFeedback + 1 (tempAuth.GeoViQuaFeedback?)
			    			metadataElements.put("auth.geoviquafeedback", "1");
			    			// Obs.Stakeholder judgement value + 1 (obsGeom.StakeholderJudgement?)
			    		}
			    		else if (commissionRate > 66)
			    		{
			    			// Commission is high
			    			// Density not right and auth quality not so good but no agreement of quality
			    			// Obs.ISO19157 Thematic Accuracy
			    			// NonQuantitativeAttributeCorrectness = Auth value - e
			    			// Auth.GeoViQuaFeedback - 1 (tempAuth.GeoViQuaFeedback?)
			    			metadataElements.put("auth.geoviquafeedback", "-1");
			    			// Auth.Commission - e (tempAuth.Commission?)
			    			// Obs.Stakeholder judgement value is the same (obsGeom.StakeholderJudgement?)
			    		}
			    		else
			    	   {
			    			// Commission is middle
			    		}
					}
		    	}
		    	
				
			}
			
			
			
			authIt.close();
		
			
			
			
		}
		obsIt2.close();
		FeatureCollection resultFeatureCollection = new ListFeatureCollection(typeF, resultArrayList);
		
		LOG.warn("Distance within Feature Collection Size " + resultFeatureCollection.size());
		
		
		HashMap<String, IData> results = new HashMap<String, IData>();
		try
		{
		results.put("result", new GTVectorDataBinding((FeatureCollection)obsFc));
		results.put("qual_result", new GTVectorDataBinding((FeatureCollection)resultFeatureCollection));
		
		}
		catch (Exception e)
		{
			LOG.warn("Exception " + e);
		}
		
		return results;
		
		//LOG.warn(results)
		
		
	}
	

	
}
