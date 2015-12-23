# Web Processing Service for COBWEB-QA#

##Quality Assurance Web Processing Service using 52North WPS

Quality tests are implemented as either Java or R processes.

To install Java processes:

1. Building conbweb-qa jar (e.g. using gradle)

2. Integrate cobweb-qa library into pom.xml. E.g. at terminal:
``mvn install:install-file -Dfile=./cobweb-qa-0.2.0.2.jar -DgroupId=eu.cobwebproject.qa -DartifactId=cobweb-qa-lib -Dversion=0.2.0.2 -Dpackaging=jar -DgeneratePom=true``
or using Eclipse M2E
``Run -> Run Configurations -> select Maven build -> enter details above (e.g. Goals = install:install-file and add parameters as in terminal above.``
3. Deploy and register processes in WPS.

4. Run unit tests from Maven. E.g. Run As -> mvn test