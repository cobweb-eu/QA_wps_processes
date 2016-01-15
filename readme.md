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


## Troubleshooting

* Certain processing (such as blur checking of high-resolution photographs and R scripts with complex geometric inputs) may require increases in Tomcat heap size. E.g. modify ``JAVA_OPTS="-Djava.awt.headless=true`` to something like ``-Xmx1024m`` for 1024mb of heap space.
 
* Incorrectly configured R processes can cause unexpected errors. Avoid using commas within the the WPS4R input/ouput tags as these are used for parsing. 

* Incorrectly compiled Java processes can cause unexpected errors. Check GetCapbilities requests execute correctly following addition of new processes. E.g. An error of ``ERR_INCOMPLETE_CHUNKED_ENCODING`` may occur if one process is not compiled or deployed correctly.

