package eu.cobwebproject.tests.wp4.pillar.lbs;

import java.io.IOException;

import org.junit.After;
import org.junit.Before;
import org.n52.wps.client.ExecuteRequestBuilder;
import org.n52.wps.client.WPSClientException;
import org.n52.wps.client.WPSClientSession;

import junit.framework.TestCase;
import net.opengis.wps.x100.ExecuteDocument;
import net.opengis.wps.x100.ProcessDescriptionType;

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
	
	private final String refSchema = "http://schemas.opengis.net/gml/3.1.0/base/feature.xsd";
	private final String refMimeType = "text/xml; subtype=gml/3.1.0";
		
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
	
}
