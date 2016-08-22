package pillar3.automaticvalidation;

import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.MalformedURLException;
import java.net.URI;
import java.net.URL;
import java.net.URLConnection;
import java.net.URLDecoder;
import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import javax.imageio.ImageIO;

import org.apache.log4j.Logger;
import org.geotools.data.collection.ListFeatureCollection;
import org.geotools.data.simple.SimpleFeatureIterator;
import org.geotools.feature.FeatureCollection;
import org.geotools.feature.simple.SimpleFeatureBuilder;
import org.geotools.feature.simple.SimpleFeatureTypeBuilder;
import org.n52.wps.io.data.IData;
import org.n52.wps.io.data.binding.complex.GTVectorDataBinding;
import org.n52.wps.io.data.binding.literal.LiteralDoubleBinding;
import org.n52.wps.io.data.binding.literal.LiteralIntBinding;
import org.n52.wps.io.data.binding.literal.LiteralStringBinding;
import org.n52.wps.server.AbstractAlgorithm;
import org.n52.wps.server.ExceptionReport;
import org.opengis.feature.Property;
import org.opengis.feature.simple.SimpleFeature;
import org.opengis.feature.simple.SimpleFeatureType;
import org.opengis.feature.type.PropertyType;
import org.opengis.referencing.crs.CoordinateReferenceSystem;

import eu.cobwebproject.qa.automaticvalidation.BlurCheckAwt;		// implementation
import eu.cobwebproject.qa.automaticvalidation.BlurCheckRunnable; 	// interface



public class LaplacePhotoBlurCheck extends AbstractAlgorithm{
		
	/*
	public static void main(String[] args) {
		
		double threshold = 222; //ie. will be the mean in distribution test.
		long variance = 222; 
		double[] dqResult = computeDataQualityMetadata(variance,threshold);
		double  DQ_UsabilityValue = dqResult[0];
		System.out.println(dqResult[0]);
	}
	
	 */	
	
	static Logger LOG = Logger.getLogger(LaplacePhotoBlurCheck.class);
		
	public static final long MAX_IMG_SIZE = 6000000;
	
	private ArrayList<String> errors;
	
	/**
	 * @author Sam Meek (unotts) and Seb Clarke (Environment Systems) and Julian Rosser (unotts)
	 * Process to check whether a photo is blurry by using the functionality from cobweb-qa library by Michael K
	 * Output is the metadata field "DQ_01" relating to Obs_Usability which is between 0 and 1 for ranging between 
	 * not passing and passing result. qual_result is observations with only metadata 1s are returned.
	 */
	
	public LaplacePhotoBlurCheck() {
		super();
		errors = new ArrayList<String>();
	}
	
	
	@Override
	/**
	 * inputData a HashMap of the input data:
	 * this is designed to get images from PCAPI with a reference
	 * @param urlPrefix: a prefix to any extracted URL (can be null)
	 * @param inputObservations: the observations
	 * @param threshold: For sharpness, 1500 is a good start
	 * @param urlFieldName: the name of the field containing the URLs
	 * results a HashpMap of the results:
	 * @result result: the input data with the "Obs_Usability" with a 1 or a 0
	 * @result qual_result: the "Obs_Usability" 1s are returned
	 */
	public Map<String, IData> run(Map<String, List<IData>> inputData)
			throws ExceptionReport {
		
		// Get params from WPS call
		List<IData> baseList = inputData.get("urlPrefix");
		List<IData> obsList = inputData.get("inputObservations");
		List<IData> tList = inputData.get("threshold");
		List<IData> fNameList = inputData.get("urlFieldName");
		
		FeatureCollection obsFc = ((GTVectorDataBinding)obsList.get(0)).getPayload();
		String fieldName = ((LiteralStringBinding)fNameList.get(0)).getPayload();
		String urlBase = ((LiteralStringBinding)baseList.get(0)).getPayload();
		int threshold = ((LiteralIntBinding)tList.get(0)).getPayload();
		
		// Use the first feature from the feature collection as template for output...
		SimpleFeatureIterator sfi = (SimpleFeatureIterator) obsFc.features();
		CoordinateReferenceSystem inputObsCrs = obsFc.getSchema().getCoordinateReferenceSystem();
		SimpleFeature tempPropFeature = null;		// temporary feature from which to extract properties
		try {		
			tempPropFeature = sfi.next();
		} finally {
			// ensure we release resources to the OS
			sfi.close();			
		}
		
		Collection<Property> obsProp = tempPropFeature.getProperties();
		SimpleFeatureTypeBuilder resultTypeBuilder = new SimpleFeatureTypeBuilder();
		resultTypeBuilder.setName("typeBuilder");
		
		//Set crs to match the input
		resultTypeBuilder.setCRS(inputObsCrs);
		
		
		ArrayList<SimpleFeature> resultArrayList = new ArrayList<SimpleFeature>(); 
		ArrayList<SimpleFeature> qual_resultArrayList = new ArrayList<SimpleFeature>();
		
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
		
		//add DQ_Field		
		resultTypeBuilder.add("DQ_01", Double.class);
		
		// Build the result feature type
		SimpleFeatureType typeF = resultTypeBuilder.buildFeatureType();
		// Use feature type to build result features
		SimpleFeatureBuilder resultFeatureBuilder = new SimpleFeatureBuilder(typeF);
		
		sfi = (SimpleFeatureIterator) obsFc.features();
		String urlS = null;
		
		try {
			while (sfi.hasNext()) {
				SimpleFeature tempSf = sfi.next();	
				for (Property obsProperty : tempSf.getProperties()) {
					String name = obsProperty.getName().toString();
					Object value = obsProperty.getValue();
					
					LOG.warn ("Adding property " + " name " +  name + " value " + value);
					
					if(obsProperty.getName().toString().equalsIgnoreCase(fieldName)){
						urlS = obsProperty.getValue().toString();
					}
					resultFeatureBuilder.set(name, value);
				}
				
				BufferedImage original = null;
				URL url;
				
				try {
					//Escape naughty spaces and illegal chars. 
					url = convertToURLEscapingIllegalCharacters(urlBase+urlS); 	   				
					LOG.warn ("Downloading image url: " + url);
					if(imageIsTooBig(url, MAX_IMG_SIZE)) {
						throw new IOException("Image is bigger than max allowable size (or we can't tell how big it is)");
					}
					original = ImageIO.read(url);
				} catch (IOException e) {
					LOG.error(e.getMessage() + " : " + urlBase+urlS);
					errors.add(e.getMessage());
				}		
		
				// Do the check and set usability accordingly
				BlurCheckAwt blurChecker = new BlurCheckAwt(original, threshold, false); // careful with debug - tomcat installation directory must be writeable if using it.
				
				blurChecker.run();	// This should probably run on a thread! 
		
				//Usability is between 0 or 1 based on blurriness / threshold.
				//I.e. If photoVariance < threshold then DQ = photoVariance / threshold
				// else = 1
				LOG.warn ("blur check variance " + blurChecker.variance);
				LOG.warn ("blur check pass " + blurChecker.pass);
				
				double[] dqResult = computeDataQualityMetadata(blurChecker.variance,threshold);
				double  DQ_UsabilityValue = dqResult[0];
				resultFeatureBuilder.set("DQ_01", DQ_UsabilityValue);		
			
				
				// Build result
				SimpleFeature tempResult = resultFeatureBuilder.buildFeature(tempSf.getID());
				tempResult.setDefaultGeometry(tempSf.getDefaultGeometry());
				resultArrayList.add(tempResult);
				if(blurChecker.pass){
					qual_resultArrayList.add(tempResult);
				}
			}
		} finally {
			sfi.close();
		}
		
		FeatureCollection resultFeatureCollection = new ListFeatureCollection(typeF, resultArrayList);
		FeatureCollection qual_resultFeatureCollection = new ListFeatureCollection(typeF, qual_resultArrayList);

		
		// Use the first feature from the feature collection as template for output...
		SimpleFeatureIterator fi = (SimpleFeatureIterator) resultFeatureCollection.features();
		CoordinateReferenceSystem tempCrs = resultFeatureCollection.getSchema().getCoordinateReferenceSystem();
		SimpleFeature tempFeature = null;		// temporary feature from which to extract properties
		try {		
			while (fi.hasNext()) {
				tempPropFeature = fi.next();
				for (Property obsProperty : tempPropFeature.getProperties()) {
					String name = obsProperty.getName().toString();
					Object value = obsProperty.getValue();					
					LOG.warn ("FC property " + " name " +  name + " value " + value);				
				}
			}
		} finally {
			// ensure we release resources to the OS
			fi.close();			
		}
		
		
		
		HashMap<String, IData> results = new HashMap<String, IData>();
		results.put("result", new GTVectorDataBinding((FeatureCollection)resultFeatureCollection));
		results.put("qual_result", new GTVectorDataBinding((FeatureCollection)qual_resultFeatureCollection));
		
		return results;
	}

	
	/**
	 * Compute accuracy details for metadata
	 * 
	 * Uses the variance from the laplace blur check the user provdied threshold to give a DQ_01 / DQ_UsabilityElement
	 * value between 0 and 1.
	 * @param blurVariance, threshold.
	 * @return some accuracy metadata to get bunged in with the obs:
	 * 				array(DQ_usability)
	 * 
	 */
	private static double[] computeDataQualityMetadata(long imageVariance, double threshold) {
		
		double DQ_UsabilityValue = 0;				
		if (imageVariance < threshold && threshold != 0) {
			LOG.warn("variance less than the threshold");
			DQ_UsabilityValue = imageVariance/threshold;
		} else { 
			LOG.warn("variance is more than the threshold");
			DQ_UsabilityValue =	1;
		}
		

		double[] currentResult = new double[]{DQ_UsabilityValue};
		LOG.warn("Returning final DQ Val: " + DQ_UsabilityValue);
		return currentResult;			
	}
	
	
	@Override
	public List<String> getErrors() {
		return errors;
	}

	@Override
	public Class<?> getInputDataType(String id) {
		if (id.equalsIgnoreCase("inputObservations")){
			return GTVectorDataBinding.class;
		}
		
		if(id.equalsIgnoreCase("urlFieldName")){
			return LiteralStringBinding.class;
		}
		
		if(id.equalsIgnoreCase("urlPrefix")){
			return LiteralStringBinding.class;
		}
		
		if(id.equalsIgnoreCase("threshold")){
			return LiteralDoubleBinding.class;	
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
	
	private boolean imageIsTooBig(URL imageUrl, long maxImageSize) throws IOException {
		URLConnection c = imageUrl.openConnection();
		long imgSize = c.getContentLengthLong();
		LOG.warn("image file size: " + String.valueOf(imgSize));
		return imgSize > maxImageSize || imgSize == -1;
	}
	
	/**
	 * Escape URL strings to produce a URL object without illegal chars e.g. spaces  
	 * 
	 * @param string,
	 * @return URL
	 * 
	 */
	public URL convertToURLEscapingIllegalCharacters(String string) {
	    try {
	        String decodedURL = URLDecoder.decode(string, "UTF-8");
	        URL url = new URL(decodedURL);
	        URI uri = new URI(url.getProtocol(), url.getUserInfo(), url.getHost(), url.getPort(), url.getPath(), url.getQuery(), url.getRef()); 
	        return uri.toURL(); 
	    } catch (Exception ex) {
	        ex.printStackTrace();
	        return null;
	    }
	}
	

 }
