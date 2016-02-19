package pillar.automaticvalidation;

import java.awt.image.BufferedImage;
import java.io.IOException;
import java.net.URL;
import java.net.URLConnection;
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

import eu.cobwebproject.qa.automaticvalidation.BlurCheckAwt;		// implementation
import eu.cobwebproject.qa.automaticvalidation.BlurCheckRunnable; 	// interface



public class LaplacePhotoBlurCheck extends AbstractAlgorithm{
	static Logger LOG = Logger.getLogger(LaplacePhotoBlurCheck.class);
	
		

	
	public static final long MAX_IMG_SIZE = 6000000;
	
	private ArrayList<String> errors;
	
	/**
	 * @author Sam Meek (unotts) and Seb Clarke (Environment Systems) and Julian Rosser (unotts)
	 * Process to check whether a photo is blurry by using the functionality from cobweb-qa library by Michael K
	 * Output is the metadata field "Obs_Usability" which is 1 for pass criteria and 0 for not passing
	 * result is observations with 1 or 0
	 * qual_result is observations with only metadata 1s are returned
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
		resultTypeBuilder.add("Obs_Usability", Double.class);
		
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
					if(obsProperty.getName().toString().equalsIgnoreCase(fieldName)){
						urlS = obsProperty.getValue().toString();
					}
					resultFeatureBuilder.set(name, value);
				}
				
				BufferedImage original = null;
				URL url;
				
				try {
					url = new URL(urlBase+urlS);
					if(imageIsTooBig(url, MAX_IMG_SIZE)) {
						throw new IOException("Image is bigger than max allowable size (or we can't tell how big it is)");
					}
					original = ImageIO.read(url);
				} catch (IOException e) {
					LOG.error(e.getMessage() + " : " + urlBase+urlS);
					errors.add(e.getMessage());
				}		
		
				// Do the check and set usability accordingly
				BlurCheckRunnable blurChecker = new BlurCheckAwt(original, threshold, false);
				blurChecker.run();	// This should probably run on a thread! 
		
				//Usability could be more than 0 or 1 with a ratio.
				//I.e. If photoVariance < threshold then DQ = photoVariance / threshold
				resultFeatureBuilder.set("Obs_Usability", blurChecker.pass?1:0);
				
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

		HashMap<String, IData> results = new HashMap<String, IData>();
		results.put("result", new GTVectorDataBinding((FeatureCollection)resultFeatureCollection));
		results.put("qual_result", new GTVectorDataBinding((FeatureCollection)qual_resultFeatureCollection));
		
		return results;
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
	

 }
