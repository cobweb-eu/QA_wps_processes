#################################################################
# COBWEB QAQC   June 2014
# pillar4 Authoritative Data comparison
# some typical QCs
# Didier Leibovici Sam Meek and Mike Jackson University of Nottingham
#
# each function is to be encapsulated as process part of the WPS
# input format and output format of the data and metadata 
# are managed within the java wrapper 


# pillar4.AuthoritativeDataComparison.xxxx 
#   where xxxx is the name of the particular QC test

# pillar4.AuthoritativeDataComparison.AttributeDistribution  
#   comparing attribute values to Authoritative data at the given location of these attributes captured
#################################################################

 ##################################################################
#describtion set for WPS4R
# input  set for 52North WPS4R
#output set for 52North WPS4R

# wps.des: pillar4.AuthoritativeDataComparison.AttributeDistribution , title = Pillar4 AuthoritativeDataComparison AttributeDistribution,
# abstract = QC test comparing quantitative attribute input Obs to given authoritative value and distribution as metadata about quality. DQGVQCSQ: ("DQ_UsabilityElement" "DQ_QuantitativeAttributeAccuracy"); 

# wps.in: inputObservations, shp, title = Observation(s) input, abstract= gml or shp of the citizen observations ; 
# wps.in: ObsAttribFieldName, string, title = AttributeName,  abstract = attribute name existing in inputObservations ; 
# wps.in: UUIDFieldName, string, title = the ID fieldname,  abstract = attribute name existing in the inputObservations ; 

# wps.in: inputAuthoritativeData, shp, title = Authoritative data, abstract= gml or shp of the Authoritative data ; 
# wps.in: AuthAttribFieldName, string, title = Auth AttributeName,  abstract = matching attribute in inputAuthoritativeData ; 
# wps.in: AuthUUIDFieldName, string, title = the  Auth ID fieldname,  abstract = attribute name existing in the inputAuthObservations ; 
# wps.in: AuthScopeLevel, string, title= scope as dataset or feature, abstract= if quality is given at feature level for the authoritative data use " feature";


# wps.in: AuthMeta, xml, title = Authoritative metadata, abstract= if NULL will do a poisson distribution based on the values ; 
# wps.in: ObsMeta, xml,  title = Observation metadata, abstract= if given will update the metadata record(s) ; 
# wps.in: VolMeta, xml, title = Vol metadata, abstract= if given will update the metadata record(s) ; 

# wps.in: Prob, double, title = Probablity threshold, abstract = level value rejecting "to be part of the distribution" ;
# wps.in: AuthDistrib, string, value=normal, title= distribution of the Authoritative attribute, abstract="normal" or "poisson" should be using UncertML in the future


#################################################################

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
 DQlookup=cbind(DQlookup,DQ_MeasureUnit, DQ_Default)
###########################################
######## function used   
pillar4.AttributeDistribution <-function(ObsAttrib,AuthAttrib, ProbThreshold=0.10){
	# all this is at feature level
	# ObsAttrib is a quantitative value  ... citizen data captured
	# AuthAttrib is the expected value as measured by the authoritative data
	#
	# AuthMetaQ is vector  of quality metadata with  the variance (normal) of the expected distribution
	#   would potentially need parsing UncertML within the ISO19157
	#
	# test if the Obs does (not) belongs to this distrib 
	#       i.e. if p(Auth>Obs)<ProbThreshold   Obs is considered "not equal" to AuthAttrib 
	#       assign the 2*prob (being over) to ISO19157::DomainConsistency
	#       assign "no" to  ISO19157::Usability (maybe a temporary no)
	#       
	# if not below threshold	 
	#    i.e.  one cannot reject Obs= Auth  and Obs belongs to the distrib 
	#   assign the variance to the data captured ISO19157::QuantitativeAttributeAccuracy  and  Usability to "yes" 
	##  	 
	
		
	if(!(AuthDistrib=="poisson" ||AuthDistrib=="normal"))AuthDistrib<<-"poisson"
	#ObsMetaQ[Distrib]=AuthMetaQ[Distrib]
	
	  # we suppose the "DQ_QuantitativeAttributeAccuracy" is 68% prob error so equivalent to 1sd
	if(AuthDistrib =="normal") {
		AuthMetaQ[is.na(AuthMetaQ[,"DQ_06"]),"DQ_06"]<<-sqrt(abs(AuthAttrib))
		p=pnorm(abs(ObsAttrib-AuthAttrib),mean=0,sd=as.numeric(AuthMetaQ[Auth.i,"DQ_06"]),lower.tail=FALSE)
	}
	if(AuthDistrib =="poisson") {
		AuthMetaQ[is.na(AuthMetaQ[Auth.i,"DQ_06"]),"DQ_06"]<<-abs(AuthAttrib)
		if(ObsAttrib <=AuthMetaQ[Auth.i,"DQ_06"]^2)p=ppois(ObsAttrib,as.numeric(AuthMetaQ[Auth.i,"DQ_06"])^2,lower.tail=TRUE)
		else p=ppois(ObsAttrib,as.numeric(AuthMetaQ[Auth.i,"DQ_06"])^2,lower.tail=FALSE)
	}
	#obs c(1,6,8,16)Auth c(17,18) vol c(23,25)
	ObsMetaQ[i,"DQ_01"]<<-mean(c(ObsMetaQ[i,"DQ_01"],2*p))
	VolMetaQ[i,"CSQ_05"]<<-mean(c(VolMetaQ[i,"CSQ_05"], 2*p))
	
		if(ObsMetaQ[i,"DQ_01"]>=0.7)AuthMetaQ[Auth.i,"GVQ_01"]<<-AuthMetaQ[Auth.i,"GVQ_01"]+1
	    if(ObsMetaQ[i,"DQ_01"]<=0.3 && VolMetaQ[i,"CSQ_06"]>=0.7)AuthMetaQ[Auth.i,"GVQ_02"]<<-AuthMetaQ[Auth.i,"GVQ_02"]+1
	    
		if (p>ProbThreshold){
			ObsMetaQ[i,"DQ_06"]<<-mean(c(ObsMetaQ[i,"DQ_06"],AuthMetaQ[Auth.i,"DQ_06"]),na.rm=TRUE) 
			if(!is.na(AuthMetaQ[Auth.i,"DQ_16"])){ObsMetaQ[i,"DQ_16"]<<-mean(c(ObsMetaQ[i,"DQ_16"],AuthMetaQ[Auth.i,"DQ_16"]),na.rm=TRUE)
			ObsMetaQ[i,"DQ_08"]<<-mean(c(ObsMetaQ[i,"DQ_08"],2*p*ObsMetaQ[i,"DQ_16"]))}	
		}
		
	   VolMetaQ[i,"CSQ_07"]<<-VolMetaQ[i,"CSQ_07"]+1
		#	Obs c(Distrib,DQ[c(1,6,8)])  Auth c("Distrib,GVQ[c(1,2)])  Vol CSQ[5]
#return(list("ObsMetaQ"=ObsMetaQ, "AuthMetaQ"=AuthMetaQ, "VolMetaQ"=VolMetaQ))	
}#NormPoisDistribTreshold 
### attention this is for a particular fieldname
#  #

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
###############################################################################
#############################
testInit <-function(){
	setwd("/Users/lgzdl/Documents/Dids/DidsE/COBWEB/Co-Design/JKW knotweed (Snodonian)/DidData/")

	inputObservations<<-"SnowJKW.shp" #shp 156
	ObsAttribFieldName <<-"H1"     #string  Height in JKW is categorical
	UUIDFieldName<<-"Iden"
	inputAuthoritativeData <<-"SnowBuff.shp"     #shp
	AuthAttribFieldName<<-"H1" # string
	AuthUUIDFieldName <<-"Iden"
	AuthScopeLevel<<-"dataset"
	AuthMeta<<-NULL
	ObsMeta<<-inputObservations
	VolMeta<<-inputObservations
	Prob<<-0.10 # 
	AuthDistrib <<-"normal"
	
}
testinit2<-function(){
	#levels(Obs@data[,"H1"])
#[1] "< 2m"              "<50cm"             ">2m"               "1m"                "1m (waist height)"
#[6] "2m"
Obs@data[is.na(Obs@data[,"H1"]),"H1"]="2m"
Haut1=abs(rnorm(156,1,2))
Haut1[Obs@data[,"H1"]=="<2m"]=rnorm(156,1.2,0.5)[Obs@data[,"H1"]=="< 2m"]
Haut1[Obs@data[,"H1"]=="2m"]=rnorm(156,2,0.8)[Obs@data[,"H1"]=="2m"]
Haut1[Obs@data[,"H1"]==">2m"]=rnorm(156,2.3,0.8)[Obs@data[,"H1"]==">2m"]
Haut1[Obs@data[,"H1"]=="1m"]=rnorm(156,1,0.3)[Obs@data[,"H1"]=="1m"]
Haut1[Obs@data[,"H1"]=="1m (waist height)"]=rnorm(156,1.2,0.4)[Obs@data[,"H1"]=="1m (waist height)"]
Haut1[Obs@data[,"H1"]=="<50cm"]=rnorm(156,0.5,0.3)[Obs@data[,"H1"]=="<50cm"]

Obs@data[,"H1"]<<-abs(Haut1)

Haut2=abs(rnorm(156,1,2))
Haut2[Obs@data[,"H1"]=="< 2m"]=rnorm(156,1.2,0.5)[Obs@data[,"H1"]=="< 2m"]
Haut2[Obs@data[,"H1"]=="2m"]=rnorm(156,2,0.8)[Obs@data[,"H1"]=="2m"]
Haut2[Obs@data[,"H1"]==">2m"]=rnorm(156,2.3,0.8)[Obs@data[,"H1"]==">2m"]
Haut2[Obs@data[,"H1"]=="1m"]=rnorm(156,1,0.3)[Obs@data[,"H1"]=="1m"]
Haut2[Obs@data[,"H1"]=="1m (waist height)"]=rnorm(156,1.2,0.4)[Obs@data[,"H1"]=="1m (waist height)"]
Haut2[Obs@data[,"H1"]=="<50cm"]=rnorm(156,0.5,0.3)[Obs@data[,"H1"]=="<50cm"]

Auth@data[,"H1"]<<-abs(Haut2)

}
#################################################################
#libraries to read gml  or shapefile or geoJSON or ....
# see possible file formats  ogrDrivers()   ...
# wps.off
if("testInitw" %in% ls())testInitw() else testInit()# to be commented when in the WPS
# wps.on
######

library(XML)
library(rgdal)
library(rgeos)

 Obsdsn= inputObservations #getdsn(inputObservations) #"." 
 Authdsn= inputAuthoritativeData #getdsn(inputAuthoritativeData)  #"."
 
 
inputObservations=ogrListLayers(Obsdsn)[1] # supposed only one layer
inputAuthoritativeData =ogrListLayers(Authdsn)[1] # supposed only one layer

GML=attr(ogrListLayers(Obsdsn),"driver")=="GML"

Obs <-readOGR(Obsdsn,layer= inputObservations)
Auth <-readOGR(Authdsn,layer=inputAuthoritativeData) # supposed to be only one geometry corresponding to the location of the Vol
											 # the query has been done before ? or do we need to do the query in the WPS
											 # this may not be easy to do in BPMN as then the location is parametrised
#wps.off
testinit2()
#wps.on

# kind of clip Auth to buffer obs
clipDist=800
RectObs=gBuffer(bboxAsPol(Obs),width=clipDist)
LesA=gBinarySTRtreeQuery(gBuffer(Auth,width=0.1,byid=TRUE),RectObs)[[1]]
Auth = Auth[LesA,]	#eg pour Woodland on passe de 58480 - 618 useful

# metaQ as matrices
# metaQ as matrices/vector
ObsMetaQ=ObsMeta
AuthMetaQ=AuthMeta
VolMetaQ=VolMeta # "string names"
#then 
# metaQ as matrices/vector

if(!is.null(ObsMeta) && ObsMeta == Obsdsn)ObsMetaQ=Obs@data # shp or gml idem otherwise will be xml from a CSW
if(!is.null(VolMeta) && VolMeta == Obsdsn)VolMetaQ=Obs@data
if(!is.null(AuthMeta) && AuthMeta == Authdsn)AuthMetaQ=Auth@data

#obs c(1,6,8,16)Auth c(17,18) vol c(23:25)
ObsMetaQ=GetSetMetaQ(ObsMetaQ,listQ=c(1,6,8,14),Idrecords= Obs@data[,UUIDFieldName])
AuthMetaQ=GetSetMetaQ(AuthMetaQ,listQ=c(6,14,16,17,18), Idrecords = Auth@data[,AuthUUIDFieldName])
VolMetaQ=GetSetMetaQ(VolMetaQ,listQ=c(23:25), Idrecords =Obs@data[,UUIDFieldName],scope='volunteer')

############################
# Main loop for each citizen
for (i in 1:dim(Obs@data)[1]){
	# creating the matching
	Auth.i= findProximityFeatures(Obs[i,], bufferS=0.1)[1] # index in the matrix or UUIDfieldname value
	#this should be only one index

	if(!is.null(Auth.i)&& !is.na(Obs@data[i, ObsAttribFieldName]))Res=pillar4.AttributeDistribution(Obs@data[i, ObsAttribFieldName],Auth@data[Auth.i, AuthAttribFieldName],ProbThreshold=Prob)
 
 #ObsMetaQ[i,]=Res$ObsMetaQ ; AuthMetaQ[i,]=Res$AuthMetaQ ; VolMetaQ[i,]=Res$VolMetaQ
 
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
# wps.out: id=UpdatedObs, value= outP4ADT,type=shp , title = Observation and metadata for quality updated, abstract= each feature in the collection ; 
localDir=getwd()
if(is.null(UpdatedObs))UpdatedObs=paste(inputObservations,"outP4ADT",sep="")


if(GML) writeOGR(Obs,localDir, layer=UpdatedObs, driver="GML" ,overwrite_layer=TRUE)
if(!GML) writeOGR(Obs,localDir, layer=UpdatedObs, driver="ESRI Shapefile" ,overwrite_layer=TRUE)



cat(paste("Saved Destination: ", localDir, "\n with \n",UpdatedObs, " .gml or .shp ",sep=""), "\n" )


# old out ObsMetaQ.output, xml, title = Observation metadata for quality updated, abstract= each feature in the collection; 
# old out AuthMetaQ.output, xml, title = Auth metadata updated if asked for, abstract= each feature in the collection; 
# old out VolMetaQ.ouput, xml, title = Vol metadata for quality updated, abstract= each feature in the collection; 

# outputs  by WPS4R