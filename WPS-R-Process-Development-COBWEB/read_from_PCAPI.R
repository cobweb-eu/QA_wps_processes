library(sp); library(maptools);library(rgdal);
# wps.des: id = read.From.PCAPI, title = simple adaptor for WPS reading from a PCAPI REST json end point,
# abstract = Takes a string id and url string of rest service and makes a bunch of assumptions about formats;
# Author: Julian Rosser
###############################################################################

# wps.in: url, string, title = REST URL,  abstract = This is the end-point URL for the rest service;
# wps.in: id, string, title = User ID of the query,  abstract = This is the uuid for the query;
# wps.in: jsonFileId, string, title = Survey JSON ID,  abstract = This is the survey ID of the json data;

library(curl)
library(rjson)

# wps.off;
#test vars
url = "https://dyfi.cobwebproject.eu/pcapi/records/local"
id = "2338e388-f34e-25d9-945c-54cffd9c46c2"
jsonFileId = "b1b28830-9443-46b1-82f7-3d772f30cdbb"#
# wps.on;

#assumed kvp
parameterKvpGuff = "?filter=format,editor&frmt=geojson&id="
#pcapiJson = "https://dyfi.cobwebproject.eu/pcapi/records/local/2338e388-f34e-25d9-945c-54cffd9c46c2/?filter=format,editor&frmt=geojson&id=b1b28830-9443-46b1-82f7-3d772f30cdbb.json"
pcapiJson = paste0(url,"/",id,"/",parameterKvpGuff,jsonFileId,".json")

#this will be in wps4r temp space
download.file(pcapiJson, destfile = "temp.json", method="curl")
map = readOGR("temp.json", "OGRGeoJSON")

#out processing
out="out_from_pcapi.shp"
writeOGR(map,out,"data","ESRI Shapefile")
# wps.out: out, shp_x, returned PCAPI data;

