#################################################################
# COBWEB QAQC February 2016 May 2016
# pillar5 Model-based Validation
# some typical QCs
#
# Dr Didier Leibovici Dr Julian Rosser and Pr Mike Jackson University of Nottingham
#
# each function is to be encapsulated as process part of the WPS
# input format and output format of the data and metadata 
# are managed within the java wrapper 


# pillar5.ModelBasedValidation.xxx 
# or  pillar5.xxx 
#   where xxxx is the name of the particular QC test


#  pillar5.ReliabilityDistribution
#     to compare an the distribution of a DQ_ quality element to its 'distribution' 
#   for the same subject over other participations
#   and its consistancy with the current CSQ_Reliability fo this volunteer
#   
##################################################################
#describtion set for WPS4R
# input  set for 52North WPS4R
#output set for 52North WPS4R

# wps.des: pillar5.ModelBasedValidation.ReliabilityDistribution, title = pillar5 Model-Based Validation ReliabilityDistribution,
# abstract = QC test comparing DQ_ value to the distribution of values for this volunteer or a given sample; 

# wps.in: inputObservations, application/x-zipped-shp, title = Observation(s) input, abstract= gml or shp of the citizen observations;  
# wps.in: UUIDFieldName, string, title = the ID fieldname,  abstract = attribute name existing in the inputObservations; 
# wps.in: DQparam, string, title = DQ element to check from the list of DQs;

# wps.in: NarrowRange, double, value=0.20, title= Narrow extent of the values, abstract= Value considered as narrow range difference between a high value and low value (e.g. interquatile distance 1sd);
# wps.in: SurveyQueryEndPoint, string, value=NULL, title = query giving back as shp or gml with all observations made by the citizen identified in UUIDFieldName, abstract= shp or gml resulting from querying the surveys. It is expected to have matching fieldnames as UUIDFieldName. this should be only the end point and we do the query in the code for each UUIDfieldName value. If "NULL" will use the sample from inputObservations and if not "NULL" but not self-check the whole sample from that data is used;
# wps.in: SelfCheck, boolean, value=0, title= To query for each volunteer on SurveyQueryEndPoint or not;

# wps.in: ObsMeta, string, value= NULL,title = Observation metadata, abstract= can be NULL in an xml file or as inputObservations. If given will update the metadata record(s) ; 
# wps.in: VolMeta, string, value= NULL,title = Volunteer metadata, abstract= can be NULL in an xml file or as inputObservations. If given will update the metadata record(s); 
# wps.in: SurveyMeta, string, value= NULL,title = Observation metadata;
################################################################

#libraries to read gml  or shapefile or geoJSON or ....
# see possible file formats  ogrDrivers()   ...
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
pillar5.ReliabilityDistribution <-function(val, vals,NarrowRange, DQm="DQ_01",augDiff=0.33){
	# all this is at feature level
	# position in the distribution of values
	# 	A distrib narrow and high / B narrow and low / C not narrow
	#   position in this distrib
	# vals are ordered by time of capture ... expecting to improve
	# chnage point analysis could be used!
	# DQm is the DQ checked
	VolMetaQ[i,"CSQ_07"]<<-VolMetaQ[i,"CSQ_07"]+1
	
	SuDis=summary(vals)
	sdvals=sd(vals) #
	Qstep=quantile(vals,probs=0.08) 
	Q3Q1=SuDis[5]-SuDis[2] #
	
	PctDQm=!(DQm %in% DQlookup[c(6,11,14:18),1] )
	pctVal=which(sort(c(val,vals))==val)/(length(vals)+1) #position in the distribution as quantile
	pctVal=pctVal[length(pctVal)]
	# minpctVal=1/(length(vals)+1) # 
	augDiff=max(c(0.8,augDiff))
 if(PctDQm){
 		if(mean(c(Q3Q1,sdvals)) <=NarrowRange){#narrow
 	      if(pctVal>=0.75){#high 
 	      	     ObsMetaQ[i,"DQ_01"]<<-min(c(1, ObsMetaQ[i,"DQ_01"]+ augDiff*(1-ObsMetaQ[i,"DQ_01"])))
 	      	     VolMetaQ[i,"CSQ_04"]<<-min(c(1, VolMetaQ[i,"CSQ_04"]+ augDiff*(1-VolMetaQ[i,"CSQ_04"]))) 
 	      	   if(pctVal>=0.8){
 	      	   ObsMetaQ[i,DQm]<<-min(c(1, ObsMetaQ[i,DQm]+ augDiff*(1-ObsMetaQ[i, DQm])))
 	      	   	VolMetaQ[i,"CSQ_05"]<<-min(c(1, VolMetaQ[i,"CSQ_05"]+ augDiff*(1-VolMetaQ[i,"CSQ_05"])))
 	      	   	VolMetaQ[i,"CSQ_06"]<<--min(c(1, VolMetaQ[i,"CSQ_06"]+ augDiff*(1-VolMetaQ[i,"CSQ_06"])))
 	      	   	}#higher
 	      } 
 	      if(pctVal<=0.25){#low
 	      	    ObsMetaQ[i,"DQ_01"]<<-(1-augDiff/2)*ObsMetaQ[i,"DQ_01"]
 	      	     VolMetaQ[i,"CSQ_04"]<<-(1-augDiff/2)*VolMetaQ[i,"CSQ_04"] 
 
 	      	if(pctVal<=0.2){
 	      	   	ObsMetaQ[i,DQm]<<-(1-augDiff/2)*ObsMetaQ[i,DQm]
 	      	   	VolMetaQ[i,"CSQ_05"]<<-(1-augDiff/2)*VolMetaQ[i,"CSQ_05"]
 	      	   	VolMetaQ[i,"CSQ_06"]<<-(1-augDiff/2)*VolMetaQ[i,"CSQ_06"]
 	      	   	}
 	      	} #low
 	      }#if
 	    else{# not narrow
 	      if(pctVal>=0.75){#high 
 	      	augDiff=max(c(0.9, augDiff+ (1-augDiff)*augDiff))
 	      	     ObsMetaQ[i,"DQ_01"]<<-min(c(1, ObsMetaQ[i,"DQ_01"]+ augDiff*(1-ObsMetaQ[i,"DQ_01"])))
 	      	     VolMetaQ[i,"CSQ_04"]<<-min(c(1, VolMetaQ[i,"CSQ_04"]+ augDiff*(1-VolMetaQ[i,"CSQ_04"]))) 
 	      	   if(pctVal>=0.8){
 	      	   	ObsMetaQ[i,DQm]<<-min(c(1, ObsMetaQ[i,DQm]+ augDiff*(1-ObsMetaQ[i, DQm])))
 	      	   	VolMetaQ[i,"CSQ_05"]<<-min(c(1, VolMetaQ[i,"CSQ_05"]+ augDiff*(1-VolMetaQ[i,"CSQ_05"])))
 	      	   	VolMetaQ[i,"CSQ_06"]<<--min(c(1, VolMetaQ[i,"CSQ_06"]+ augDiff*(1-VolMetaQ[i,"CSQ_06"])))
 	      	   	}#higher
 	      }
 	      if(pctVal<=0.25){#low
 	      	    ObsMetaQ[i,"DQ_01"]<<-(1-augDiff/2)*ObsMetaQ[i,"DQ_01"]
 	      	     VolMetaQ[i,"CSQ_04"]<<-(1-augDiff/2)*VolMetaQ[i,"CSQ_04"] 
 	      	if(pctVal<=0.2){
 	      	   	ObsMetaQ[i,DQm]<<-(1-augDiff/4)*ObsMetaQ[i,DQm]
 	      	   	VolMetaQ[i,"CSQ_05"]<<-(1-augDiff/4)*VolMetaQ[i,"CSQ_05"]
 	      	   	VolMetaQ[i,"CSQ_06"]<<-(1-augDiff/4)*VolMetaQ[i,"CSQ_06"]
 	      	   	}
 	      	} #low
 	    }#else 
 	 }
 	 	  
 if(!PctDQm){ #not a PctDQm
 		if(mean(c(Q3Q1,sdvals)) <=NarrowRange){#narrow
 	      if(pctVal>=0.75){#high is not good her
 	      	     ObsMetaQ[i,"DQ_01"]<<-(1-augDiff/3)*ObsMetaQ[i,"DQ_01"]
 	      	     VolMetaQ[i,"CSQ_04"]<<-(1-augDiff/3)*VolMetaQ[i,"CSQ_04"]
 	      	     ObsMetaQ[i,DQm]<<-ObsMetaQ[i,DQm]+ augDiff/2*ObsMetaQ[i, DQm]
 	      	   if(pctVal>=0.8){
 	      	   	ObsMetaQ[i,DQm]<<-ObsMetaQ[i,DQm]+ augDiff/2*ObsMetaQ[i, DQm]
 	      	   	VolMetaQ[i,"CSQ_05"]<<-(1-augDiff/4)*VolMetaQ[i,"CSQ_05"]
 	      	   	VolMetaQ[i,"CSQ_06"]<<-(1-augDiff/4)*VolMetaQ[i,"CSQ_06"]
 	      	   	}#higher
 	      } 
 	      if(pctVal<=0.25){#low
 	      	    ObsMetaQ[i,"DQ_01"]<<-min(c(1, ObsMetaQ[i,"DQ_01"]+ augDiff*(1-ObsMetaQ[i,"DQ_01"])))
 	      	     VolMetaQ[i,"CSQ_04"]<<-min(c(1,  VolMetaQ[i,"CSQ_04"]+ augDiff*(1- VolMetaQ[i,"CSQ_04"]))) 
 	      	     ObsMetaQ[i,DQm]<<-(1-augDiff/3)*ObsMetaQ[i,DQm]
 	      	if(pctVal<=0.2){
 	      	   	ObsMetaQ[i,DQm]<<-(1-augDiff/3)*ObsMetaQ[i,DQm]
 	      	   	VolMetaQ[i,"CSQ_05"]<<-min(c(1, VolMetaQ[i,"CSQ_05"]+ augDiff*(1-VolMetaQ[i,"CSQ_05"])))
 	      	   	VolMetaQ[i,"CSQ_06"]<<--min(c(1, VolMetaQ[i,"CSQ_06"]+ augDiff*(1-VolMetaQ[i,"CSQ_06"])))
 	      	   	 	      	   	}
 	      	} #lowerelse{# not narrow
 	      if(pctVal>=0.75){#high 
 	      	 	 ObsMetaQ[i,"DQ_01"]<<-(1-augDiff/5)*ObsMetaQ[i,"DQ_01"]
 	      	     VolMetaQ[i,"CSQ_04"]<<-(1-augDiff/5)*VolMetaQ[i,"CSQ_04"]
 	      	   if(pctVal>=0.8){
 	      	   	ObsMetaQ[i,DQm]<<-ObsMetaQ[i,DQm]+ augDiff/2*ObsMetaQ[i, DQm]
 	      	   	VolMetaQ[i,"CSQ_05"]<<-(1-augDiff/5)*VolMetaQ[i,"CSQ_05"]
 	      	   	VolMetaQ[i,"CSQ_06"]<<-(1-augDiff/5)*VolMetaQ[i,"CSQ_06"]
 	      	   	}#higher
 	      }
 	      if(pctVal<=0.25){#low
 	      	augDiff=max(c(0.9, augDiff+ (1-augDiff)*augDiff))
 	      	   ObsMetaQ[i,"DQ_01"]<<-min(c(1, ObsMetaQ[i,"DQ_01"]+ augDiff*(1-ObsMetaQ[i,"DQ_01"])))
 	      	     VolMetaQ[i,"CSQ_04"]<<-min(c(1,  VolMetaQ[i,"CSQ_04"]+ augDiff*(1- VolMetaQ[i,"CSQ_04"]))) 	
 				ObsMetaQ[i,DQm]<<-(1-augDiff/3)*ObsMetaQ[i,DQm]
 	      	if(pctVal<=0.2){
 	      	   	ObsMetaQ[i,DQm]<<-(1-augDiff/4)*ObsMetaQ[i,DQm]
 	      	   	VolMetaQ[i,"CSQ_05"]<<-min(c(1, VolMetaQ[i,"CSQ_05"]+ augDiff*(1-VolMetaQ[i,"CSQ_05"])))
 	      	   	VolMetaQ[i,"CSQ_06"]<<--min(c(1, VolMetaQ[i,"CSQ_06"]+ augDiff*(1-VolMetaQ[i,"CSQ_06"])))   	
 	      	   	}
 	      	} #lower
 	    }#else
  }#else 	  		
} # ReliabilityDistribution

### 


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

################################################################
#libraries to read gml  or shapefile or geoJSON or ....
# see possible file formats  ogrDrivers()   ...
 
# wps.off
testInit<-function(){
	#setwd("/Users/lgzdl/Documents/Dids/DidsE/COBWEB/Co-Design/JKW knotweed (Snodonian)/DidData/")	
  #inputObservations<<-"SnowdoniaNationalParkJapaneseKnotweedSurvey_pillar5_ProximitySuitabilityPolygonScore.shp"
  
	setwd("C:\\Users\\ezzjfr\\Documents\\R_scripts\\JKWData4Pillar5_proxmitySuitabilityPOlygonScore\\")
	inputObservations<<- "SnowdoniaNationalParkJapaneseKnotweedSurvey_IdAsString_out_outP2LQ2_pillar5_ProximitySuitabilityPolygonScore.shp"
	
  
  DQparam<<-"DQ_ThematicClassificationCorrectness"
  SurveyQueryEndPoint<<-"SnowdoniaNationalParkJapaneseKnotweedSurvey_pillar5_ProximitySuitabilityPolygonScore.shp"# need to find a more illustrative one ...
  SurveyQueryEndPoint<<-"NULL"# need to find a more illustrative one ...

	UUIDFieldName<<-"IdAsString"
	VolMeta <<-inputObservations
	ObsMeta<<-inputObservations
	SurveyMeta<<-SurveyQueryEndPoint
	SelfCheck<<-0
	NarrowRange<<-0.33
} # to be commented when in the WPS
#testInit()
# wps.on
#################################

DQmlook="DQ_01"
if(DQparam %in% DQlookup[,1]) DQmlook =DQlookup[which(DQlookup[,1]== DQparam),1]
if(DQparam %in% DQlookup[,2]) DQmlook =DQlookup[which(DQlookup[,2]== DQparam),1]
wdqm=which(DQlookup[,1]== DQmlook)

library(XML)
library(rgdal)
library(rgeos)





#julian readOGR of observations
layername <- sub(".shp","", inputObservations) # just use the file name as the layer name
Obsdsn = inputObservations
Surveydsn = SurveyQueryEndPoint
readMultiPointAsOGR = function(filename) {  
  library(maptools)
  shape <- readShapePoints(filename)
  tempfilename = paste0(filename,"_tempfilenametemp")
  writeOGR(shape, ".", tempfilename, driver="ESRI Shapefile")
  tempObs <-readOGR(".",layer= tempfilename) # 
  return(tempObs)
}
Obs = readMultiPointAsOGR(layername )


#Didier readOGR of data
# Obsdsn= inputObservations #getdsn(inputObservations) #"." 
# inputObservations=ogrListLayers(Obsdsn)[1] # supposed only one layer
# GML=attr(ogrListLayers(Obsdsn),"driver")=="GML"
# Obs <-readOGR(Obsdsn,layer= inputObservations)
# Surveydsn = SurveyQueryEndPoint #getdsn(inputModData)  #"."

if(is.null(SurveyQueryEndPoint) && SurveyQueryEndPoint!="NULL"){
  inputSurveyData =ogrListLayers(Surveydsn)[1] # supposed only one layer
  SurveyData <-readOGR(Authdsn,layer= inputSurveyData) # or use readShp
 }





# metaQ as matrices
# metaQ as matrices/vector
ObsMetaQ=ObsMeta
VolMetaQ=VolMeta # "string names"
SurveyMetaQ=SurveyMeta
#then 
# metaQ as matrices/vector

if(!is.null(ObsMeta) && ObsMeta == Obsdsn)ObsMetaQ=Obs@data # shp or gml idem otherwise will be xml from a CSW
if(!is.null(VolMeta) && VolMeta == Obsdsn)VolMetaQ=Obs@data
if(!is.null(SurveyMeta) && SurveyMeta == Surveydsn && SurveyQueryEndPoint!="NULL")SurveyMetaQ= SurveyData@data
#obs c(1)Auth c() vol c(21:25)
ObsMetaQ=GetSetMetaQ(ObsMetaQ,listQ=unique(c(1,wdqm)),Idrecords= Obs@data[,UUIDFieldName])

VolMetaQ=GetSetMetaQ(VolMetaQ,listQ=c(21:25), Idrecords =Obs@data[,UUIDFieldName],scope='volunteer')

if(!is.null(SurveyMetaQ) && SurveyMetaQ!="NULL")SurveyMetaQ=GetSetMetaQ(SurveyMetaQ,listQ=c(unique(c(1,wdqm)),c(21:25)), Idrecords = SurveyData@data[,UUIDFieldName],scope='volunteer')

############################
# Main loop for each citizen
vals=ObsMetaQ[, DQmlook]
	if(!is.null(SurveyMetaQ) && SurveyMetaQ!="NULL")vals= SurveyMetaQ[,DQmlook]
for (i in 1:dim(Obs@data)[1]){
	 #val, vals,NarrowRange, DQm="DQ_01",augDiff=0.33)
	 val=ObsMetaQ[i, DQmlook]
	 if(SelfCheck && !is.null(SurveyMetaQ) && SurveyMetaQ!="NULL")vals=vals[SurveyMetaQ[, UUIDFieldName]==Obs@data[i,UUIDFieldName]]
		Res=pillar5.ReliabilityDistribution(val,vals,NarrowRange,DQm=DQmlook)
	
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
#if(is.null(UpdatedObs))UpdatedObs=paste(inputObservations,"outP5RC",sep="")
#if(GML) writeOGR(Obs,localDir, layer=UpdatedObs, driver="GML" ,overwrite_layer=TRUE)
#if(!GML) writeOGR(Obs,localDir, layer=UpdatedObs, driver="ESRI Shapefile" ,overwrite_layer=TRUE)
#cat(paste("Saved Destination: ", localDir, "\n with \n",UpdatedObs, " .gml or .shp ",sep=""), "\n" )


UpdatedObs=paste0(layername, "_outP5RC.shp")
writeOGR(Obs,UpdatedObs,"data","ESRI Shapefile")

# wps.out: id=UpdatedObs, type=shp_x, title = Observation and metadata for quality updated, abstract= each feature in the collection ; 


# old out ObsMetaQ.output, xml, title = Observation metadata for quality updated, abstract= each feature in the collection; 
# old out AuthMetaQ.output, xml, title = Auth metadata updated if asked for, abstract= each feature in the collection; 
# old out VolMetaQ.ouput, xml, title = Vol metadata for quality updated, abstract= each feature in the collection; 

# outputs  by WPS4R