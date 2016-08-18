# Quality Assurance Web Processing Service

Quality Assurance Web Processing Services using 52North WPS. 
## Description

This repository contains quality tests (Quality Controls). The Quality Controls are implemented as Java and R processes which are registered within the WPS for use in geoprocessing workflows. The processes have been deployed on both Linux (Ubuntu) and Windows (7) environments. There are several ways to install and run the WPS and associated processes. The core environment for running the WPS are an installation of:

1. [Tomcat](http://tomcat.apache.org/) 
2. [GeoServer](http://geoserver.org/download/)
3. [R](https://www.r-project.org/), if installing the R processes. 
4. [52NorthWPS](http://52north.org/communities/geoprocessing/wps/) with GeoTools and WPS4R extensions.

For the R processes, RServe is also required as are various R packages which should be installed from the R terminal as normal.

For convenience and rapid set up a Docker image has been made available. Alternatively the system may be compiled and deployed from source.

## Structure

The repository contains two dirs:
* ``/WPS-Process-Development-COBWEB`` - contains Java process implementations
* ``/WPS-R-Process-Development-COBWEB`` - contains R process implementations
* ``/SampleWPSExecuteRequests`` - contains sample ExecuteRequests for deployed WPS processes

## Documentation
Additional documentation and learning materials on using the Web Processing Service within the workflow editor can be found in the [QAwAT](https://github.com/cobweb-eu/workflow-at) repository and workflow [wiki](https://github.com/cobweb-eu/workflow-at/wiki).
Further details of the software can be found in the COBWEB D4.6 and D4.7 deliverables.

## Installation
### Docker image installation

A Docker image with Tomcat, R, 52NorthWPS and the Quality Control processes is available. The image is forked from the 52North [tethys_docker](https://github.com/tethysplatform/tethys_docker), uses 52North WPS 3.3.0 (with some patches applied) is started in the same way with:

    $ sudo docker run -d -p 8080:8080 --name n52wps maptopixel/n52wps-mvn-git
    


### Full installation instructions

1. Install 52North Web Processing Service, v3.4.0 and v3.3.0 (however the latter requires some patches) have been tested. Instructions for achieving this are available from 52North. For patching v3.3.0, updated versions of the [52n-wps-r-3.3.0.jar](http://geoprocessing.forum.52north.org/Reading-raster-data-inputs-with-wpsr-td4026006.html) and [52n-wps-io-geotools-3.3.0.jar](http://geoprocessing.forum.52north.org/Chaining-FeatureCollections-td4025861.html) are required.

2. Install 52North WPS geotoools package.

3. Clone and deploy Quality Control processes from this (QA_WPS_Processes) repository.

- To install Java processes:

	1. Clone and build cobweb-qa jar (e.g. using gradle). Instructions on how to do this are available in the [cobweb-qa](https://github.com/cobweb-eu/cobweb-qa) repo.

	2. Integrate cobweb-qa library (as a .jar) into your local Maven repository (pom.xml). E.g. at terminal: 
	``mvn install:install-file -Dfile=../../cobweb-qa/build/libs/cobweb-qa-0.3.1.jar -DgroupId=eu.cobwebproject.qa -DartifactId=cobweb-qa-lib -Dversion=0.3.1 -Dpackaging=jar -DgeneratePom=true`` 
	or using Eclipse M2E: ``Run -> Run Configurations -> select Maven build -> enter details above (e.g. Goals = install:install-file and add parameters as in terminal above.``
	
	3. Compile the Java processes in WPS-Process-Development-COBWEB as a Maven package. E.g. ``cd WPS-Process-Development-COBWEB`` and ``mvn clean package -Dmaven.test.skip=true``. Note that the tests must be skipped until they are compliled and registered.
	
	4. Copy the compiled processes to the deployed WPS app (two possibilities here - don't mix these as dependency conflicts can occur). Either copy the resulting ``with-dependencies.jar`` file from the previous step and copy to something like ``wps/WEB-INF/lib/``. The jar contains the compiled process and associated ProcessDescription definitions required for their deployment and invocation in the WPS.
	
	OR copy the bytecode files (e.g. ``cp -r target/classes/pillar1 /usr/share/tomcat7-wps/wpshome/WEB-INF/classes/``)

	5. Register processes in the WPS by editing wps_config_geotools.xml. (e.g. in the Docker image this is ``/usr/share/tomcat7-wps/wpshome/config``).

	6. The unit tests can now be run from Maven. E.g. ``cd WPS-Process-Development-COBWEB`` and ``mvn clean package -Dmaven.test.skip=false``

- To install R processes:

	1. Ensure the WPS4R extension to the 52North WPS is installed and is working correctly.

	2. Add scripts from ``WPS-R-Process-Development-COBWEB`` directory to the ``wps\R\scripts`` directory in the WPS installation location. ``(e.g. cp *R /usr/share/tomcat7-wps/wpshome/R/scripts/; chown tomcat7:tomcat7 *R)``

	3. Register scripts with the WPS according to the 52North instructions.


## Bugs
* 52North 52n-wps-webapp-3.3.0 built with GeoTools appears not to be able to generate integer output fields in response documents. E.g. for QCs that take an input and replicate its field names for the output data, integer fields are lost. FeatureId type fields are often integers so this is a pain. Doubles and strings appear to be unaffected.

* As mentioned above, v3.3 of 52North was found to exhibit bugs leading to the requirement of patched versions of two .jars [52n-wps-r-3.3.0.jar](http://geoprocessing.forum.52north.org/Reading-raster-data-inputs-with-wpsr-td4026006.html) and [52n-wps-io-geotools-3.3.0.jar](http://geoprocessing.forum.52north.org/Chaining-FeatureCollections-td4025861.html) are required. The docker installation includes these patched libraries.



## Troubleshooting common issues

* Generating output data as GML can be problematic (WPS errors of something like ``inline: Complex Result could not be generated``) if the configuration has only been partially setup correctly. Check wps_config_geotools.xml ports match the web server. This is a common problem when testing a fresh installation.

* When executing a WPS request, the output format generators must be correctly set. E.g. an error like:  ``<ows:ExceptionText>
org.n52.wps.server.ExceptionReport: Could not find an appropriate generator based on given mimetype/schema/encoding for output
</ows:ExceptionText>`` means that a particular generator is missing. This is a common problem when testing a fresh installation. Check that the GeoJSON and GML Generators against the ``resources/wps_config_geotools.xml`` sample.

* Errors with the image reading for the LaplacePhotoBlurCheck can arise with incorrectly configured JavaIO library. E.g. ``java.util.ServiceConfigurationError: javax.imageio.spi.ImageInputStreamSpi: Provider``. This can occur if there is both bytecode and a mvn generated ``*-with-dependencies.jar`` are in the web app ``wps/WEB-INF/lib/``. 

* Be careful with using the debug parameter from the cobweb-qa library. This  mode dumps images to files and will throw the following error if the directory is not writeable ``Exception in thread "main" java.lang.NullPointerException at javax.imageio.ImageIO.write(ImageIO.java:1538)``. In WPS execution the directory used is the Tomcat installation path e.g. ``/usr/share/tomcat7-wps/``

* Errors when submitting execute requests can be due to incorrect XML formatting in the document. Check the XML structure if error is: ``org.n52.wps.server.request.strategy.WCS111XMLEmbeddedBase64OutputReferenceStrategy.isApplicable(WCS111XMLEmbeddedBase64OutputReferenceStrategy.java:63)``

* Certain processing (such as blur checking of high-resolution photographs and R scripts with complex geometric inputs) may require increases in Tomcat heap size. E.g. modify ``JAVA_OPTS="-Djava.awt.headless=true`` to something like ``-Xmx1024m`` for 1024mb of heap space.

* Incorrect execute requests made to processes can cause unexpected errors. E.g. ``Could not determine input format because none of the supported formats match the given schema ("null") and encoding ("null"). (A mimetype was not specified)`` can indicate that input data is completely missing (e.g. broken reference to WFS layer). 

* Incorrectly configured R processes can cause unexpected errors. Avoid using commas within the the WPS4R input/ouput tags as these are used for parsing. To help debugging, monitoring the RServe stdout can be useful (start the R server with RServe(TRUE) from an R prompt - only seems to work for Linux).

* An R proces returning error like ``ERROR org.n52.wps.server.request.ExecuteRequest: Exception/Error while executing ExecuteRequest for org.n52.wps.server.r.pillar2.Cleaning.UsabilityFilterOut: java.lang.NullPointerException`` 
and/or like ``ERROR org.n52.wps.server.handler.RequestHandler: exception handling ExecuteRequest.`` could mean that input variables are not defined as a correct type e.g. inputObservations is defined as a String rather than a geospatial type. 

* An R proces returning error like ``Caused by: java.lang.StringIndexOutOfBoundsException: String index out of range: -1`` is usually because of issues with output variable creation or annotation.

* Incorrectly compiled Java processes can cause unexpected errors. Check GetCapbilities requests execute correctly following addition of new processes. E.g. An error of ``ERR_INCOMPLETE_CHUNKED_ENCODING`` may occur if one process is not compiled or deployed correctly. Or GetCapabilities may work occuring to the 52North log but does not return any XML in the browser. Use DescribeProcess call on suspicious processes - CountTweetsWithLocation was causing this on one deployment.

* Java errors similar ``Unsupported major.minor version 52.0`` indicate that a Java process may be compiled and run with different versions. Avoid this issue by compiling on the runtime machine and/or specifying source & target Java versions e.g. ``javac -Xlint -cp "../../../lib/*" -source 1.7 -target 1.7 GetLineOfSight.java``

* R processes that use the RGDAL library (rather than maptools) for reading observations will fail when points are in a multipoint data structure, which some java processes generate for some reason. This is because readOGR doesn't support multipoint structures (https://stat.ethz.ch/pipermail/r-sig-geo/2011-July/012416.html).

## Other non-WPS issues

* If Tomcat7 is not starting and it is not the WPS at fault, check that the JDK and JRE are configured correctly (i.e. us the JRE that ships with the JDK). This is common problem on fresh installations
