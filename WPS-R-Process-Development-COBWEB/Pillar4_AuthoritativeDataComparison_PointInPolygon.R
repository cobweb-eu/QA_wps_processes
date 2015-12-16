#################################################################
# FP7 project COBWEB 
#  QAQC   November 2015
# pillar4 AuthoritativeDataComparison
#            
# Dr Didier Leibovici, Dr Julian Rosser and Pr Mike Jackson University of Nottingham
#
# as process part of the WPS
# input format and output format of the data and metadata 
# are managed within the java wrapper from 52N
# testInit() is a test setting up the inputs and outputs parameters when ran only from within R alone
#
# pillar4.AuthoritativeDataComparison.xxxx
#   where xxxx is the name of the particular QC test
################################################################
# pillar4.AuthoritativeDataComparison.PointInPolygon 
################################################################
#    Check knowing the position uncertainty (if given)  if a point belongs to a polygon then concluding
#       on relative position accuracy and 'relative' semantic therefore usability and attibute accuracies.
# The DQ produced or updated if already existing are:
# DQGVQCSQ:("DQ_UsabilityElement","DQ_ThematicClassificationCorrectness",
# "DQ_NonQuantitativeAttributeCorrectness","DQ_QuantitativeAttributeAccuracy","DQ_DomainConsistency",
# DQ_AbsoluteExternalPositionalAccuracy", "DQ_RelativeInternalPositionalAccuracy",
# "GVQ_PositiveFeedback","GVQ_NegativeFeedback",
# "CSQ_Ambiguity","CSQ_Judgement","CSQ_Reliability",
# "CSQ_Trust","CSQ_NbContributions")  
#################################################################
# depending on the attiribute type (if used)  c(1, 4 or 5 or 6, 8, 14, 16) c(14,16,17,18) c(19:25)
####### codelist initialisation if needed



#1=getNodeSet(xx,"//gmd:DQ_DataQuality[.//gmd:MD_ScopeCode[@codeListValue='dataset'] ]//gmd:DQ_RelativeInternalPositionalAccuracy[.//gmd:measureDescription/gco:CharacterString/text()='geographic']//gco:Record")
##################################################################
#describtion set for WPS4R
# input  set for 52North WPS4R
# output set for 52North WPS4R

# wps.des: id = Pillar4.AuthoritativeDataComparison.PointInPolygon , title = Pillar4.AuthoritativeDataComparison.PointInPolygon , abstract = QC checking (given position uncertainties) if a point belongs to a polygon then concluding on relative position accuracy and 'relative' semantic therefore usability. DQGVQCSQ:("DQ_UsabilityElement" "DQ_ThematicClassificationCorrectness" "DQ_NonQuantitativeAttributeCorrectness" "DQ_QuantitativeAttributeAccuracy" "DQ_AbsoluteExternalPositionalAccuracy" "DQ_RelativeInternalPositionalAccuracy" "GVQ_PositiveFeedback" "GVQ_NegativeFeedback" "CSQ_Judgement" "CSQ_Reliability" "CSQ_Validity" "CSQ_Trust" "CSQ_NbContributions");


# wps.in: inputObservations, shp_x, title = Observation(s) input, abstract= gml or shp of the citizen observations ; 
# wps.in: UUIDFieldName, string, title = the ID fieldname of the volunteer which will be also in ObsMeta if not NULL and VolMeta,  abstract = record identifier in the inputObservations ; 

# wps.in: inputAuthoritativeData, shp_x, title = Authoritative data polygons, abstract= gml or shp of the polygon thematic data ; 
# wps.in: AuthUUIDFieldName, string, title = the  Authoritative ID fieldname,  abstract = record identifier ; 
# wps.in: AuthFieldName, string, value=NULL title = the  Authoritative fieldname categorising the polygons,  abstract = attribute for selection of polygons to be in. If NULL all the polygons are considered ;
# wps.in: AuthFieldNameValue, string, value=woodland, title = the fieldname selection,  abstract = value of the AuthFieldname to select as polygons to be in ;  
# wps.in: ThematicAgreement, boolean, value= 0, title = Agreement or Disagreement,  abstract = Agreement or Disagreement of thematic layer and citizen observations i.e. if being in the polygon is increasing the accuracy /quality  (agreement) or not  ;
# wps.in: ScopeLevel, string, value= feature, title= scope as dataset or feature, abstract= if quality is given at feature level for the authoritative data use " feature";

# wps.in: AuthMeta, string, value= NULL, title = modelled habitat metadata, abstract= modelled habitat metadata which can be  NULL, xml file or same as inputModData; 
# wps.in: ObsMeta, string, value= NULL,title = Observation metadata, abstract= can be NULL in an xml file or as inputObservations. If given will update the metadata record(s) ; 
# wps.in: VolMeta, string, value= NULL,title = Volunteer metadata, abstract= can be NULL in an xml file or as inputObservations. If given will update the metadata record(s); 


# wps.in: ObsAttrType, string, value= c("classification"_"quantitative"), title = type of the attibutes in the record , abstract = list of types present in the records mathing the three postential different types of quality for attribute c("classification"_"non-quantitative"_"quantitative");
#########################








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

pillar4.PointInPolygon <-function(Obs.i, Auth.i, ThemaAg){
	# ObsMetaQ is  quality metadata for Obsrvations (gom and attrib)
	# VolMetaQ is   vector of quality elements for the citizen
	# AuthMetaQ is   feedback quality 
	#  Auth.i contains the inex of polygons intersepting Obs.i (after all buffered accroding to their position accuracy)  
	#  
	#  would potentially need parsing UncertML within the ISO19157 for the attribute
	# updated in th parent frame
	
	vecDistTo <-function(Obs.i,Mod){
			 vD=NULL
			for(i in 1:dim(Mod)[1]){
				vD=c(vD,gDistance(geometry(Obs.i),geometry(Mod[i,])))
			}
		return(vD)	
	}#fin de vecDist
	neaRestAuth<-function(Obs.i,Mod){
			d=300
			if(ObsMetaQ[i,"DQ_14"]!=888)d=3*ObsMetaQ[i,"DQ_14"]
			leNearest=NULL
			while (is.null(leNearest)){
				leNearest=gBinarySTRtreeQuery(geometry(Auth),gBuffer(geometry(Obs.i), width=d))[[1]]
			d=d+300	
			}
		if(length(leNearest)>1){
			vD=vecDistTo(Obs.i,Mod[leNearest,])
			leNearest=leNearest[vD==min(vD)]
			}	
		return(leNearest[1])		
	}#fin de nearest
		##############	début
		VolMetaQ[i,"CSQ_07"]<<-VolMetaQ[i,"CSQ_07"]+1
	if(is.null(Auth.i)){ #not in at all as no intersection
	 	if(ThemaAg){ # not good
	 	#ObsMetaQ
	 		Near=NULL
	 		if(ObsMetaQ[i,"DQ_14"]!=888){
	 			buffNear=3*ObsMetaQ[i,"DQ_14"]+ AuthDQ_14
	 			ObsBuff=gBuffer(geometry(Obs[i,]),width=ObsMetaQ[i,"DQ_14"])
	 			Near=gBinarySTRtreeQuery(gBuffer(geometry(Auth),byid=TRUE,width=buffNear),
	 			         ObsBuff)[[1]]
	 		}
	 		if(is.null(Near))ObsMetaQ[i,"DQ_08"]<<- ObsMetaQ[i,"DQ_08"]/2 #if none was set up to 0.5 mean with 0
	 		else ObsMetaQ[i,"DQ_08"]<<- mean(c(ObsMetaQ[i,"DQ_08"],1-median(vectDisTo(ObsBuff,Auth[Near,]))/(1+buffNear)) ) #if none was set up to 0.5	
	 	ObsMetaQ[i,"DQ_01"]<<-mean(c(ObsMetaQ[i,"DQ_01"],ObsMetaQ[i,"DQ_08"]))
	 	
	 	if("classification" %in% ObsAttrType)ObsMetaQ[i,"DQ_04"]<<-mean(c(ObsMetaQ[i,"DQ_08"],ObsMetaQ[i,"DQ_04"]))
	 	if("non-quantitative" %in% ObsAttrType)ObsMetaQ[i,"DQ_05"]<<-mean(c(ObsMetaQ[i,"DQ_08"],ObsMetaQ[i,"DQ_05"]))
	 	#if("quantitative" %in% ObsAttrType) cannot say anything I think 	
	 	}
	 	else{ #good
	 	#ObsMetaQ
	 	 ObsMetaQ[i,"DQ_08"]<<- (ObsMetaQ[i,"DQ_08"]+1)/2
	 	 ObsMetaQ[i,"DQ_01"]<<- (ObsMetaQ[i,"DQ_01"]+1)/2
	 	 	if(any(AuthMetaQ[,"DQ_16"]!=888)) {    #suppose in fact if exists it exists for all
	  		ObsMetaQ[i,"DQ_16"]=mean(c(ObsMetaQ[i,"DQ_16"],AuthMetaQ[neaRestAuth(Obs[i,],Auth),"DQ_16"]),na.rm=TRUE)
	 		}			
	    
	   }
	}
	else{ #in or partially in
		propIn=1
		if(ObsMetaQ[i,"DQ_14"]!=888)propIn=1-gArea(gDifference(Buffer(geometry(Obs[i,]),width=ObsMetaQ[i,"DQ_14"]),geometry(Auth[Auth.i,])))/gArea(gBuffer(geometry(Obs[i,]),width=ObsMetaQ[i,"DQ_14"]))
	 	if(ThemaAg){ # not good
	 		#ObsMetaQ
	 		ObsMetaQ[i,"DQ_08"]<<-mean(c(ObsMetaQ[i,"DQ_08"],1-propIn))
	 		ObsMetaQ[i,"DQ_01"]<<-mean(c(ObsMetaQ[i,"DQ_01"],ObsMetaQ[i,"DQ_08"]))
	 	if("classification" %in% ObsAttrType)ObsMetaQ[i,"DQ_04"]<<-mean(c(ObsMetaQ[i,"DQ_08"],ObsMetaQ[i,"DQ_04"]))
	 	if("non-quantitative" %in% ObsAttrType)ObsMetaQ[i,"DQ_05"]<<-mean(c(ObsMetaQ[i,"DQ_08"],ObsMetaQ[i,"DQ_05"]))
	 		 	}
	 	else{ #good
	 		#ObsMetaQ
	 		ObsMetaQ[i,"DQ_08"]<<-mean(c(ObsMetaQ[i,"DQ_08"],propIn))
	 		ObsMetaQ[i,"DQ_01"]<<-mean(c(ObsMetaQ[i,"DQ_01"],ObsMetaQ[i,"DQ_08"]))
	 	 if("classification" %in% ObsAttrType)ObsMetaQ[i,"DQ_04"]<<-mean(c(ObsMetaQ[i,"DQ_08"],ObsMetaQ[i,"DQ_04"]))
	 	 if("non-quantitative" %in% ObsAttrType)ObsMetaQ[i,"DQ_05"]<<-mean(c(ObsMetaQ[i,"DQ_08"],ObsMetaQ[i,"DQ_05"]))
	 	 if("quantitative" %in% ObsAttrType && !is.na(ObsMetaQ[i,"DQ_06"]))ObsMetaQ[i,"DQ_06"]<<-mean(c(AuthMetaQ[Auth.i,"DQ_06"],ObsMetaQ[i,"DQ_06"]),na.rm=TRUE)
	 	
	 	}
	 		#AuthMetaQ
	 	if(ObsMetaQ[i,"DQ_01"]>=0.80) AuthMetaQ[Auth.i,"GVQ_01"]=AuthMetaQ[Auth.i,"GVQ_01"]+1 # nb tot of feedback is the sum
		if(ObsMetaQ[i,"DQ_01"]<=0.20) AuthMetaQ[Auth.i,"GVQ_02"]=AuthMetaQ[Auth.i,"GVQ_02"]+1
		
	} #in
	
	# VolMetaQ
	 		VolMetaQ[i,"CSQ_01"]<<-mean(c(VolMetaQ[i,"CSQ_01"],ObsMetaQ[i,"DQ_08"]))
	 		VolMetaQ[i,"CSQ_03"]<<-mean(c(VolMetaQ[i,"CSQ_03"],VolMetaQ[i,"CSQ_01"],ObsMetaQ[i,"DQ_08"]))
			VolMetaQ[i,"CSQ_04"]<<-VolMetaQ[i,"CSQ_04"]*VolMetaQ[i,"CSQ_03"]
				
#return(list("ObsMetaQ"=ObsMetaQ, "ModMetaQ"=ModMetaQ, "VolMetaQ"=VolMetaQ))	
}# end of pillar4.PointInPolygon

### 
##
findMatchFeature<-function(Obs.i,bufferSo=100){
 # polygon including the point
 # or
 # closest point or line
 # here distances or need a spatial! request!
 #
 # WARNING made ofr Auth as parameter
    outlist=gBinarySTRtreeQuery(geometry(Auth),gBuffer(geometry(Obs.i), width=bufferSo))[[1]]
   #f
  for (a in outlist){
   if(!is.null(gIntersection(geometry(Obs.i), geometry(Auth)[a,])) )return(a)
  }
return(NULL)	
} 
# #
findProximityFeatures<-function(Obs.i,bufferS){
 # polygon close by obsi
 # or
 # closest point or line
 # here distances or need a spatial! request!
     outlist=c(NULL)
     # select from index and then from proximity
     outlist=gBinarySTRtreeQuery(geometry(Auth),gBuffer(geometry(Obs.i), width=bufferS))[[1]]
   #for (a in 1:dim(Modi@data)[1]){# too slow
   #if(gDistance(geometry(Obs.i), geometry(Mod)[a,]) <= bufferS ) outlist=c(outlist,a)	
   #}
return(outlist)	
} 
# #
getdsn<-function(tt){
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
		
	if(is.null(Meta) || Meta=="NULL"|| Meta=="") return(defaultMeta(MetaQ))
		
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
			 Meta.all <- xmlParse(Meta, isURL= isUrl(Meta))
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



#wps.off
testInit <-function(){
	#setwd("/Users/lgzdl/Documents/Dids/DidsE/COBWEB/Co-Design/JKW knotweed (Snodonian)/DidData/")
	setwd("C:\\Users\\ezzjfr\\Documents\\R_scripts\\JKWData4Pillar5_proxmitySuitabilityPOlygonScore\\")
  
	inputObservations<<- "SnowdoniaNationalParkJapaneseKnotweedSurvey_pillar5_ProximitySuitabilityPolygonScore.shp"#"SnowJKW.shp" #shp Snow is smaller
	UUIDFieldName<<-"Iden"     #string 
	ObsAttrType <<-c("classification","non-quantitative")
	inputAuthoritativeData<<-"Woodland.shp"     #shp or gml or woodland.shp (selected) was not projected
	AuthUUIDFieldName<<-"OBJECTID"
	AuthFieldName<<-"CATEGORY"
	AuthFieldNameValue<<-"Woodland"
	ThematicAgreement<<-0 # i.e. should not  be able to grow in forest
	ScopeLevel<<-"feature"
	AuthMeta<<-NULL
	ObsMeta<<-inputObservations
	VolMeta<<-NULL	
}
#wps.on  Obse=readOGR(".",layer="SnowdoniaNationalParkJapaneseKnotweedSurvey_pillar5.ProximitySuitabilityPolygonScore")
#################################################################
#libraries to read gml  or shapefile or geoJSON or ....
# see possible file formats  ogrDrivers()   ...
# wps.off
testInit() # to be commented when in the WPS
# wps.on
######
#names(UsaThresh)=c("DQ_04","DQ_14","DQ_16")

library(XML)
library(rgdal)
library(rgeos)

 Obsdsn=getdsn(inputObservations) #"." 
 Authdsn=getdsn(inputAuthoritativeData)  #"."
  inputObservations=sub(Obsdsn,"",sub(".gml","",sub(".shp","", inputObservations,fixed=TRUE),fixed=TRUE),fixed=TRUE)#no .shp can be gml etc..
  inputAuthoritativeData =sub(Authdsn,"",sub(".gml","",sub(".shp","", inputAuthoritativeData,fixed=TRUE),fixed=TRUE),fixed=TRUE)

Obs <-readOGR(Obsdsn,layer= inputObservations)
Auth <-readOGR(Authdsn,layer=inputAuthoritativeData) 
         # supposed to be only one geometry corresponding to the location of the Vol
		 # the query has been done before ? or do we need to do the query in the WPS
		 # this may not be easy to do in BPMN as then the location is parametrised

# kind of clip Auth to buffer obs
clipDist=1600
RectObs=gBuffer(bboxAsPol(Obs),width=clipDist)
LesAuth=gBinarySTRtreeQuery(geometry(Auth),RectObs)[[1]]
Auth=Auth[LesAuth,]	#eg pour Woodland on passe de 58480 à 618 useful

#Auth<-gIntersection(RectObs, Auth)) # trop long
											 

 #if(!is.null(ObsAttribFieldName))ObsAttrib=Obs@data[,c(UUIDFieldName ,ObsAttribFieldName)]
 #else ObsAttrib=Obs@data[,c(UUIDFieldName)] # ID attribute with UUID 
 #if(!is.null(AuthAttribFieldName))AuthAttrib=Auth@data[,c(AuthUUIDFieldName ,AuthAttribFieldName)]
 #else AuthAttrib=Auth@data[,c(AuthUUIDFieldName)]
 
# already selected or not yet selected
if(!is.null(AuthFieldName) && AuthFieldName!="NULL") Auth=Auth[ Auth@data[, AuthFieldName]== AuthFieldNameValue,]


# metaQ as matrices/vector
ObsMetaQ=ObsMeta
AuthMetaQ=AuthMeta
VolMetaQ=VolMeta # "string names"
#then

if(!is.null(ObsMeta) && ObsMeta == inputObservations)ObsMetaQ=Obs@data
 # shp or gml idem otherwise will be xml from a CSW
if(!is.null(VolMeta) && VolMeta == inputObservations)VolMetaQ=Obs@data
if(!is.null(AuthMeta) && AuthMeta == inputAuthoritativeData)AuthMetaQ=Auth@data

## depending on the attribute type (if used)  c(1, 4 or 5 or 6, 8, 14, 16) c(14,16,17,18) c(19:25)
 obslist=1;Authlist=NULL
 if( "classification" %in% ObsAttrType)obslist=c(obslist,4)
 if( "non-quantitative" %in% ObsAttrType)obslist=c(obslist,5)
 if( "quantitative" %in% ObsAttrType){obslist=c(obslist,6);Authlist=6}
obslist=c(obslist,8,14,16)

ObsMetaQ= GetSetMetaQ(ObsMetaQ,listQ=obslist ,Idrecords= Obs@data[,UUIDFieldName])
AuthMetaQ= GetSetMetaQ(AuthMetaQ,listQ=c(Authlist,14, 16, 17,18), Idrecords = Auth@data[,AuthUUIDFieldName])
VolMetaQ= GetSetMetaQ(VolMetaQ,listQ=c(19, 21,22,24, 25), Idrecords =Obs@data[,UUIDFieldName],scope='volunteer')


## Main loop for each citizen data
for (i in 1:dim(Obs@data)[1]){
	bufferS= 0.01
	AuthDQ_14=0
	if(any(AuthMetaQ[,"DQ_14"]!=888)) AuthDQ_14=mean(c(AuthMetaQ[AuthMetaQ[,"DQ_14"]!=888,"DQ_14"]),na.rm=TRUE)
 	if(AuthDQ_14!=0) Auth.i=gBinarySTRtreeQuery(gBuffer(geometry(Auth),byid=TRUE,width=AuthDQ_14),gBuffer(geometry(Obs[i,]),width=bufferS))[[1]]
	if(AuthDQ_14==0)Auth.i=gBinarySTRtreeQuery(geometry(Auth),gBuffer(geometry(Obs[i,]),width=bufferS))[[1]]
 	
	Res=pillar4.PointInPolygon(i,Auth.i,ThematicAgreement)

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
# wps.out: UpdatedObs, shp_x, returned geometry;


localDir=getwd()
if(is.null(UpdatedObs))UpdatedObs=paste(inputObservations,"outP4PIP",sep="")
writeOGR(Obs,localDir, UpdatedObs, driver="ESRI Shapefile" ,overwrite_layer=TRUE)
UpdatedObs=paste(UpdatedObs,".shp",sep="")
cat(paste("Saved Destination: ", localDir, "/",UpdatedObs,sep=""), "\n" )



# old out ObsMetaQ.output, xml, title = Observation metadata for quality updated, abstract= each feature in the collection; 
# old out AuthMetaQ.output, xml, title = Auth metadata updated if asked for, abstract= each feature in the collection; 
# old out UserMetaQ.ouput, xml, title = User metadata for quality updated, abstract= each feature in the collection; 

# outputs  by WPS4R