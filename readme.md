# Web Processing Service for COBWEB-QA

Quality Assurance Web Processing Services using 52North WPS. This repository contains quality tests (Quality Controls). The Quality Controls are implemented as Java and R processes which are registered within the WPS for use in geoprocessing workflows. There are several ways to install and run the WPS and associated processes. The core environment for running the WPS are an installation of:

1. Tomcat
2. GeoServer
3. R and RServe package (if installing the R processes)

Linux (Ubuntu v12.04) and Windows (7) environments have been tested.

A Docker image is in preparation for automated deployment of the WPS.


## Installation instructions

1. Install 52North Web Processing Service (v3.4.0 and v3.3.0 have been tested). Instructions for achieving this are available from 52North.

2. Install 52North WPS geotoools package.

3. Clone and deploy Quality Control processes from this (QA_WPS_Processes) repository.

- To install Java processes:

	1. Clone and build cobweb-qa jar (e.g. using gradle). Instructions on how to do this are available in the [cobweb-qa](https://github.com/cobweb-eu/cobweb-qa) repo.

	2. Integrate cobweb-qa library (as a .jar) into your local Maven repository (pom.xml). E.g. at terminal:
``mvn install:install-file -Dfile=./cobweb-qa-0.3.1.jar -DgroupId=eu.cobwebproject.qa -DartifactId=cobweb-qa-lib -Dversion=0.3.1 -Dpackaging=jar -DgeneratePom=true``
or using Eclipse M2E
``Run -> Run Configurations -> select Maven build -> enter details above (e.g. Goals = install:install-file and add parameters as in terminal above.``

	3. Compile the Java processes in WPS-Process-Development-COBWEB as a Maven package. E.g. ``cd WPS-Process-Development-COBWEB`` and ``mvn clean package -Dmaven.test.skip=true``

	4. Deploy and register processes in WPS 

	4. Run unit tests from Maven. E.g. Run As -> mvn test


- To install R processes:

	1. Ensure the WPS4R extension to the 52North WPS is installed and working correctly.

	2. Add scripts from ``WPS-R-Process-Development-COBWEB`` directory to the ``wps\R\scripts`` directory in the WPS installation location.

	3. Register scripts with the WPS according to the 52North instructions.


## Bugs
* 52North 52n-wps-webapp-3.3.0 built with GeoTools appears not to be able to generate integer output fields in response documents. E.g. for QCs that take an input and replicate its field names for the output data, integer fields are lost. FeatureId type fields are often integers so this is a pain. Doubles and strings appear to be unaffected.


## Troubleshooting common issues

* Generating output data as GML can be problematic (WPS errors of something like ``inline: Complex Result could not be generated``) if the configuration has only been partially setup correctly. Check wps_config_geotools.xml ports match the web server. This is a common problem when testing a fresh installation.

* Certain processing (such as blur checking of high-resolution photographs and R scripts with complex geometric inputs) may require increases in Tomcat heap size. E.g. modify ``JAVA_OPTS="-Djava.awt.headless=true`` to something like ``-Xmx1024m`` for 1024mb of heap space.

* Incorrect execute requests made to processes can cause unexpected errors. E.g. ``Could not determine input format because none of the supported formats match the given schema ("null") and encoding ("null"). (A mimetype was not specified)`` can indicate that input data is completely missing (e.g. broken reference to WFS layer). 

* Incorrectly configured R processes can cause unexpected errors. Avoid using commas within the the WPS4R input/ouput tags as these are used for parsing. To help debugging, monitoring the RServe stdout can be useful (start the R server with RServe(TRUE) from an R prompt - only seems to work for Linux).

* An R proces returning error like ``ERROR org.n52.wps.server.request.ExecuteRequest: Exception/Error while executing ExecuteRequest for org.n52.wps.server.r.pillar2.Cleaning.UsabilityFilterOut: java.lang.NullPointerException`` 
and/or like ``ERROR org.n52.wps.server.handler.RequestHandler: exception handling ExecuteRequest.`` could mean that input variables are not defined as a correct type e.g. inputObservations is defined as a String rather than a geospatial type. 

* An R proces returning error like ``Caused by: java.lang.StringIndexOutOfBoundsException: String index out of range: -1`` is usually because of issues with output variable creation or annotation.

* Incorrectly compiled Java processes can cause unexpected errors. Check GetCapbilities requests execute correctly following addition of new processes. E.g. An error of ``ERR_INCOMPLETE_CHUNKED_ENCODING`` may occur if one process is not compiled or deployed correctly.

* Java errors similar ``Unsupported major.minor version 52.0`` indicate that a Java process may be compiled and run with different versions. Avoid this issue by compiling on the runtime machine and/or specifying source & target Java versions e.g. ``javac -Xlint -cp "../../../lib/*" -source 1.7 -target 1.7 GetLineOfSight.java``

* R processes that use the RGDAL library (rather than maptools) for reading observations will fail when points are in a multipoint data structure, which some java processes generate for some reason. This is because readOGR doesn't support multipoint structures (https://stat.ethz.ch/pipermail/r-sig-geo/2011-July/012416.html).

## Other non-WPS issues

* If Tomcat7 is not starting and it is not the WPS at fault, check that the JDK and JRE are configured correctly (i.e. us the JRE that ships with the JDK). This is common problem on fresh installations
