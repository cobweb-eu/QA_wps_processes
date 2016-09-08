#################################################################
# FP7 project COBWEB 
#  QAQC   February 2016
# pillar1 LocationBasedServicePosition
#            
# Dr Didier Leibovici, Dr Julian Rosser and Pr Mike Jackson University of Nottingham
#
# as process part of the WPS
# input format and output format of the data and metadata 
# are managed within the java wrapper from 52N
# testInit() is a test setting up the inputs and outputs parameters when ran only from within R alone
#
# pillar1.LocationBasedServicePosition.xxxx
#   where xxxx is the name of the particular QC test
################################################################
# pillar1.LocationBasedServicePosition.DistanceTo
################################################################
#    given the position and its uncertainty checking if a point(or polygon) belongs to a given polygon then concluding on relative position accuracy and 'relative' semantic therefore usability and attribute accuracies
#
# The DQ produced or updated if already existing are:
# DQGVQCSQ:("DQ_UsabilityElement" "DQ_TConceptualConsistency" "DQ_TopologicalConsistency" 
# "CSQ_Ambiguity" "CSQ_Vagueness" "CSQ_Judgement" "CSQ_Reliability" "CSQ_Validity" "CSQ_Trust" 
# "CSQ_NbControls")
#################################################################
# depending on the attribute type (if used)  c(1, 4 or 5 or 6, 8, 14, 16) c(14,16,17,18) c(19:25)

########################################################################
 ##################################################################
#describtion set for WPS4R
# input  set for 52North WPS4R
# output set for 52North WPS4R

# wps.des: pillar1.LBS.DistanceTo , title = Pillar 1 LocationBasedServicePosition DistanceTo , abstract = QC checking (given position uncertainties) the closest distance to a set of geometries then given a threshold concluding on relative position accuracy and 'relative' semantic therefore usability. DQGVQCSQ:("DQ_UsabilityElement" "DQ_ConceptualConsistency" "DQ_TopologicalConsistency"    "CSQ_Ambiguity" "CSQ_Vagueness" "CSQ_Judgement" "CSQ_Reliability" "CSQ_Validity" "CSQ_Trust" "CSQ_NbControls")                  


# wps.in: inputObservations, shp, title = Observation(s) input, abstract= gml or shp of the citizen observations ; 
# wps.in: UUIDFieldName, string, title = the ID fieldname of the volunteer which will be also in ObsMeta if not NULL and VolMeta,  abstract = record identifier in the inputObservations ; 

# wps.in: inputLocationData, shp, title = location data points line or polygon, abstract= gml or shp of the thematic data to get close to  It is supposed to be one geometry or very few; 
# wps.in: ToleranceDistance,double, title= distance max to consider to be acceptable;
# wps.in: ObsMeta, string, value= NULL,title = Observation metadata, abstract= can be NULL in an xml file or as inputObservations. If given will update the metadata record(s) ; 
# wps.in: VolMeta, string, value= NULL,title = Volunteer metadata, abstract= can be NULL in an xml file or as inputObservations. If given will update the metadata record(s); 


########################

####### codelist initialisation if needed

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
 # vagueness and ambiguity are measured by lask of i.e. 0.8 is seen as not ambiguous
 # i.e. all measures but position are monotonic increasing with perceived quality
 DQlookup=cbind(DQlookup,DQ_MeasureUnit, DQ_Default)
######## function used   

pillar1.DistanceTo <-function(i, Loc.i){
	# ObsMetaQ is  quality metadata for Obsrvations (gom and attrib)
	# VolMetaQ is   vector of quality elements for the citizen
	# AuthMetaQ is   feedback quality 
	#  Auth.i contains the inex of polygons intersepting Obs.i (after all buffered accroding to their position accuracy)  
	#  
	#  would potentially need parsing UncertML within the ISO19157 for the attribute
	# updated in th parent frame
	
	vecDistTo <-function(Ob,Mod){
			 vD=NULL
			for(i in 1:dim(Mod)[1]){
				vD=c(vD,gDistance(geometry(Mod[i,]), geometry(Ob)))
			}
		return(vD)	
	}#fin de vecDist
		##############	début
		
		VolMetaQ[i,"CSQ_07"]<<-VolMetaQ[i,"CSQ_07"]+1
		
	if(is.null(Loc.i)){ #more than 2*tolerance +bufferS
		#too far
	 	#ObsMetaQ
	 	 ObsMetaQ[i,"DQ_07"]<<- 0
	 	 ObsMetaQ[i,"DQ_01"]<<- (ObsMetaQ[i,"DQ_01"])/3
	 	 ObsMetaQ[i,"DQ_10"]<<-mean(c(ObsMetaQ[i,"DQ_10"],ObsMetaQ[i,"DQ_01"]))
	 	 VolMetaQ[i,"CSQ_02"]<<-mean(c(VolMetaQ[i,"CSQ_02"], ObsMetaQ[i,"DQ_10"]))
	 }
	else{ #less than 2*tolerance (with uncertainty)
		mind=min(vecDistTo(Obs[i,],Loc[Loc.i,]))
	   if(mind <= ToleranceDistance){ # good
	   	maxmind=max(c(1-mind/ToleranceDistance,0.55))
	 	 ObsMetaQ[i,"DQ_07"]<<- mean(c( ObsMetaQ[i,"DQ_07"],1,maxmind)) #if none was set up to 0.5	
	 	 ObsMetaQ[i,"DQ_01"]<<-mean(c(maxmind,ObsMetaQ[i,"DQ_01"],ObsMetaQ[i,"DQ_07"]))	
	 	 ObsMetaQ[i,"DQ_10"]<<-mean(c(ObsMetaQ[i,"DQ_10"],ObsMetaQ[i,"DQ_07"])) 
	 	 ObsMetaQ[i,"DQ_16"]<<-mean(c(ObsMetaQ[i,"DQ_16"],max(c(mind,ObsMetaQ[i,"DQ_16"]/3))))	
	 	 
	 	 # VolMetaQ
	 	 VolMetaQ[i,"CSQ_02"]<<-mean(c(VolMetaQ[i,"CSQ_02"], ObsMetaQ[i,"DQ_07"]))
	 		VolMetaQ[i,"CSQ_05"]<<-mean(c(VolMetaQ[i,"CSQ_05"],1,1))
	 		VolMetaQ[i,"CSQ_03"]<<-mean(c(VolMetaQ[i,"CSQ_03"],VolMetaQ[i,"CSQ_05"],ObsMetaQ[i,"DQ_07"]))
			VolMetaQ[i,"CSQ_04"]<<-mean(c(VolMetaQ[i,"CSQ_04"], VolMetaQ[i,"CSQ_05"]))
	    }
	    else{ #less good 
	    	to2mind=max(c(0.1,0.55*(2-mind/ToleranceDistance)))	 # 1 to 0	
	 		ObsMetaQ[i,"DQ_07"]<<-mean(c(ObsMetaQ[i,"DQ_07"],to2mind)) ##
	 		ObsMetaQ[i,"DQ_10"]<<-mean(c(ObsMetaQ[i,"DQ_10"],ObsMetaQ[i,"DQ_07"],to2mind))
	 		ObsMetaQ[i,"DQ_01"]<<-mean(c(to2mind, ObsMetaQ[i,"DQ_01"],ObsMetaQ[i,"DQ_07"],ObsMetaQ[i,"DQ10"]))
	 	}	 		
	
 	}
	VolMetaQ[i,"CSQ_02"]<<-mean(c(VolMetaQ[i,"CSQ_02"], ObsMetaQ[i,"DQ_01"]))
	VolMetaQ[i,"CSQ_03"]<<-mean(c(VolMetaQ[i,"CSQ_03"], VolMetaQ[i,"CSQ_03"], ObsMetaQ[i,"DQ_10"]))
	 	 VolMetaQ[i,"CSQ_01"]<<-mean(c(VolMetaQ[i,"CSQ_01"], VolMetaQ[i,"CSQ_03"]))
	 	 VolMetaQ[i,"CSQ_04"]<<-sqrt(VolMetaQ[i,"CSQ_04"]*VolMetaQ[i,"CSQ_03"])
	 	 VolMetaQ[i,"CSQ_05"]<<-sqrt(ObsMetaQ[i,"DQ_07"]*VolMetaQ[i,"CSQ_05"])
	 	 VolMetaQ[i,"CSQ_06"]<<-mean(c(VolMetaQ[i,"CSQ_04"],VolMetaQ[i,"CSQ_05"],rep(VolMetaQ[i,"CSQ_06"],VolMetaQ[i,"CSQ_07"])))
	 	
				
#return(list("ObsMetaQ"=ObsMetaQ, "ModMetaQ"=ModMetaQ, "VolMetaQ"=VolMetaQ))	
}# end of pillar4.PointInPolygon 

### ObsMetaQ= GetSetMetaQ(ObsMetaQ,listQ=c(1,7,10,14,16) ,Idrecords= Obs@data[,UUIDFieldName])
##VolMetaQ= GetSetMetaQ(VolMetaQ,listQ=c( 21,22,23, 25), Idrecords =Obs@data[,UUIDFieldName],scope='volunteer')
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


bboxAsPol <-function(obj){
	# adpated from from bbox2sp in library(pedometrics)
	    bb <- bbox(obj) 
    bbx <- c(bb[1, 1], bb[1, 2], bb[1, 2], bb[1, 1], bb[1, 1])
    bby <- c(bb[2, 1], bb[2, 1], bb[2, 2], bb[2, 2], bb[2, 1])  
        bb <- SpatialPoints(data.frame(bbx, bby))
        bb <- Polygons(list(Polygon(bb)), ID = as.character(1))
        bb <- SpatialPolygons(list(bb))
        proj4string(bb) <- proj4string(obj)
    return(bb)
}#bboxasPol

########################################################################################
#################################
 
#wps.off
testInit <-function(){
	#setwd("/Users/lgzdl/Documents/Dids/DidsE/COBWEB/Co-Design/JKW knotweed (Snodonian)/DidData/")
	#inputObservations<<-"SnowdoniaNationalParkJapaneseKnotweedSurvey_AllPoints_EnglishCleaned_final.shp"
	  
	setwd("C:\\Users\\ezzjfr\\Documents\\R_scripts\\JKWData4Pillar5_proxmitySuitabilityPOlygonScore\\")
	inputObservations<<- "SnowdoniaNationalParkJapaneseKnotweedSurvey_IdAsString.shp"
  
  ToleranceDistance<<-330
	UUIDFieldName<<-"timestamp"     #string 
	inputLocationData <<-"LocationPOLY.shp"     #shp or gml or woodland.shp (selected) was not projected
	ObsMeta<<-inputObservations
	VolMeta<<-inputObservations	
}
#wps.on  Obse=readOGR(".",layer="SnowdoniaNationalParkJapaneseKnotweedSurvey_pillar5.ProximitySuitabilityPolygonScore")
#################################################################
#libraries to read gml  or shapefile or geoJSON or ....
# see possible file formats  ogrDrivers()   ...
# wps.off
if("testInitw" %in% ls())testInitw() else testInit() # to be commented when in the WPS
# wps.on
######
#names(UsaThresh)=c("DQ_04","DQ_14","DQ_16")

library(XML)
library(rgdal)
library(rgeos)

 Obsdsn= inputObservations #getdsn(inputObservations) #"." 
 Locdsn= inputLocationData #getdsn(inputAuthoritativeData)  #"."
  
inputObservations=ogrListLayers(Obsdsn)[1] # supposd only one layer
inputLocationData =ogrListLayers(Locdsn)[1] # supposd only one layer

GML=attr(ogrListLayers(Obsdsn),"driver")=="GML"

Obs <-readOGR(Obsdsn,layer= inputObservations)
Loc <-readOGR(Locdsn,layer= inputLocationData) 
         # supposed to be only one geometry corresponding to the location of the Vol
         # or very few possible locations
		 # the query has been done before or do we need to do the query in the WPS
		 # this may not be easy to do in BPMN as then the location is parametrised



# metaQ as matrices/vector
ObsMetaQ=ObsMeta
VolMetaQ=VolMeta # "string names"
#then

if(!is.null(ObsMeta) && ObsMeta == Obsdsn)ObsMetaQ=Obs@data
 # shp or gml idem otherwise will be xml from a CSW
if(!is.null(VolMeta) && VolMeta == Obsdsn)VolMetaQ=Obs@data




ObsMetaQ= GetSetMetaQ(ObsMetaQ,listQ=c(1,7,10,14,16)  ,Idrecords= Obs@data[,UUIDFieldName])
VolMetaQ= GetSetMetaQ(VolMetaQ,listQ=19: 25, Idrecords =Obs@data[,UUIDFieldName],scope='volunteer')


## Main loop for each citizen data
for (i in 1:dim(Obs@data)[1]){
	bufferS= ObsMetaQ[i,"DQ_14"]
	if(bufferS==888)bufferS=100
	# non too pessimistic 1sd accuracy ... but WARNING no accuracy retrieved!
	bufferS=bufferS+ 2*ToleranceDistance
Loc.i=gBinarySTRtreeQuery(gBuffer(geometry(Loc),width=0.1,byid=TRUE),gBuffer(geometry(Obs[i,]),width=bufferS))[[1]]	
	Res=pillar1.DistanceTo(i,Loc.i)

	#ObsMetaQ AuthMetaQ and VolMetaQ updated from within pillar4.PointInPolygon 
}#for
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

if(FALSE){ # at the moment as there is no GeoVIQUA service implemented GVQ like are put with the rest
	      # reporting the data URL inputModData
	      if(fullQualityNames)colnames(AuthMetaQ)=DQlookup[DQlookup[,1]==colnames(AuthMetaQ),2]
	      colnames(AuthMetaQ)=paste(substring(inputAuthoritativeData,1,7),colnames(AuthMetaQ),sep="_")
		Auth@data=cbind(Auth@data, AuthMetaQ)	
}
#
# as metadata xml write 
if(outputForma=="CSW"||outputForma=="SOS" ){
	# to create an ISO19157 XML to be potentially integrated in an ISO19115/19139 encoding
	#
}

#
#output as
UpdatedObs=NULL
if(nchar(inputObservations)>=33)inputObservations=paste(strtrim(inputObservations,22),sub(strtrim(inputObservations,nchar(inputObservations)-33),"", inputObservations),sep="_")
# wps.out: id=UpdatedObs, value= outP4PIP,type=shp , title = Observation and metadata for quality updated, abstract= each feature in the collection ; 
localDir=getwd()
if(is.null(UpdatedObs))UpdatedObs=paste(inputObservations,"outP1D2",sep="")

if(GML) writeOGR(Obs,localDir, layer=UpdatedObs, driver="GML" ,overwrite_layer=TRUE)
if(!GML) writeOGR(Obs,localDir, layer=UpdatedObs, driver="ESRI Shapefile" ,overwrite_layer=TRUE)



cat(paste("Saved Destination: ", localDir, "\n with \n",UpdatedObs, " .gml or .shp ",sep=""), "\n" )



# old out ObsMetaQ.output, xml, title = Observation metadata for quality updated, abstract= each feature in the collection; 
# old out AuthMetaQ.output, xml, title = Auth metadata updated if asked for, abstract= each feature in the collection; 
# old out UserMetaQ.ouput, xml, title = User metadata for quality updated, abstract= each feature in the collection; 

# outputs  by WPS4R