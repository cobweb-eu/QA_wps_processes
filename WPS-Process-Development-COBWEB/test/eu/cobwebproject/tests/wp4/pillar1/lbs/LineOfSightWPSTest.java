package eu.cobwebproject.tests.wp4.pillar1.lbs;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;

import org.apache.xmlbeans.XmlObject;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.n52.wps.client.ExecuteRequestBuilder;
import org.n52.wps.client.WPSClientException;
import org.n52.wps.client.WPSClientSession;

import junit.framework.TestCase;
import net.opengis.wps.x100.ExecuteDocument;
import net.opengis.wps.x100.ExecuteResponseDocument;
import net.opengis.wps.x100.ProcessDescriptionType;
import pillar1.lbs.GetLineOfSight;

/**
 * Test cases for WPS interface to new LineOfSight from cobweb-qa
 * 
 * @author Sebastian Clarke - Environment Systems - sebastian.clarke@envsys.co.uk
 *
 */
public class LineOfSightWPSTest extends TestCase {	
	private static final String XPATH_GEOMETRY = "//*:Point/*:pos/text()";
	private static final boolean DEBUG = false;
	
	// Configuration parameters

	private final String wpsLocation = "http://localhost:8010/wps/WebProcessingService";	// The WPS is installed here
	private final String processID = "pillar1.lbs.GetLineOfSight";	// The process we are testing
	private final String testObservationHoneysuckle = "http://geo.envsys.co.uk:8080/geoserver/cobweb/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=cobweb:CobwebSampleData&outputFormat=gml3&featureId=CobwebSampleData.61&srsName=EPSG:27700";

	private final String refSchema = "http://schemas.opengis.net/gml/3.1.0/base/feature.xsd";
	private final String refMimeType = "text/xml; subtype=gml/3.1.0";
	// urls to hosted surface models
	private final String testRemoteSurfaceModelObs = "http://www.envsys.co.uk/cobweb/surfaceModel_sn7698.txt";
	private final String testRemoteSurfaceModel = "http://www.envsys.co.uk/cobweb/surfaceModel.txt";
	
	// instance members
	private WPSClientSession wpsClient; 
	
	/**
	 * setUp method called before every test
	 * 
	 * Sets up a connection to the WPS
	 * @throws WPSClientException 
	 * @throws IOException 
	 */
	@Before
	public void setUp() throws WPSClientException, IOException {
		wpsClient = WPSClientSession.getInstance();
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
	
	@Test
	public void testObservationOutOfBounds() throws IOException, WPSClientException {
		ExecuteDocument request = buildRequest(testObservationHoneysuckle, testRemoteSurfaceModel);
		Object response = wpsClient.execute(wpsLocation, request);
		assertTrue(response instanceof ExecuteResponseDocument);		
		ExecuteResponseDocument responseDocument = (ExecuteResponseDocument) response;
		// Assert whether matches expected 
		XmlObject[] positionTags = responseDocument.execQuery(XPATH_GEOMETRY);
		assertTrue("Too many results", positionTags.length <= 1);
		assertTrue("No results found", positionTags.length == 1);
		assertTrue(positionTags[0].newCursor().getTextValue().equals("-1.0 -1.0"));
	}
	
	@Test
	public void testObservationWithCustomHeightmap() throws IOException, WPSClientException {
		ExecuteDocument request = buildRequest(testObservationHoneysuckle, testRemoteSurfaceModelObs);
		Object response = wpsClient.execute(wpsLocation, request);
		assertTrue(response instanceof ExecuteResponseDocument);		
		ExecuteResponseDocument responseDocument = (ExecuteResponseDocument) response;
		// Assert whether matches expected 
		XmlObject[] positionTags = responseDocument.execQuery(XPATH_GEOMETRY);
		assertTrue("Too many results", positionTags.length <= 1);
		assertTrue("No results found", positionTags.length == 1);
		assertTrue(positionTags[0].newCursor().getTextValue().equals("276283.41790517466 298378.18305935315"));
	}
	
	/**
	 * Helper function to build a Line of sight WPS request
	 * @param url: To the feature to run LOS on
	 * @param surfaceModel: url to the surface model to check against
	 * @return An execute document encoding the request
	 * @throws IOException 
	 */
	private ExecuteDocument buildRequest(String url, String surfaceModel) throws IOException {
		ProcessDescriptionType procDesc = wpsClient.getProcessDescription(wpsLocation, processID);
		ExecuteRequestBuilder reqBuilder = new ExecuteRequestBuilder(procDesc);
		reqBuilder.addComplexDataReference(GetLineOfSight.INPUT_OBS, url, refSchema, null, refMimeType);
		reqBuilder.addComplexDataReference(GetLineOfSight.INPUT_SURFACEMODEL, surfaceModel, null, null, null);
		reqBuilder.addLiteralData(GetLineOfSight.INPUT_BEARINGNAME, "bearing");
		reqBuilder.addLiteralData(GetLineOfSight.INPUT_TILTNAME, "tilt");
		reqBuilder.addLiteralData(GetLineOfSight.INPUT_USERHEIGHT, "1.5");
		reqBuilder.setSchemaForOutput(refSchema, "result");	
		reqBuilder.setMimeTypeForOutput(refMimeType, "result");
		
		if(DEBUG) {
			System.out.println("--- Building request ---");
			System.out.println("\t Observation: \t" + url);
			System.out.println("\t Surface Model: \t" + surfaceModel);
		}
		
 		// Check the execute request we are about to build and return
		assertTrue(reqBuilder.isExecuteValid());
		return reqBuilder.getExecute();
	}
}
