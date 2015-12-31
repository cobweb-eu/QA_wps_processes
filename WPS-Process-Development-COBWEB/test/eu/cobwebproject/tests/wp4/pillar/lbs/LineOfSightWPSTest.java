package eu.cobwebproject.tests.wp4.pillar.lbs;

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
import pillar.lbs.GetLineOfSight;

/**
 * Test cases for WPS interface to new LineOfSight from cobweb-qa
 * 
 * @author Sebastian Clarke - Environment Systems - sebastian.clarke@envsys.co.uk
 *
 */
public class LineOfSightWPSTest extends TestCase {
	// Configuration parameters
	private static final boolean DEBUG = false;
	private final String wpsLocation = "http://localhost:8080/wps/WebProcessingService";	// The WPS is installed here
	private final String processID = "pillar.lbs.GetLineOfSight";	// The process we are testing
	private final String testObservationHoneysuckle = "http://grasp.nottingham.ac.uk:8010/geoserver/CobwebTest/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=CobwebTest:SampleData&outputFormat=gml3&featureId=SampleData.4";
	
	private final String refSchema = "http://schemas.opengis.net/gml/3.1.0/base/feature.xsd";
	private final String refMimeType = "text/xml; subtype=gml/3.1.0";
	private final String surfaceModelFile = "/resources/surface/surfaceModel.txt";
	
	// instance members
	private String surfaceModel;	
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
		String instanceResourceFileName = this.getClass().getResource(surfaceModelFile).getFile().toString(); 
		surfaceModel = readFileToString(instanceResourceFileName);
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
	public void testBasic() throws IOException, WPSClientException {
		ExecuteDocument request = this.buildRequest(testObservationHoneysuckle);
		Object response = wpsClient.execute(wpsLocation, request);
		System.out.println(response);
		assertTrue(response instanceof ExecuteResponseDocument);		
		ExecuteResponseDocument responseDocument = (ExecuteResponseDocument) response;
		// Assert whether matches expected 
		
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
		reqBuilder.addLiteralData(GetLineOfSight.INPUT_SURFACEMODEL, surfaceModel);
		reqBuilder.addLiteralData(GetLineOfSight.INPUT_BEARINGNAME, "bearing");
		reqBuilder.addLiteralData(GetLineOfSight.INPUT_TILTNAME, "tilt");
		reqBuilder.addLiteralData(GetLineOfSight.INPUT_TILTNAME, "tilt");
		reqBuilder.addLiteralData(GetLineOfSight.INPUT_USERHEIGHT, "1.5");
		reqBuilder.setSchemaForOutput(refSchema, "result");	
		reqBuilder.setMimeTypeForOutput(refMimeType, "result");
		
		// Check the execute request we are about to build and return
		assertTrue(reqBuilder.isExecuteValid());
		return reqBuilder.getExecute();
	}
	
	private static String readFileToString(String fileName) throws IOException {
		BufferedReader br = new BufferedReader(new FileReader(fileName));
		try {
		    StringBuilder sb = new StringBuilder();
		    String line = br.readLine();

		    while (line != null) {
		        sb.append(line);
		        sb.append(System.lineSeparator());
		        line = br.readLine();
		    }
		    
		    return sb.toString();
		} finally {
		    br.close();
		}
	}
}
