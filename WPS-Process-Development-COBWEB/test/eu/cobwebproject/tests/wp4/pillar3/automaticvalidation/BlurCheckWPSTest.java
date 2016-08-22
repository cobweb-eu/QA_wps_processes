package eu.cobwebproject.tests.wp4.pillar3.automaticvalidation;

import java.io.IOException;

import junit.framework.TestCase;
import net.opengis.wps.x100.ExecuteDocument;
import net.opengis.wps.x100.ExecuteResponseDocument;
import net.opengis.wps.x100.ProcessDescriptionType;

import org.apache.xmlbeans.XmlObject;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.n52.wps.client.ExecuteRequestBuilder;
import org.n52.wps.client.WPSClientException;
import org.n52.wps.client.WPSClientSession;

/**
 * Class to test the blur check functionality through the WPS
 * 
 * It relies on the process being installed in a local WPS
 * and the images being served from a similar location. 
 * The process populates a metadata field (DQ01) using the blur 
 * check results (0 -> 1, based on threshold). See LaplacePhotoBlurCheck
 * for more info.     
 * 
 * 
 * @author Sebastian Clarke - Environment Systems
 *
 */
public class BlurCheckWPSTest extends TestCase {
	// Configuration parameters
	private static final boolean DEBUG = true;

	private final String wpsLocation = "http://localhost:8080/wps/WebProcessingService";	// The WPS is installed here
	private final String imageBase = "http://cwlight.envsys.co.uk/img/";								// Test images served from here
	private final String processID = "pillar3.automaticvalidation.LaplacePhotoBlurCheck";				// The process we are testing
	
	private final String refSchema = "http://schemas.opengis.net/gml/3.1.0/base/feature.xsd";
	private final String refMimeType = "text/xml; subtype=gml/3.1.0";
	
	// URLs to features which have images 
	private final String urlToBlurryFeature = "http://geo.envsys.co.uk:8080/geoserver/cobweb/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=cobweb%3Acobweb_blur_shapes&maxfeatures=50&outputformat=gml3&featureID=cobweb_blur_shapes.1";
	private final String urlToSmallBlurryFeature = "http://geo.envsys.co.uk:8080/geoserver/cobweb/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=cobweb%3Acobweb_blur_shapes&maxfeatures=50&outputformat=gml3&featureID=cobweb_blur_shapes.2";
	private final String urlToSharpFeature = "http://geo.envsys.co.uk:8080/geoserver/cobweb/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=cobweb%3Acobweb_blur_shapes&maxfeatures=50&outputformat=gml3&featureID=cobweb_blur_shapes.3";
	private final String urlToButterfly = "http://geo.envsys.co.uk:8080/geoserver/cobweb/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=cobweb%3Acobweb_blur_shapes&maxfeatures=50&outputformat=gml3&featureID=cobweb_blur_shapes.4";
	private final String urlToNatBlur1 = "http://geo.envsys.co.uk:8080/geoserver/cobweb/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=cobweb%3Acobweb_blur_shapes&maxfeatures=50&outputformat=gml3&featureID=cobweb_blur_shapes.5";
	private final String urlToNature1 = "http://geo.envsys.co.uk:8080/geoserver/cobweb/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=cobweb%3Acobweb_blur_shapes&maxfeatures=50&outputformat=gml3&featureID=cobweb_blur_shapes.6";
	private final String urlToNatBlur2 = "http://geo.envsys.co.uk:8080/geoserver/cobweb/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=cobweb%3Acobweb_blur_shapes&maxfeatures=50&outputformat=gml3&featureID=cobweb_blur_shapes.7";
	private final String urlToNature2 = "http://geo.envsys.co.uk:8080/geoserver/cobweb/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=cobweb%3Acobweb_blur_shapes&maxfeatures=50&outputformat=gml3&featureID=cobweb_blur_shapes.8";
	private final String urlToWhiteMoth = "http://geo.envsys.co.uk:8080/geoserver/cobweb/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=cobweb%3Acobweb_blur_shapes&maxfeatures=50&outputformat=gml3&featureID=cobweb_blur_shapes.9";

	private final String xPathBlurryUsability = "//*:DQ_01/text()"; //Used to be "//*:Obs_Usability/text()", changed to fit with DQ* labelling
	
	private final int threshold = 1500;
	
	private WPSClientSession wpsClient;
	
	/**
	 * setUp method called before every test
	 * 
	 * Sets up a connection to the WPS
	 * @throws WPSClientException 
	 */
	@Before
	public void setUp() throws WPSClientException {
		wpsClient = WPSClientSession.getInstance();
		if(wpsClient == null) {
			System.out.println("wtf");
		}
		assertTrue(wpsClient.connect(wpsLocation));
	}
	
	/**
	 * tearDown method called after every test
	 * 
	 * Destroys connection to WPS
	 */
	@After
	public void tearDown() {
		wpsClient.disconnect(wpsLocation);
	}
		
	/**
	 * Test a blurred image fails the BlurCheck, returns bluriness result (between 0 and 1) 
	 * @throws WPSClientException 
	 * @throws IOException 
	 */
	@Test
	public void testBlurred() throws WPSClientException, IOException {
		ExecuteDocument request = buildRequest(urlToBlurryFeature);
		assertTrue(executeRequestCheckResponse(request, "0.148"));
	}
	
	/**
	 * Test a small blurred image fails the BlurCheck, returns bluriness result (between 0 and 1) 
	 * @throws WPSClientException 
	 * @throws IOException 
	 */
	@Test
	public void testBlurredSmall() throws WPSClientException, IOException {
		ExecuteDocument request = buildRequest(urlToSmallBlurryFeature);
		assertTrue(executeRequestCheckResponse(request, "0.4066666666666667"));
	}
	
	/**
	 * Test a sharp image passes the BlurCheck, returns bluriness result (value 1) 
	 * @throws IOException
	 * @throws WPSClientException
	 */
	@Test
	public void testSharp() throws IOException, WPSClientException {
		ExecuteDocument request = buildRequest(urlToSharpFeature);
		assertTrue(executeRequestCheckResponse(request, "1.0"));
	}
	
	/**
	 * Test that the butterfly passes the BlurCheck, returns bluriness result (value 1) 
	 * @throws IOException
	 * @throws WPSClientException
	 */
	@Test
	public void testButterfly() throws IOException, WPSClientException {
		ExecuteDocument request = buildRequest(urlToButterfly);
		assertTrue(executeRequestCheckResponse(request, "1.0"));
	}
	
	/**
	 * Test that the Nature 1 Blurred fails BlurCheck, returns bluriness result (between 0 and 1) 
	 * @throws IOException
	 * @throws WPSClientException
	 */
	@Test
	public void testNatureBlur1() throws IOException, WPSClientException {
		ExecuteDocument request = buildRequest(urlToNatBlur1);
		assertTrue(executeRequestCheckResponse(request, "0.2833333333333333"));
	}
	
	/**
	 * Test that the Nature 1 passes BlurCheck, returns bluriness result (value 1) 
	 * @throws IOException
	 * @throws WPSClientException
	 */
	@Test
	public void testNature1() throws IOException, WPSClientException {
		ExecuteDocument request = buildRequest(urlToNature1);
		assertTrue(executeRequestCheckResponse(request, "1.0"));
	}
	
	/**
	 * Test that the Nature blur 2 fails BlurCheck, returns bluriness result (value 1)
	 * @throws IOException
	 * @throws WPSClientException
	 */
	@Test
	public void testNatureBlur2() throws IOException, WPSClientException {
		ExecuteDocument request = buildRequest(urlToNatBlur2);
		assertTrue(executeRequestCheckResponse(request, "0.356"));
	}
	
	/**
	 * Test that the Nature 2 passes BlurCheck, returns bluriness result (value 1)
	 * @throws IOException
	 * @throws WPSClientException
	 */
	@Test
	public void testNature2() throws IOException, WPSClientException {
		ExecuteDocument request = buildRequest(urlToNature2);
		assertTrue(executeRequestCheckResponse(request, "1.0"));
	}
	
	/**
	 * Test that the White moth passes BlurCheck, returns bluriness result (value 1)
	 * @throws IOException
	 * @throws WPSClientException
	 */
	@Test
	public void testWhiteMoth() throws IOException, WPSClientException {
		ExecuteDocument request = buildRequest(urlToWhiteMoth);
		assertTrue(executeRequestCheckResponse(request, "1.0"));
	}
	
	
	/**
	 * Helper function to perform WPS request, and check the Usability parameter
	 * 
	 * @param request: The built execute request to perform
	 * @param desiredUsability: The usability value we expect to see
	 * @return boolean indicating whether the usability value matches expected
	 * @throws WPSClientException
	 */
	private boolean executeRequestCheckResponse(ExecuteDocument request, String desiredUsability) throws WPSClientException {
		Object response = wpsClient.execute(wpsLocation, request);
		if(DEBUG) System.out.println(response);
		assertTrue(response instanceof ExecuteResponseDocument);		
		ExecuteResponseDocument responseDocument = (ExecuteResponseDocument) response;
		// Return whether usability matches expected
		XmlObject[] usabilityTags = responseDocument.execQuery(xPathBlurryUsability);
		if (DEBUG) System.out.println("usabilityTags[0]: " +usabilityTags[0].newCursor().getTextValue() + " desired: " + desiredUsability);
		assertTrue(usabilityTags.length == 1);
		return usabilityTags[0].newCursor().getTextValue().equals(desiredUsability);
	}
	
	/**
	 * Helper function to build a PhotoBlurCheck WPS Request to QA Check image
	 * @param url: To the feature to check
	 * @return An execute document encoding the request
	 * @throws IOException 
	 */
	private ExecuteDocument buildRequest(String url) throws IOException {
		ProcessDescriptionType procDesc = wpsClient.getProcessDescription(wpsLocation, processID);
		ExecuteRequestBuilder reqBuilder = new ExecuteRequestBuilder(procDesc);
		reqBuilder.addComplexDataReference("inputObservations", url, refSchema, null, refMimeType);
		reqBuilder.addLiteralData("urlFieldName", "fieldcon_2");
		reqBuilder.addLiteralData("urlPrefix", imageBase);
		reqBuilder.addLiteralData("threshold", String.valueOf(threshold));
		reqBuilder.setSchemaForOutput(refSchema, "result");	
		reqBuilder.setMimeTypeForOutput(refMimeType, "result");
		
		if(DEBUG) {
			System.out.println("--- Building request ---");
			System.out.println("\t Blur check observation: \t" + url);
			System.out.println("--- Printing request ---");
			System.out.println(reqBuilder.getExecute().toString());
		}
		
		
		// Check the execute request we are about to build and return
		assertTrue(reqBuilder.isExecuteValid());
		return reqBuilder.getExecute();
	}
	
}
