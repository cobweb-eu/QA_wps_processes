package pillar.automaticvalidation;

import java.awt.Color;
import java.awt.Image;
import java.awt.image.BufferedImage;
import java.awt.image.RenderedImage;
import java.io.File;
import java.io.IOException;
import java.net.URL;
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
import org.n52.wps.io.data.GenericFileData;
import org.n52.wps.io.data.IData;
import org.n52.wps.server.AbstractAlgorithm;
import org.n52.wps.server.ExceptionReport;
import org.n52.wps.io.data.binding.complex.GTRasterDataBinding;
import org.n52.wps.io.data.binding.complex.GTVectorDataBinding;
import org.n52.wps.io.data.binding.complex.GenericFileDataBinding;
import org.n52.wps.io.data.binding.literal.LiteralDoubleBinding;
import org.n52.wps.io.data.binding.literal.LiteralIntBinding;
import org.n52.wps.io.data.binding.literal.LiteralStringBinding;
import org.opengis.feature.Property;
import org.opengis.feature.simple.SimpleFeature;
import org.opengis.feature.simple.SimpleFeatureType;
import org.opengis.feature.type.PropertyType;

import com.vividsolutions.jts.geom.Geometry;



public class LaplacePhotoBlurCheck extends AbstractAlgorithm{
	static Logger LOG = Logger.getLogger(LaplacePhotoBlurCheck.class);
	/**
	 * @author Sam Meek
	 * Process to check whether a photo is blurry by using a Laplace transform on a histogram stretched version of the black and white image
	 * Output is the metadata field "Obs_Usability" which is 1 for pass criteria and 0 for not passing
	 * result is observations with 1 or 0
	 * qual_result is observations with only metadata 1s are returned
	 */
	
	
	@Override
	/**
	 * inputData a HashMap of the input data:
	 * this is designed to get images from PCAPI with a reference
	 * @param urlPrefix: a prefix to any extracted URL (can be null)
	 * @param inputObservations: the observations
	 * @param threshold: between 0 - 255
	 * @param urlFieldName: the name of the field containing the URLs
	 * results a HashpMap of the results:
	 * @result result: the input data with the "Obs_Usability" with a 1 or a 0
	 * @result qual_result: the "Obs_Usability" 1s are returned
	 */
	public Map<String, IData> run(Map<String, List<IData>> inputData)
			throws ExceptionReport {
		
		List<IData> baseList = inputData.get("urlPrefix");
		List<IData> obsList = inputData.get("inputObservations");
		List<IData> tList = inputData.get("threshold");
		List<IData> fNameList = inputData.get("urlFieldName");
		
		
		FeatureCollection obsFc = ((GTVectorDataBinding)obsList.get(0)).getPayload();
		String fieldName = ((LiteralStringBinding)fNameList.get(0)).getPayload();
		String urlBase = ((LiteralStringBinding)baseList.get(0)).getPayload();
		int threshold = ((LiteralIntBinding)tList.get(0)).getPayload();
		
		SimpleFeatureIterator sfi = (SimpleFeatureIterator) obsFc.features();
		SimpleFeature tempPropFeature = sfi.next();
		
		Collection<Property> obsProp = tempPropFeature.getProperties();
		//SimpleFeatureType typeF = tempPropFeature.getType();
		
		SimpleFeatureTypeBuilder resultTypeBuilder = new SimpleFeatureTypeBuilder();
		resultTypeBuilder.setName("typeBuilder");
		
		ArrayList<SimpleFeature> resultArrayList = new ArrayList<SimpleFeature>(); 
		ArrayList<SimpleFeature> qual_resultArrayList = new ArrayList<SimpleFeature>();
		
		Iterator<Property> pItObs = obsProp.iterator();
		
	
		
		sfi.close();
		while (pItObs.hasNext()==true){
			
			try{
				
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
		
		resultTypeBuilder.add("Obs_Usability", Integer.class);
		
		SimpleFeatureType typeF = resultTypeBuilder.buildFeatureType();
		SimpleFeatureBuilder resultFeatureBuilder = new SimpleFeatureBuilder(typeF);
		
		SimpleFeatureIterator obsIt2 = (SimpleFeatureIterator) obsFc.features();
		String urlS = null;
		
		while (obsIt2.hasNext()==true){
			
			SimpleFeature tempSf = obsIt2.next();	
			for (Property obsProperty : tempSf.getProperties()){

				
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
				original = ImageIO.read(url);
				LOG.warn("image size = " + original.getWidth() + " " + original.getHeight());
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}		
			
			BufferedImage equalisedImage = histogramEqualization(original);
			BufferedImage laplaceImage = getLaplaceImage(equalisedImage);
			BufferedImage greyLapImage = convertImageToGrey(laplaceImage);
			int i = getBlurryImageDecision(greyLapImage, threshold);
			
			resultFeatureBuilder.set("Obs_Usability", i);
			SimpleFeature tempResult = resultFeatureBuilder.buildFeature(tempSf.getID());
			Geometry tempGeom = (Geometry) tempSf.getDefaultGeometry();
			tempResult.setDefaultGeometry(tempGeom);
			resultArrayList.add(tempResult);
			if(i == 1){
				qual_resultArrayList.add(tempResult);
			}
			
		}
		obsIt2.close();
		FeatureCollection resultFeatureCollection = new ListFeatureCollection(typeF, resultArrayList);
		FeatureCollection qual_resultFeatureCollection = new ListFeatureCollection(typeF, qual_resultArrayList);

		
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
		// TODO Auto-generated method stub
		if(id.equalsIgnoreCase("result")){
			return GTVectorDataBinding.class;
		}
		if(id.equalsIgnoreCase("qual_result")){
		return GTVectorDataBinding.class;
		}
		return null;
		
	}
	
	private BufferedImage getLaplaceImage(BufferedImage original){
		
		BufferedImage pic1 = histogramEqualization(original);
		double threshold = 0;
		BufferedImage pic2 = new BufferedImage(pic1.getWidth(), pic1.getHeight(), BufferedImage.TYPE_INT_RGB);
		int height = pic1.getHeight();
		int width = pic1.getWidth();
		for (int y = 1; y < height - 1; y++) {
            for (int x = 1; x < width - 1; x++) {
                Color c00 = new Color(pic1.getRGB(x-1, y-1));
                Color c01 = new Color(pic1.getRGB(x-1, y  ));
                Color c02 = new Color(pic1.getRGB(x-1, y+1));
                Color c10 = new Color(pic1.getRGB(x  , y-1));
                Color c11 = new Color(pic1.getRGB(x  , y  ));
                Color c12 = new Color(pic1.getRGB(x  , y+1));
                Color c20 = new Color(pic1.getRGB(x+1, y-1));
                Color c21 = new Color(pic1.getRGB(x+1, y  ));
                Color c22 = new Color(pic1.getRGB(x+1, y+1));
                int r = -c00.getRed() -   c01.getRed() - c02.getRed() +
                        -c10.getRed() + 8*c11.getRed() - c12.getRed() +
                        -c20.getRed() -   c21.getRed() - c22.getRed();
                int g = -c00.getGreen() -   c01.getGreen() - c02.getGreen() +
                        -c10.getGreen() + 8*c11.getGreen() - c12.getGreen() +
                        -c20.getGreen() -   c21.getGreen() - c22.getGreen();
                int b = -c00.getBlue() -   c01.getBlue() - c02.getBlue() +
                        -c10.getBlue() + 8*c11.getBlue() - c12.getBlue() +
                        -c20.getBlue() -   c21.getBlue() - c22.getBlue();
                r = Math.min(255, Math.max(0, r));
                g = Math.min(255, Math.max(0, g));
                b = Math.min(255, Math.max(0, b));
                Color c = new Color(r, g, b);
                
                pic2.setRGB(x, y, c.getRGB());
                
            }
		
		
	}
		
		
		return pic2;
}
	
	private static BufferedImage histogramEqualization(BufferedImage original) {
		 
        int red;
        int green;
        int blue;
        int alpha;
        int newPixel = 0;
 
        // Get the Lookup table for histogram equalization
        ArrayList<int[]> histLUT = histogramEqualizationLUT(original);
 
        BufferedImage histogramEQ = new BufferedImage(original.getWidth(), original.getHeight(), original.getType());
 
        for(int i=0; i<original.getWidth(); i++) {
            for(int j=0; j<original.getHeight(); j++) {
 
                // Get pixels by R, G, B
                alpha = new Color(original.getRGB (i, j)).getAlpha();
                red = new Color(original.getRGB (i, j)).getRed();
                green = new Color(original.getRGB (i, j)).getGreen();
                blue = new Color(original.getRGB (i, j)).getBlue();
 
                // Set new pixel values using the histogram lookup table
                red = histLUT.get(0)[red];
                green = histLUT.get(1)[green];
                blue = histLUT.get(2)[blue];
 
                // Return back to original format
                newPixel = colorToRGB(alpha, red, green, blue);
 
                // Write pixels into image
                histogramEQ.setRGB(i, j, newPixel);
 
            }
        }
        
        LOG.warn("Histogram Image " + histogramEQ.getWidth() + " " + histogramEQ.getHeight());
       
		/**try {
			File file = new File ("/Users/lgzsam/Downloads/test1.jpg");
      	  
      	  ImageIO.write(histogramEQ, "jpeg", file);
		} catch (IOException e) {
			LOG.error("IOException " + e);
			e.printStackTrace();
		}**/
		
 
        return histogramEQ;
 
    }
 
    // Get the histogram equalization lookup table for separate R, G, B channels
    private static ArrayList<int[]> histogramEqualizationLUT(BufferedImage input) {
 
        // Get an image histogram - calculated values by R, G, B channels
        ArrayList<int[]> imageHist = imageHistogram(input);
 
        // Create the lookup table
        ArrayList<int[]> imageLUT = new ArrayList<int[]>();
 
        // Fill the lookup table
        int[] rhistogram = new int[256];
        int[] ghistogram = new int[256];
        int[] bhistogram = new int[256];
 
        for(int i=0; i<rhistogram.length; i++) rhistogram[i] = 0;
        for(int i=0; i<ghistogram.length; i++) ghistogram[i] = 0;
        for(int i=0; i<bhistogram.length; i++) bhistogram[i] = 0;
 
        long sumr = 0;
        long sumg = 0;
        long sumb = 0;
 
        // Calculate the scale factor
        float scale_factor = (float) (255.0 / (input.getWidth() * input.getHeight()));
 
        for(int i=0; i<rhistogram.length; i++) {
            sumr += imageHist.get(0)[i];
            int valr = (int) (sumr * scale_factor);
            if(valr > 255) {
                rhistogram[i] = 255;
            }
            else rhistogram[i] = valr;
 
            sumg += imageHist.get(1)[i];
            int valg = (int) (sumg * scale_factor);
            if(valg > 255) {
                ghistogram[i] = 255;
            }
            else ghistogram[i] = valg;
 
            sumb += imageHist.get(2)[i];
            int valb = (int) (sumb * scale_factor);
            if(valb > 255) {
                bhistogram[i] = 255;
            }
            else bhistogram[i] = valb;
        }
 
        imageLUT.add(rhistogram);
        imageLUT.add(ghistogram);
        imageLUT.add(bhistogram);
 
        return imageLUT;
 
    }
 
    // Return an ArrayList containing histogram values for separate R, G, B channels
    public static ArrayList<int[]> imageHistogram(BufferedImage input) {
 
        int[] rhistogram = new int[256];
        int[] ghistogram = new int[256];
        int[] bhistogram = new int[256];
 
        for(int i=0; i<rhistogram.length; i++) rhistogram[i] = 0;
        for(int i=0; i<ghistogram.length; i++) ghistogram[i] = 0;
        for(int i=0; i<bhistogram.length; i++) bhistogram[i] = 0;
 
        for(int i=0; i<input.getWidth(); i++) {
            for(int j=0; j<input.getHeight(); j++) {
 
                int red = new Color(input.getRGB (i, j)).getRed();
                int green = new Color(input.getRGB (i, j)).getGreen();
                int blue = new Color(input.getRGB (i, j)).getBlue();
 
                // Increase the values of colors
                rhistogram[red]++; ghistogram[green]++; bhistogram[blue]++;
 
            }
        }
 
        ArrayList<int[]> hist = new ArrayList<int[]>();
        hist.add(rhistogram);
        hist.add(ghistogram);
        hist.add(bhistogram);
 
        return hist;
 
    }
 
    // Convert R, G, B, Alpha to standard 8 bit
    private static int colorToRGB(int alpha, int red, int green, int blue) {
 
        int newPixel = 0;
        newPixel += alpha; newPixel = newPixel << 8;
        newPixel += red; newPixel = newPixel << 8;
        newPixel += green; newPixel = newPixel << 8;
        newPixel += blue;
 
        return newPixel;
 
    }
    private BufferedImage convertImageToGrey(BufferedImage original){
		
    	
    	BufferedImage greyImage = new BufferedImage(original.getWidth(), 
    			original.getHeight(),BufferedImage.TYPE_BYTE_GRAY);
    	
        int  width = original.getWidth();
        int  height = original.getHeight();
         
         for(int i=0; i<height; i++){
         
            for(int j=0; j<width; j++){
            
               Color c = new Color(original.getRGB(j, i));
               int red = (int)(c.getRed() * 0.299);
               int green = (int)(c.getGreen() * 0.587);
               int blue = (int)(c.getBlue() *0.114);
               Color newColor = new Color(red+green+blue,
               
               red+green+blue,red+green+blue);
               
               greyImage.setRGB(j,i,newColor.getRGB());
            }
         }
         
         LOG.warn("Grey Image " + greyImage.getWidth() + " " + greyImage.getHeight());
         
 	/**	try {
 			File file = new File ("/Users/lgzsam/Downloads/test2.jpg");
       	  
       	  ImageIO.write(greyImage, "jpeg", file);
 		} catch (IOException e) {
 			LOG.error("IOException " + e);
 			e.printStackTrace();
 		}**/
 		
    	
    	
    	return greyImage;
    	
    }
    
    public int getBlurryImageDecision(BufferedImage image, int threshold){
    	int t = 1;
    	
    	 int  width = image.getWidth();
         int  height = image.getHeight();
         
         for (int i = 0; i < image.getWidth(); i++){
        	 for (int j = 0; j < image.getHeight(); j++ ){
        		 if(image.getRGB(i, j) > threshold){
        			 t = 0;
        		 }
        	 }
         }
    	
    	return t;
    }
 }
