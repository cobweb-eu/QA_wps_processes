#################################################################
# COBWEB QAQC May 2016
# pillar2 Cleaning
# some typical QCs
#
# Didier Leibovici  Julian Rosser and Mike Jackson 
# University of Nottingham
#
# each function is to be encapsulated as process part of the WPS
# input format and output format of the data and metadata 
# are managed within the java wrapper 


# pillar2.Cleaning.xxxx 
# or pillar2.xxxx
#   where xxxx is the name of the particular QC test


#  pillar2.Cleaning.UsabilityFilterOut
#     to filter out / flag out observations not meeting enough DQ_usability value 
#     as compared to a threshold
#################################################################
#describtion set for WPS4R
#input  set for 52North WPS4R
#output set for 52North WPS4R

# wps.des: pillar2.Cleaning.UsabilityFilterOut, title = pillar2 Cleaning UsabilityFilterOut,
# abstract = QC test comparing usability quality value (DQ_Usability) already computed and decide to filter out the observation if lower than threshold. This stops the QA process for this observation if not successful. One can look for the geometric mean of a list of elements; 

# wps.in: inputObservations,application/x-zipped-shp, title = Observation(s) input, abstract= gml or shp of the citizen observations; 
# wps.in: UUIDFieldName, string, title = the ID fieldname,  abstract = attribute name existing in the inputObservations ; 

# wps.in: UsabThresh, double, title= 0-100 score, abstract= Threshold value for the quality element DQ_usability; 

# wps.in: ObsMeta, string, value= NULL, title = Observation metadata, abstract= can be NULL in an xml file or as inputObservations. If given will update the metadata record(s) ; 
# wps.in: VolMeta, string, value= NULL, title = Volunteer metadata, abstract= can be NULL in an xml file or as inputObservations. If given will update the metadata record(s); 

# wps.in: listQualElt, string, value=NULL, title = alternative to DQ_01 only, abstract = if not NULL it is a list of the DQ_ or CSQ_  e.g. c(DQ_01 : DQ_04 : CSQ_05);

# wps.in: FilterOut, boolean, value=TRUE, title = FilterOut TRUE or 1 or FALSE or 0, abstract = Immediate flag to discard the observation putting DQ_Usability at 0;



#####################ISO10157#############
DQ=c("DQ_UsabilityElement","DQ_CompletenessCommission","DQ_CompletenessOmission","DQ_ThematicClassificationCorrectness",
"DQ_NonQuantitativeAttributeCorrectness","DQ_QuantitativeAttributeAccuracy","DQ_ConceptualConsistency","DQ_DomainConsistency","DQ_FormatConsistency","DQ_TopologicalConsistency","DQ_AccuracyOfATimeMeasurement","DQ_TemporalConsistency","DQ_TemporalValidity","DQ_AbsoluteExternalPositionalAccuracy","DQ_GriddedDataPositionalAccuracy","DQ_RelativeInternalPositionalAccuracy")
####################GeoViQUA basic########
GVQ=c("GVQ_PositiveFeedback","GVQ_NegativeFeedback") #can be used also for user
################# Stakeholder Quality Model 
CSQ=c("CSQ_Ambiguity","CSQ_Vagueness","CSQ_Judgement","CSQ_Reliability","CSQ_Validity","CSQ_Trust","CSQ_NbControls")
###########################################
DQlookup=cbind(c(paste("DQ_0",1:9,sep=""),paste("DQ_",10:16,sep=""),paste("GVQ_0",1:2,sep=""),paste("CSQ_0",1:7,sep="")), c(DQ,GVQ,CSQ)) 
###########################################
colnames(DQlookup)=c("code","name")
###########################################
 DQ_Default=c(0.5,0.5,0.5,0.5,0.5,NA,0.5, 0.5, 0.5, 0.5,NA, 0.5, 0.5,888,888,888, 0, 0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5,0)
DQ_MeasureUnit=c("%","%","%","%","%","variance","%","%","%","%","CE68ie1sd","%","%","meters","meters","meters","count","count","%","%","%","%","%","%","count") 
## rather otimistic by default but with pessimistism 
 # for DQ_04 and DQ_11 measure will be variance and if NA will be the value (>0) as a Poisson
 # but position uncertainty
 DQlookup=cbind(DQlookup,DQ_MeasureUnit, DQ_Default)
################################################### function used   
pillar2.UsabilityFilterOut <-function(listQual,UThresh,FO=1){
	# all this is at feature level
	##  	 
	geomeanOV<-function(listQual){
		prod=1
		rDQ=as.numeric(summary(grepl("DQ",listQual))["TRUE"])
		rCSQ=as.numeric(summary(grepl("CSQ",listQual))["TRUE"])
		for(q in listQual){
		if(grepl("DQ",q))prod=prod*ObsMetaQ[i,q]
		if(grepl("CSQ",q))prod=prod*VolMetaQ[i,q]	
		}
		r=sum(c(rDQ,rCSQ),na.rm=TRUE)
		if(r==0) return(0)
	return(prod^1/r)	
	}#geomeanOV
	VolMetaQ[i,"CSQ_07"]<<-VolMetaQ[i,"CSQ_07"]+1
	if(is.null(listQual))diffin=UThresh - ObsMetaQ[i,"DQ_01"]
	else diffin=UThresh -geomeanOV(listQual)
	
	if(!(diffin<=0)) {	#  not all fine
		if(FO || FO==1)ObsMetaQ[i,"DQ_01"]<<-0
	}
	else{#diffin <=0
	 if(!is.null(listQual))ObsMetaQ[i,"DQ_01"]<<-max(c(ObsMetaQ[i,"DQ_01"],mean(c(UThresh,ObsMetaQ[i,"DQ_01"]))) )
	 VolMetaQ[i,"CSQ_04"]<<-max(c(VolMetaQ[i,"CSQ_04"],mean(c(UThresh,VolMetaQ[i,"CSQ_04"]))) )
	}
		
		
}# UsabilityFilterOut

### 
# #
getdsn<-function(tt){
	fin=substr(tt,nchar(tt)-3,nchar(tt))
	if(fin==".gml")return(tt)
	dd=strsplit(tt,"/")[[1]]
	if(length(dd)==1)return(".")
	else return(sub(dd[length(dd)],"",tt,fixed=TRUE))
}#end of dsn

measureSelectPath <-function(DQ_element,meas="geographic"){
 	#encoding= c("boolean" ,"character", "numeric")
 	# example path [.//gmd:measureDescription/gco:CharacterString/text()='geographic'] see expr in GetSetMetaQ
 	encoding="numeric"
 	path=""
 	 if(DQ_element=="DQ_RelativeInternalPositionalAccuracy,")path=paste0("[.//gmd:measureDescription/gco:CharacterString/text()=","\'",meas,"\'","]")
 	 if(DQ_element=="DQ_ConceptualConsistency")encoding="boolean"
 	 
 return(list("path"=path,"encoding"=encoding))
 }
 
GetSetMetaQ<-function(Meta,listQ=c(1,3), Idrecords=NULL,scope=NULL){
	# "CSW","SOS","WFS",scope=c("observation","dataset","user")
	# QQ list the fields more than columns for potential different naming
	# get if they exists corresponding fields DQ GVQ or CSQ
	# 
	#
	#listQ are %in% 1:25 nb of rows of DQlookup
	# are encode using DQlookup[,1]
	# 
	
	defaultMeta <-function(Meta){
  		# with
  		# DQ_Default=c(0.5,0.5,0.5,0.5,0.5,NA,0.5, 0.5, 0.5, 0.5,NA, 0.5, 0.5,888,888,888, 0, 
  		#0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5,0)
        # DQ_MeasureUnit=c("%","%","%","%","%","variance","%","%","%","%","CE68ie1sd","
        #      %","%","meters","meters","meters","count","count","%","%","%","%","%","%","count") 
         
 		 if("DQ_16" %in% colnames(Meta) && "DQ_14" %in% colnames(Meta)){
  			Meta[is.na(Meta[,"DQ_16"]),"DQ_16"]=Meta[is.na(Meta[,"DQ_16"]),"DQ_14"]
  		}
  		for (co in colnames(Meta)){
  		Meta[is.na(Meta[,co]),co]=as.numeric(DQlookup[DQlookup[,1]==co, "DQ_Default"])
  		}
  	return(Meta)
  	}#end of defaultMeta
  
	dim2=length(listQ)
	
	if(is.null(Idrecords)) dim1=1 else dim1=length(Idrecords)
	MetaQ=matrix(rep(NA,dim1*dim2),c(dim1,dim2))
		MetaQ=as.data.frame(MetaQ)
		colnames(MetaQ)= DQlookup[listQ,1] # 1 is DQ_01 etc 2 is DQ_UsabilityElement etc ..
		if(!is.null(Idrecords)) rownames(MetaQ)=Idrecords
	
	MetaQ=defaultMeta(MetaQ)
	if(is.null(Meta) || Meta=="NULL"|| Meta=="") return(MetaQ)
		
	if(is.object(Meta) ){ # Meta already read by readOGR simple gml or shp
		if(class(Meta)[1] %in% c("SpatialPointsDataFrame","SpatialPolygonsDataFrame","SpatialLinesDataFrame","SpatialGridDataFrame"))Meta=Meta@data
		for (j in listQ){
			if (DQlookup[j,1] %in% colnames(Meta)) MetaQ[,DQlookup[j,1]]=Meta[,DQlookup[j,1]]
			else if (DQlookup[j,2] %in% colnames(Meta)) MetaQ[,DQlookup[j,1]]=Meta[,DQlookup[j,2]]
			#else Meta@data<<-cbind(Meta@data,MetaQ[,DQlookup[j,1]]) # add columns in with NA
		}
	}
	else {
		library(XML); #library(XML2R) # XML2R needs an url
		## putting  DQ_ elements (CSQ or GVQ)	
			 Meta.all <- xmlParse(Meta, isURL=TRUE) #, isURL= isUrl(Meta))
			for (j in listQ){ 
				q=DQlookup[j,2];q1=DQlookup[j,1]
				scopeSelect=""
				if(!is.null(scope))scopeSelect=paste0("[.//gmd:MD_ScopeCode[@codeListValue=","\'", scope ,"\'","] ]") #scope='dataset' scope='feature
				measureSelect=measureSelectPath(q)
				expr=paste0("//gmd:DQ_DataQuality", scopeSelect,"//gmd:",q,measureSelect$path, "//gco:Record")
				node=getNodeSet(Meta.all,expr) # to get DQ_element "value" ....
				#"//gmd:DQ_DataQuality[.//gmd:MD_ScopeCode[@codeListValue='dataset'] ]//gmd:DQ_RelativeInternalPositionalAccuracy[.//gmd:measureDescription/gco:CharacterString/text()='geographic']//gco:Record"
				# would have been better to get a first node and look for gco:Record and gf:Id afterwards but getNodeSet  ... can be done by  XMLDoc  of a node[[i]]
# or now we supose that UUID is an attribute of <gco:Record UUID='lepreumz">
				nolen=length(node)
				if(nolen>=1){
					for (i in 1:nolen){
						iI=i
						if(scope=="feature" && !is.null(node[[i]])){
							if(!is.null(Idrecords))iI=xmlGetAttr(node[[i]],"gml:id")
						}
			    		if(measureSelect$encoding=="numeric")MetaQ[iI,q1]=as.numeric(xmlValue(node[[i]]))
			    		else if(measureSelect$encoding=="boolean")MetaQ[iI,q1]=as.factor(xmlValue(node[[i]]))
			    		else MetaQ[iI,q1]=xmlValue(node[[i]])
					}
				}
			}	
	}
	MetaQ=defaultMeta(MetaQ)
return(MetaQ)
}#end of GetSetMetaQ as a matrix

cbindUP <-function(dat, datU){
	# remove from dat the columns list DQ
	# could do with a ... there 
	for (c in colnames(datU)){
		if (c %in% colnames(dat))dat[,c]=datU[,c]
		else {
		temp=colnames(dat)
		dat=cbind(dat,datU[,c])
		colnames(dat)=c(temp,c)
		}
	}
return(dat)
}#cbindUP

#
################################################################
#libraries to read gml  or shapefile or geoJSON or ....
# see possible file formats  ogrDrivers()   ...

# wps.off
testInit<-function(){
	#setwd("/Users/lgzdl/Documents/Dids/DidsE/COBWEB/Co-Design/JKW knotweed (Snodonian)/DidData/")	
  #inputObservations<<-"SnowdoniaNationalParkJ_ey_AllPoints_EnglishCleaned_finaloutP5PSPS.shp"

  setwd("C:\\Users\\ezzjfr\\Documents\\R_scripts\\JKWData4Pillar5_proxmitySuitabilityPOlygonScore\\")
  inputObservations<<- "SnowdoniaNationalParkJapaneseKnotweedSurvey_IdAsString.shp"

  listQualElt<<-NULL
  UsabThresh <<-0.7
	#UUIDFieldName<<-"Iden"     #string
	UUIDFieldName<<-"Iden"  
	VolMeta <<-inputObservations
	ObsMeta<<-inputObservations
	FilterOut<<-TRUE
} # to be commented when in the WPS
#testInit()
# wps.on
######


FilterOut=eval(parse(text= FilterOut))
listQualElt =eval(parse(text= gsub(":",",", listQualElt)))
lQ=c(1,22,25)
if(!is.null(listQualElt)){
	lQ=(1:25)[match(DQlookup[,1], listQualElt,nomatch=0)!=0]	
	if (!(1 %in% lQ))lQ=c(1,lQ)
	if (!(22 %in% lQ))lQ=c(lQ,22)
	if (!(25 %in% lQ))lQ=c(lQ,25)
}


library(XML)
library(rgdal)
library(rgeos)




#julian readOGR of observations
layername <- sub(".shp","", inputObservations) # just use the file name as the layer name
Obsdsn = inputObservations
#Obs <- readOGR(dsn = Obsdsn, layer = layername) # Broken for multi-point reading
readMultiPointAsOGR = function(filename) {  
  library(maptools)
  shape <- readShapePoints(filename)
  tempfilename = paste0(filename,"_tempfilenametemp")
  writeOGR(shape, ".", tempfilename, driver="ESRI Shapefile")
  #ogrInfo(".",tempfilename )
  tempObs <-readOGR(".",layer= tempfilename) # 
  return(tempObs)
}
Obs = readMultiPointAsOGR(layername )


#Didier readOGR
#Obsdsn= inputObservations #getdsn(inputObservations) #"." 
#inputObservations=ogrListLayers(Obsdsn)[1] # supposed only one layer
#Obs <-readOGR(Obsdsn,layer= inputObservations)
# metaQ as matrices
# metaQ as matrices/vector


GML=attr(ogrListLayers(Obsdsn),"driver")=="GML"


ObsMetaQ=ObsMeta
VolMetaQ=VolMeta # "string names"

#then 
# metaQ as matrices/vector

if(!is.null(ObsMeta) && ObsMeta == Obsdsn)ObsMetaQ=Obs@data # shp or gml idem otherwise will be xml from a CSW
if(!is.null(VolMeta) && VolMeta == Obsdsn)VolMetaQ=Obs@data

#obs c(1)Auth c() vol c(21:25)

ObsMetaQ=GetSetMetaQ(ObsMetaQ,listQ=lQ[lQ<=16],Idrecords= Obs@data[,UUIDFieldName])

VolMetaQ=GetSetMetaQ(VolMetaQ,listQ=lQ[lQ>=19], Idrecords =Obs@data[,UUIDFieldName],scope='volunteer')

############################
# Main loop for each citizen

for (i in 1:dim(Obs@data)[1]){ 
		Res=pillar2.UsabilityFilterOut(listQualElt, UsabThresh,FO=FilterOut)	
	#
	}

#
####### metadata of data quality ouput
##	

outputForma="allinWFS" #  observations were in a WFS and we add on DQs ...!!!
		               #"CSW" or "SOS" a ISO19157 reporting is made and either 
		               #sent to a CSW or with the observations in O&M
fullQualityNames=FALSE

## all in WFS
if(outputForma=="allinWFS"){
	if(fullQualityNames){ # for the full names
		colnames(ObsMetaQ)=DQlookup[DQlookup[,1]==colnames(ObsMetaQ),2]
		colnames(VolMetaQ)=DQlookup[DQlookup[,1]==colnames(VolMetaQ),2]
		}
	Obs@data=cbindUP(cbindUP(Obs@data,ObsMetaQ), VolMetaQ)
	
}


#
# as metadata xml write 
if(outputForma=="CSW"||outputForma=="SOS" ){
	# to create an ISO19157 XML to be potentially integrated in an ISO19115/19139 encoding
	#
}

#
#output as


#UpdatedObs=NULL
#if(nchar(inputObservations)>=33)inputObservations=paste(strtrim(inputObservations,22),sub(strtrim(inputObservations,nchar(inputObservations)-33),"", inputObservations),sep="_")
#localDir=getwd()
#if(is.null(UpdatedObs))UpdatedObs=paste(inputObservations,"outP2UFO",sep="")
#if(is.null(UpdatedObs))UpdatedObs=paste(layername,"_outP2UFO",sep="")
#if(GML) writeOGR(Obs,localDir, layer=UpdatedObs, driver="GML" ,overwrite_layer=TRUE)
#if(!GML) writeOGR(Obs,localDir, layer=UpdatedObs, driver="ESRI Shapefile" ,overwrite_layer=TRUE)


UpdatedObs=paste0(layername, "_outP2UFO.shp")
writeOGR(Obs,UpdatedObs,"data","ESRI Shapefile")

#cat(paste("Saved Destination: ", localDir, "\n with \n",UpdatedObs, " .gml or .shp ",sep=""), "\n" )

# wps.out: UpdatedObs, shp_x, returned geometry;