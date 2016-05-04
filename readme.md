# Web Processing Service for COBWEB-QA#

Quality Assurance Web Processing Services using 52North WPS. Quality tests are implemented as either Java or R processes.

To install Java processes:

1. Build cobweb-qa jar (e.g. using gradle)

2. Integrate cobweb-qa library into pom.xml. E.g. at terminal:
``mvn install:install-file -Dfile=./cobweb-qa-0.2.0.2.jar -DgroupId=eu.cobwebproject.qa -DartifactId=cobweb-qa-lib -Dversion=0.2.0.2 -Dpackaging=jar -DgeneratePom=true``
or using Eclipse M2E
``Run -> Run Configurations -> select Maven build -> enter details above (e.g. Goals = install:install-file and add parameters as in terminal above.``
3. Deploy and register processes in WPS.

4. Run unit tests from Maven. E.g. Run As -> mvn test


To install R processes:

1. Ensure the WPS4R extension to the 52North WPS is installed and working correctly.

2. Add scripts from ``WPS-R-Process-Development-COBWEB`` directory to the ``wps\R\scripts`` directory in the WPS installation location.

3. Register scripts with the WPS according to the 52North instructions.


## Bugs
* 52North 52n-wps-webapp-3.3.0 built with GeoTools appears not to be able to generate integer output fields in response documents. E.g. for QCs that take an input and replicate its field names for the output data, integer fields are lost. FeatureId type fields are often integers so this is a pain. Doubles and strings appear to be unaffected.


## Troubleshooting

* Certain processing (such as blur checking of high-resolution photographs and R scripts with complex geometric inputs) may require increases in Tomcat heap size. E.g. modify ``JAVA_OPTS="-Djava.awt.headless=true`` to something like ``-Xmx1024m`` for 1024mb of heap space.

* Incorrect execute requests made to processes can cause unexpected errors. E.g. ``Could not determine input format because none of the supported formats match the given schema ("null") and encoding ("null"). (A mimetype was not specified)`` can indicate that input data is completely missing (e.g. broken reference to WFS layer). 

* Incorrectly configured R processes can cause unexpected errors. Avoid using commas within the the WPS4R input/ouput tags as these are used for parsing. To help debugging, monitoring the RServe stdout can be useful (start the R server with RServe(TRUE) from an R prompt - only seems to work for Linux).

* An R proces returning error like ``ERROR org.n52.wps.server.request.ExecuteRequest: Exception/Error while executing ExecuteRequest for org.n52.wps.server.r.pillar2.Cleaning.UsabilityFilterOut: java.lang.NullPointerException`` 
and/or like ``ERROR org.n52.wps.server.handler.RequestHandler: exception handling ExecuteRequest.`` could mean that input variables are not defined as a correct type e.g. inputObservations is defined as a String rather than a geospatial type. 

* An R proces returning error like ``Caused by: java.lang.StringIndexOutOfBoundsException: String index out of range: -1`` is usually because of issues with output variable creation or annotation.


* Incorrectly compiled Java processes can cause unexpected errors. Check GetCapbilities requests execute correctly following addition of new processes. E.g. An error of ``ERR_INCOMPLETE_CHUNKED_ENCODING`` may occur if one process is not compiled or deployed correctly.

* Java errors similar ``Unsupported major.minor version 52.0`` indicate that a Java process may be compiled and run with different versions. Avoid this issue by compiling on the runtime machine and/or specifying source & target Java versions e.g. ``javac -Xlint -cp "../../../lib/*" -source 1.7 -target 1.7 GetLineOfSight.java``

* R processes that use the RGDAL library (rather than maptools) for reading observations will fail when points are in a multipoint data structure, which some java processes generate for some reason. This is because readOGR doesn't support multipoint structures (https://stat.ethz.ch/pipermail/r-sig-geo/2011-July/012416.html).
