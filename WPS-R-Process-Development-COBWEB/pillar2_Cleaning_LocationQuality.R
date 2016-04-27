#################################################################
# FP7 project COBWEB 
#  QAQC   February 2015
# pillar2 Cleaning
#            
# Dr Didier Leibovici, Dr Julian Rosser and Pr Mike Jackson University of Nottingham
#
# as process part of the WPS
# input format and output format of the data and metadata 
# are managed within the java wrapper from 52N
# testInit() is a test setting up the inputs and outputs parameters when ran only from within R alone
#
# pillar2.Cleaning.xxxx
#   where xxxx is the name of the particular QC test
################################################################
# pillar2.Cleaning.LocationQuality 
################################################################
#    Check knowing the position uncertainty (if given)  and previous methods (in pillar 1 LoS ContainsPoly or DistanceTo) in relation to location to the full usability of not of the observation. Filtering out and feedback to the user are the most important outcomes and raising the usability when passes through.

#################################################################
 ##################################################################
#describtion set for WPS4R
# input  set for 52North WPS4R
# output set for 52North WPS4R

# wps.des: pillar2.Cleaning.LocationQuality , title = Pillar 2 Cleaning LocationQuality , abstract = QC Check knowing the position uncertainty (if given)  and previous methods (in pillar 1 LoS ContainsPoly or DistanceTo) in relation to location to the full usability of not of the observation. Filtering out and feedback to the user are the most important outcomes and raising the usability when passes through. DQGVQCSQ:(DQ_UsabilityElement DQ_ThematicClassificationCorrectness DQ_NonQuantitativeAttributeCorrectness DQ_QuantitativeAttributeAccuracy   GVQ_PositiveFeedback GVQ_NegativeFeedback CSQ_Judgement CSQ_Reliability CSQ_Validity CSQ_NbContributions);l

# wps.in: inputObservations, shp_x, title = Observation(s) input, abstract= gml or shp of the citizen observations; 

# wps.in: UUIDFieldName, string, title = the ID fieldname of the volunteer which will be also in ObsMeta if not NULL and VolMeta,  abstract = record identifier in the inputObservations ; 

# wps.in: ScopeLevel, string, title = scope level,  abstract = Scope level for processing ; 

# wps.in: LBSmethod, string, value= feature, title= LBS method(s) used in pillar1, abstract= depending on the position unertainty and the method(s) to refer to from pillar1 the QC test will increase or decrease mostly the DQ_usability if rules using thresholds are met or not. The string is at most c(WithinPoly DistanceTo ContainsPoly LoS) and the order is important as quality is modified in that order;
# wps.in: ObsMeta, string, value= NULL,title = Observation metadata, abstract= can be NULL in an xml file or as inputObservations. If given will update the metadata record(s) ; 
# wps.in: VolMeta, string, value= NULL,title = Volunteer metadata, abstract= can be NULL in an xml file or as inputObservations. If given will update the metadata record(s); 


# wps.in: DQlevel, double, value= 0.7, title = base threshold used to compare with usability and DQ_ConceptualConsistencey or DQ_TopologicalConsistency ;
# wps.in: PositionUncertainty, double, value= 500, title= Position Accuracy in meters as to compare with DQ_AbsoluteExternalPositionalAccuracy and involved in the rules;

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
## rather otimistic by default but with pessimistism (?)
 # for DQ_04 and DQ_11 measure will be variance and if NA will be the value (>0) as a Poisson
 # but position uncertainty
 # vagueness and ambiguity are measured by lask of i.e. 0.8 is seen as not ambiguous
 # i.e. all measures but position are monotonic increasing with perceived quality
 DQlookup=cbind(DQlookup,DQ_MeasureUnit, DQ_Default)
######## function used   
pillar2.LocationQualityCSQ<-function(i,val){
	#val is the initial DQ01
	dr=(val-ObsMetaQ[i,"DQ_01"])
	if(dr>0){
			VolMetaQ[i,"CSQ_02"]<<-min(c(1,VolMetaQ[i,"CSQ_02"]+dr))
			VolMetaQ[i,"CSQ_03"]<<-min(c(1,VolMetaQ[i,"CSQ_03"]+dr))
			VolMetaQ[i,"CSQ_04"]<<-min(c(1,mean(c(VolMetaQ[i,"CSQ_04"]+dr,max(c(VolMetaQ[i,"CSQ_03"],VolMetaQ[i,"CSQ_04"])) ) )))
			if(val>DQlevel)VolMetaQ[i,"CSQ_05"]<<- VolMetaQ[i,"CSQ_05"]*(1+0.1*(1-VolMetaQ[i,"CSQ_05"]))
	} 
	if(dr<0){
		VolMetaQ[i,"CSQ_02"]<<-max(c(0,VolMetaQ[i,"CSQ_02"]+dr))
			VolMetaQ[i,"CSQ_03"]<<-max(c(0,VolMetaQ[i,"CSQ_03"]+dr))
			VolMetaQ[i,"CSQ_04"]<<-max(c(0,mean(c(VolMetaQ[i,"CSQ_04"]+dr,max(c(VolMetaQ[i,"CSQ_03"],VolMetaQ[i,"CSQ_04"])) ) )))
			VolMetaQ[i,"CSQ_05"]<<- DQlevel*VolMetaQ[i,"CSQ_05"]
	}
}# fini

pillar2.LocationQuality <-function(i,LBM,DQ=DQlevel,PosUnt=PositionUncertainty){
	# ObsMetaQ is  quality metadata for Obsrvations (geom and attrib)
	# VolMetaQ is   vector of quality elements for the citizen
	#  
	#  would potentially need parsing UncertML within the ISO19157 for the attribute
	# updated in th parent frame
#[20,] "CSQ_02" "CSQ_Vagueness"                          "%"            "0.5"     
#[21,] "CSQ_03" "CSQ_Judgement"                          "%"            "0.5"     
#[22,] "CSQ_04" "CSQ_Reliability"                        "%"            "0.5"     
#[23,] "CSQ_05" "CSQ_Validity"   	
		##############	début c("WithinPoly"_"DistanceTo"_"ContainsPoly"_"LoS") 
		VolMetaQ[i,"CSQ_07"]<<-VolMetaQ[i,"CSQ_07"]+1
		
		if(ObsMetaQ[i,"DQ_01"]>0.90)return(min(c(1,max(c(ObsMetaQ[i,"DQ_01"]+0.10*ObsMetaQ[i,"DQ_07"],ObsMetaQ[i,"DQ_01"]+0.10*ObsMetaQ[i,"DQ_10"])))))      
	
	
	if(LBM=="WithinPoly"){#DQ07 DQ01 DQ10
		aug=min(c(1,ObsMetaQ[i,"DQ_01"]+0.10*sqrt(ObsMetaQ[i,"DQ_07"]*ObsMetaQ[i,"DQ_10"])))
		if(ObsMetaQ[i,"DQ_01"]>0.9*DQ & ObsMetaQ[i,"DQ_14"]<0.6*PosUnt)return(aug) #0.63 and 300m
		if(ObsMetaQ[i,"DQ_01"]>0.7*DQ & ObsMetaQ[i,"DQ_07"]>0.85*DQ & ObsMetaQ[i,"DQ_14"]<PosUnt)return(aug)
		if(ObsMetaQ[i,"DQ_01"]>0.7*DQ & ObsMetaQ[i,"DQ_10"]>0.85*DQ & ObsMetaQ[i,"DQ_14"]<PosUnt)return(aug)
		if(ObsMetaQ[i,"DQ_01"]>0.9*DQ & ObsMetaQ[i,"DQ_07"]>0.85*DQ & ObsMetaQ[i,"DQ_10"]>0.85*DQ)return(aug)
		}
	if(LBM=="DistanceTo"){#DQ07 DQ01 DQ10
		aug=min(c(1,ObsMetaQ[i,"DQ_01"]+0.20*sqrt(ObsMetaQ[i,"DQ_07"]*ObsMetaQ[i,"DQ_10"])))
		if(ObsMetaQ[i,"DQ_01"]>0.85*DQ & ObsMetaQ[i,"DQ_14"]<0.9*PosUnt)return(aug) #0.6 and 450m
		if(ObsMetaQ[i,"DQ_01"]>0.65*DQ & ObsMetaQ[i,"DQ_07"]>0.9*DQ & ObsMetaQ[i,DQ_14]<PosUnt)return(aug)
		if(ObsMetaQ[i,"DQ_01"]>0.65*DQ & ObsMetaQ[i,"DQ_10"]>0.9*DQ & ObsMetaQ[i,DQ_14]<PosUnt)return(aug)
		if(ObsMetaQ[i,"DQ_01"]>0.85*DQ & ObsMetaQ[i,"DQ_07"]>0.9*DQ & ObsMetaQ[i,"DQ_10"]>0.9*DQ)return(aug)
		}
	if(LBM=="ContainsPoly"){#DQ07 DQ01 DQ10
		aug=min(c(1,ObsMetaQ[i,"DQ_01"]+0.25*sqrt(ObsMetaQ[i,"DQ_07"]*ObsMetaQ[i,"DQ_10"])))
		if(ObsMetaQ[i,"DQ_01"]>0.80*DQ & ObsMetaQ[i,"DQ_14"]<0.9*PosUnt)return(aug) #0.56 and 450m
		if(ObsMetaQ[i,"DQ_01"]>0.6*DQ & ObsMetaQ[i,"DQ_07"]>0.9*DQ & ObsMetaQ[i,"DQ_14"]<PosUnt)return(aug)
		if(ObsMetaQ[i,"DQ_01"]>0.6*DQ & ObsMetaQ[i,"DQ_10"]>0.9*DQ & ObsMetaQ[i,"DQ_14"]<PosUnt)return(aug)
		if(ObsMetaQ[i,"DQ_01"]>0.8*DQ & ObsMetaQ[i,"DQ_07"]>0.9*DQ & ObsMetaQ[i,"DQ_10"]>0.9*DQ)return(aug)

		}
	if(LBM=="LoS"){#DQ01 DQ10
		aug=min(c(1,ObsMetaQ[i,"DQ_01"]+0.20*ObsMetaQ[i,"DQ_10"]))
		if(ObsMetaQ[i,"DQ_01"]>0.85*DQ & ObsMetaQ[i,"DQ_14"]<0.9*PosUnt)return(aug) #0.6 and 450m
		if(ObsMetaQ[i,"DQ_01"]>0.75*DQ & ObsMetaQ[i,"DQ_10"]>0.9*DQ & ObsMetaQ[i,"DQ_14"]<PosUnt)return(aug)
		}
	dim=max(c(0,ObsMetaQ[i,"DQ_01"]-0.10* min(ObsMetaQ[i,"DQ_07"],ObsMetaQ[i,"DQ_10"],ObsMetaQ[i,"DQ_01"])))
    return(dim)
#return(list("ObsMetaQ"=ObsMetaQ, "ModMetaQ"=ModMetaQ, "VolMetaQ"=VolMetaQ))	
}# end of pillar4.PointInPolygon

#
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

 #########################################################################################

testInit <-function(){
	#setwd("/Users/lgzdl/Documents/Dids/DidsE/COBWEB/Co-Design/JKW knotweed (Snodonian)/DidData/")
	#inputObservations<<- "SnowdoniaNationalParkJapaneseKnotweedSurvey_pillar5_ProximitySuitabilityPolygonScore.shp"#"SnowJKW.shp" #shp Snow is smaller
  
  setwd("C:\\Users\\ezzjfr\\Documents\\R_scripts\\JKWData4Pillar5_proxmitySuitabilityPOlygonScore\\")
  inputObservations<<- "SnowdoniaNationalParkJapaneseKnotweedSurvey.shp"
  
  setwd("C:\\Program Files\\Apache Software Foundation\\Tomcat 7.0\\temp\\wps4r-workspace-2016427-131918_3fbcec31")
  
	UUIDFieldName<<-"Iden"     #string 
	ScopeLevel<<-"feature"
	LBSmethod<<-c("WithinPoly","LoS")
    DQlevel<<-0.7
    PositionUncertainty<<-500
	ObsMeta<<-inputObservations
	VolMeta<<-NULL	
}

#################################################################
#libraries to read gml  or shapefile or geoJSON or ....
# see possible file formats  ogrDrivers()   ...
# wps.off
#testInit() # to be commented when in the WPS
# wps.on
######
#LBSmethod<<-"c('WithinPoly'_'LoS')"
#LBSmethod =eval(parse(text= gsub("_",",", LBSmethod)))



library(XML)
library(rgdal)
library(rgeos)




#julian readOGR
layername <- sub(".shp","", inputObservations) # just use the file name as the layer name
Obsdsn = inputObservations
#Obs <- readOGR(dsn = Obsdsn, layer = layername) # Broken for multi-point reading
readMultiPointAsOGR = function(filename ) {  
  library(maptools)
  shape <- readShapePoints(filename)
  writeOGR(shape, ".", "temp", driver="ESRI Shapefile")
  #ogrInfo(".", "temp" )
  tempObs <-readOGR(".",layer= "temp") # 
  return(tempObs)
}
Obs = readMultiPointAsOGR(layername )




print("LOADED DATASETS.")
print("inputObservations")
print(inputObservations)
print("Layer name")
print(layername)
print("Obsdsn")
print(Obsdsn)
print("Printing projection...")
print("Observations prj")
print(Obs@proj4string)



#Didier read OGR
#Obsdsn= inputObservations #getdsn(inputObservations) #"." 
#inputObservations=ogrListLayers(Obsdsn)[1] # supposd only one layer
#GML=attr(ogrListLayers(Obsdsn),"driver")=="GML"
#Obs <-readOGR(Obsdsn,layer= inputObservations)


# metaQ as matrices/vector
ObsMetaQ=ObsMeta

VolMetaQ=VolMeta # "string names"
#then

if(!is.null(ObsMeta) && ObsMeta == Obsdsn)ObsMetaQ=Obs@data
 # shp or gml idem otherwise will be xml from a CSW
if(!is.null(VolMeta) && VolMeta == Obsdsn)VolMetaQ=Obs@data
#modifying 1
ObsMetaQ= GetSetMetaQ(ObsMetaQ,listQ=c(1,7,10,14,16) ,Idrecords= Obs@data[,UUIDFieldName])
VolMetaQ= GetSetMetaQ(VolMetaQ,listQ=c(19:25), Idrecords =Obs@data[,UUIDFieldName],scope='volunteer')
# modifying20:23

## Main loop for each citizen data
for (i in 1:dim(Obs@data)[1]){
	iniDQ01=ObsMetaQ[i,"DQ_01"]
	for (LBSM in LBSmethod)ObsMetaQ[i,"DQ_01"]=pillar2.LocationQuality(i,LBSM)
    Res=pillar2.LocationQualityCSQ(i,iniDQ01)
    
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



#out processing
UpdatedObs=paste0(layername, "out_outP2LQ2_NEW.shp")
writeOGR(Obs,UpdatedObs,"data","ESRI Shapefile")
# wps.out: UpdatedObs, shp_x, returned geometry;

# old out ObsMetaQ.output, xml, title = Observation metadata for quality updated, abstract= each feature in the collection; 
# old out AuthMetaQ.output, xml, title = Auth metadata updated if asked for, abstract= each feature in the collection; 
# old out UserMetaQ.ouput, xml, title = User metadata for quality updated, abstract= each feature in the collection; 

# outputs  by WPS4R