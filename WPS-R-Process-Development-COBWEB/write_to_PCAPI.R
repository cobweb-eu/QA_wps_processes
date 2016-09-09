library(sp); library(maptools);library(rgdal);
# wps.des: id = write.to.PCAPI, title = simple adaptor for WPS writing to a PCAPI REST json end point,
# abstract = Takes a string uuid and url string of rest service and the inputObservations destined for pcapi;
# Author: Julian Rosser
###############################################################################

# wps.in: url, string, title = REST URL,  abstract = This is the end-point URL for the rest service;
# wps.in: UUID, string, title = User ID of the query,  abstract = This is the uuid for the query;
# wps.in: inputObservations, shp, title = observations data,  abstract = This is the obs data for pcapi;
# wps.in: sIdValue, string, title = sid value,  abstract = This is the value for an sid ;

library(rjson)
library(maptools)
library(RCurl)

# wps.off;
#test vars
setwd("C:/Users/ezzjfr/Documents/test_pcapi_data")
url = "https://dyfi.cobwebproject.eu/pcapi/records/local"
UUID = "731bc121-8264-3982-7d06-84f550577723" #a uuid
inputObservations<<- "out_from_pcapi.shp"
sIdValue = "test_sid"
# wps.on;
  
#curl terminal
#curl -T https://dyfi.cobwebproject.eu/pcapi/records/local/731bc121-8264-3982-7d06-84f550577723/11_QA.json

#force readOGR of multi-point observations
layername <- sub(".shp","", inputObservations) # just use the file name as the layer name
shape <- readShapePoints(layername)
tempfilename = paste0(layername,"_json")
writeOGR(shape, paste0(getwd(),'/', tempfilename), 'shape', driver='GeoJSON')

#local json filename
localJsonFile = tempfilename

#remote json filename
qaFilename = "QA.json"
sId = paste0(sIdValue, "_",qaFilename)

#upload destination
pcapiCurlString = paste0(url,"/",UUID,"/",sId)

uri <- pcapiCurlString
file.name <- localJsonFile
result <- postForm(uri, file = fileUpload(filename = file.name, contentType="application/json"), .opts = list(ssl.verifypeer = FALSE))

out = result
# wps.out: out, string, returned PCAPI result;
