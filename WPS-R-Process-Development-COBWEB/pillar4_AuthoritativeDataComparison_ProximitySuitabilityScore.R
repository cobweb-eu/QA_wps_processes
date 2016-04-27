#################################################################
# FP7 project COBWEB 
#  QAQC   December 2015
# pillar4 Authoritative Data Comparison
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
# pillar4.AuthoritativeDataComparison.ProximitySuitabilityScore 
################################################################
#   deriving the likelihood of the observed occurrence (citizen captured data) from 
#   polygon proximity to a given authoritative data (e.g., existing observed occurrences)
# DQGVQCSQ:
# DQ_UsabilityElement
# DQ_DomainConsistency
# DQ_ThematicClassificationCorrectness
# DQ_NonQuantitativeAttributeCorrectness
# DQ_AbsoluteExternalPositionalAccuracy
# DQ_RelativeInternalPositionalAccuracy
# GVQ_PositiveFeedback
# GVQ_NegativeFeedback
# CSQ_Judgement
# CSQ_Reliability
# CSQ_Validity
# CSQ_Trust   
#################################################################
# note: the algorithm is close to what one can do with k-NN classification

##################################################################
#describtion set for WPS4R
# input  set for 52North WPS4R
# output set for 52North WPS4R

# wps.des: Pillar4.AuthoritativeDataComparison.ProximitySuitabilityScore , title = Pillar 4 AuthoritativeDataComparison.ProximitySuitabilityScore , abstract = QC scoring classification correctness in relation to geometry proximity for the Obs to given authoritative data polygons or points of species. DQGVQCSQ:DQ_UsabilityElement DQ_DomainConsistency DQ_ThematicClassificationCorrectness DQ_NonQuantitativeAttributeCorrectness DQ_AbsoluteExternalPositionalAccuracy DQ_RelativeInternalPositionalAccuracy GVQ_PositiveFeedback GVQ_NegativeFeedback CSQ_Judgement CSQ_Reliability CSQ_Validity CSQ_Trust CSQ_NbContributions;

# wps.in: inputObservations, shp, title = Observation(s) input, abstract= gml or shp of the citizen observations;
# wps.in: UUIDFieldName, string, title = the ID fieldname of the volunteer which will be also in ObsMeta if not NULL and VolMeta,  abstract = record identifier in the inputObservations;
# wps.in: inputAuthData, shp, title = authoritative species data, abstract= gml or shp of the authoritative species data. Can be points or polygons; 
# wps.in: AuthUUIDFieldName, string, title = the  Auth ID fieldname,  abstract = record identifier; 
# wps.in: ScopeLevel, string, value= feature, title= scope as dataset or feature, abstract= if quality is given at feature level for the authoritative data use feature;

# wps.in: AuthMeta, string, value= NULL, title = modelled habitat metadata, abstract= modelled habitat metadata which can be  NULL xml file or same as inputAuthData; 
# wps.in: ObsMeta, string, value= NULL,title = Observation metadata, abstract= can be NULL in an xml file or as inputObservations. If given will update the metadata record(s) ; 
# wps.in: VolMeta, string, value= NULL,title = Volunteer metadata, abstract= can be NULL in an xml file or as inputObservations. If given will update the metadata record(s); 


# wps.in: BufferSizeProx, double, value= 120, title = location proximity , abstract = buffer size in meters to intersect citizen data position with habitat data. Note that The largest BufferSizeProx is the most confidence is given to nearest habitat likelihood (as well as potententially including more habitat locations);
# wps.in: sFUN, string, value= max, title = summary function on weigths of likelihood, abstract = "max" or "mean" on the weigths for each Attrib value (qualitative) or weithed summary of the Attrib. Attrib is the habitat likelihhod of the species;
# wps.in: UsaThresh, string, value= c(0.80 _50_ 20), title= Usability thresholds for quality elements: DQ_ThematicClassificationCorrectness DQ_AbsoluteExternalPositionalAccuracy and DQ_RelativeInternalPositionalAccuracy , abstract=Thresholds to derive DQ_Usability. The input is an R vector like c(0.80 _50 _20) where position accuracies are in meters and classification  correctness is a percentage;
#########################


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
######## function used   
pillar4.ProximitySuitabilityScore <-function(Obs.i,Auth,bufferS, ObsMetaQ=NULL,AuthMetaQ=NULL,VolMetaQ=NULL){
  #pillar5.ModelBasedValidation.ProximitySuitabilityScore(mod.i,ObsMetaQ[i,],ModMetaQ,VolMetaQ[i,])
  
  # if quantitative attribute for likelihood 
  # Obs.i  is the citizen data captured as sp object (feature with attibutes)
  # Mod is themodelled habitat with the attribute ontaining a likelihood 
  #   encoded Low=0 Medium=1 high=2 or quantitative
  #
  #  	#  
  # ObsMetaQ is  quality metadata for Obsrvations (gom and attrib)
  # VolMetaQ is   vector of quality elements for the citizen
  # ModMetaQ is   feedback quality on habitat data 
  #     
  #      would potentially need parsing UncertML within the ISO19157 for the attribute
  
  
  StandDecreaseDist<-function(d,decrF=c("sigmo","Gauss", "invDist"),plato=0.10*bufferS, min=10){
    reScl <-function(d){return(d*100/bufferS)}		
    wei=reScl(d) # 0 to 100
    wei =c(0.01,wei,100); d=c(0,d,1000000)
    weiC=wei
    if(decrF[1]=="invDist"){wei[weiC>=0.001]=100/(wei[weiC>=0.001]);wei[weiC<=0.001]=100}
    if(decrF[1]=="Gauss")wei=100*exp(-wei^2/2222)
    if(decrF[1]=="sigmo")wei=100*(1-1/(1+exp(- (wei-50)/8 ) ))
    wei[d<=plato]=100
    wei=100*(wei-min(wei))/(max(wei)-min(wei))
    wei[wei<=min]=min
    wei=wei[-c(1,length(wei))]
    return(wei/100)	
  }#fin de StandDecreaseDist
  
  vecDistTo <-function(Obs.i,Mod){
    vD=NULL
    for(i in 1:dim(Mod)[1]){
      vD=c(vD,gDistance(geometry(Obs.i),geometry(Mod[i,])))
    }
    return(vD)	
  }#fin de vecDist
  
  summaryFunction<-function(wei,sFUN){ # here in fact onl max or mean of wei 
    #different from P5
    
    #if(toupper(Qual2QuantEncoding) !="QUANT") vect=matchQualOrd(vect, Qual2QuantEncoding)
    if(tolower(sFUN)=="max") out=max(wei)
    if(tolower(sFUN)=="mean") out=mean(wei)
    
    return(out)			
  }#fin de summaryFunction
  RelativeAreas <-function(Obs.i,Mod, minInfl=0.9){
    aeraObs=gArea(Obs.i) #gArea() from rGeos or slot area Obs.i@polygons[[1]]@area
    aeraM=NULL;
    for (u in 1:dim(Mod)[1]){aeraM=c(aeraM,gArea(Mod[u,]))}
    if(sum(aeraM)!=0)infl=aeraM/(sum(aeraM)) # all are points
    else infl=aeraM
    infl[aeraM==0]=1 # if points all to 1
    infl=minInfl + (1-minInfl)*infl*(1+aeraM)/(1+aeraObs+aeraM)
    return(infl)
  }#find de RelativeAreas 
  #####################
  ##############	début
  
  dist=vecDistTo(Obs.i,Auth) # decrF plato max and min hardcoded for now
  if(!any(dist<=bufferS))return(list("ObsMetaQ"=ObsMetaQ, "AuthMetaQ"=AuthMetaQ, "VolMetaQ"=VolMetaQ))	
  
  Auth = Auth[dist<=bufferS,]
  dist=dist[dist<=bufferS]
  if(!any(dist==0)){
    wei=StandDecreaseDist(dist)*RelativeAreas(Obs.i,Auth) #0 1
    score=summaryFunction(wei,sFUN)
  }
  else {
    score=1
  }
  ## reasoning on score to quality
  ##
  ##ObsMeta,listQ=c(DQlookup[c(1,4,14,16),]
  ## DQ_CLassificationCorrectness
  if(ObsMetaQ[,"DQ_04"]!=0.5)ObsMetaQ[,"DQ_04"]=mean(c(ObsMetaQ[,"DQ_04"],score))
  else ObsMetaQ[,"DQ_04"]=score #DQ_04 
  ## DQ_AbsoluteExternalPositionalAccuracy # DQ_14
  # ObsMetaQ[3] must be already in
  ## DQ_RelativeInternalPositionalAccuracy # DQ_16
  
  if(any(AuthMetaQ[,"DQ_16"]!=888)) {    
    if(any(dist<=0.25* BufferSizeProx))ObsMetaQ[,"DQ_16"]=mean(c(ObsMetaQ[,"DQ_16"], AuthMetaQ[dist<=0.25* BufferSizeProx,"DQ_16"]),na.rm=TRUE)
  } # updates/ takes relative position accuracy from nearest Mod
  
  if(any(AuthMetaQ[,"DQ_14"]!=888)) {    
    if(any(dist<=0.25* BufferSizeProx))ObsMetaQ[,"DQ_14"]=mean(c(ObsMetaQ[,"DQ_14"], AuthMetaQ[dist<=0.25* BufferSizeProx,"DQ_14"]),na.rm=TRUE)
  } # updates/ takes absolute position accuracy from nearest Mod
  
  ## DQ_Usability  DQ_ThematicClassificationCorrectness DQ_AbsoluteExternalPositionalAccuracy DQ_Relative...
  # 1 4 14 16
  #browser()
  if(ObsMetaQ[,"DQ_04"] >=UsaThresh["DQ_04"] & ObsMetaQ[,"DQ_14"]<=UsaThresh["DQ_14"] & ObsMetaQ[,"DQ_16"]<=UsaThresh["DQ_16"]){
    ObsMetaQ["DQ_01"]=score  # DQ_01
    #UsaThresh= c(x,y,z) "DQ_4", "DQ_14", "DQ_16)
  } 
  else {
    score=mean(c(ObsMetaQ[,"DQ_01"],score))
    ObsMetaQ[,"DQ_01"]=score	 	
    if(ObsMetaQ[,"DQ_04"]<UsaThresh["DQ_04"])ObsMetaQ[,"DQ_01"]=score^2/UsaThresh["DQ_04"]
    if(ObsMetaQ[,"DQ_14"]>UsaThresh["DQ_14"] && ObsMetaQ[,"DQ_14"]!=888)ObsMetaQ[,"DQ_01"]=score*UsaThresh["DQ_14"]/ObsMetaQ[,"DQ_14"] #
    if(ObsMetaQ[,"DQ_16"]>UsaThresh["DQ_14"] && ObsMetaQ[,"DQ_16"]!=888)ObsMetaQ[,"DQ_01"]=score*UsaThresh["DQ_16"]/ObsMetaQ[,"DQ_16"]
  }
  ## GVQ_PositiveFeedback   GVQ_NegativeFeedback
  if(ObsMetaQ[,"DQ_01"]>=0.80) AuthMetaQ[,"GVQ_01"]= AuthMetaQ[,"GVQ_01"]+1 # nb tot of feedback is the sum
  if(ObsMetaQ[,"DQ_01"]<=0.20) AuthMetaQ[,"GVQ_02"]= AuthMetaQ[,"GVQ_02"]+1
  # CSQ_judgement  CSQ_reliability  CSQ_Validity  CSQ_Trust
  # 21 22 23 24 25
  NBContrib=VolMetaQ[,"CSQ_07"]
  if(is.na(NBContrib)) NBContrib=0
  VolMetaQ[,"CSQ_07"]=NBContrib+1
  if(ObsMetaQ[,"DQ_04"] <=0.20) VolMetaQ[,"CSQ_03"]= max(c(0,(NBContrib*VolMetaQ[,"CSQ_03"]-1)/(NBContrib +1)))
  if(VolMetaQ[,"CSQ_04"] >=0.51 & ObsMetaQ[,"DQ_01"] >=0.70) VolMetaQ[,"CSQ_04"] =(NBContrib*VolMetaQ[,"CSQ_04"]+1)/(NBContrib +1)
  if(ObsMetaQ[,"DQ_04"] >=UsaThresh["DQ_04"]) {
    VolMetaQ[,"CSQ_03"]=max(c(0,VolMetaQ[,"CSQ_03"],na.rm=TRUE))
    VolMetaQ[,"CSQ_05"]=max(c(0,VolMetaQ[,"CSQ_05"],na.rm=TRUE))
    
    VolMetaQ[,"CSQ_03"]= (NBContrib*VolMetaQ[,"CSQ_03"]+1)/(NBContrib +1);
    VolMetaQ[,"CSQ_05"]= mean(c(VolMetaQ[,"CSQ_05"],ObsMetaQ[,"DQ_04"]))
  }
  
  if(mean(c(VolMetaQ[,"CSQ_03"], VolMetaQ[,"CSQ_04"],VolMetaQ[,"CSQ_05"]))>=0.70 & ObsMetaQ[,"DQ_04"] >=UsaThresh["DQ_04"] ) VolMetaQ[,"CSQ_06"]= VolMetaQ[,"CSQ_06"]+1
  
  
  return(list("ObsMetaQ"=ObsMetaQ, "AuthMetaQ"=AuthMetaQ, "VolMetaQ"=VolMetaQ))	
}#

### 
##
findMatchFeature<-function(Obs.i,bufferSo=100){#(Obs.i,Mod,bufferSo=100){
  # polygon including the point
  # or
  # closest point or line
  # here distances or need a spatial! request!
  outlist=gBinarySTRtreeQuery(gBuffer(geometry(Auth),width=0.1,byId=TRUE),gBuffer(geometry(Obs.i), width=bufferSo))[[1]]
  #f
  for (a in outlist){
    if(!is.null(gIntersection(geometry(Obs.i), geometry(Auth)[a,])) )return(a)
  }
  return(NULL)	
} 
# #
findProximityFeatures<-function(Obs.i,bufferS){#(Obs.i,Mod,bufferS){
  # polygon close by obsi
  # or
  # closest point or line
  # here distances or need a spatial! request!
  outlist=c(NULL)
  # select from index and then from proximity
  outlist=gBinarySTRtreeQuery(gBuffer(geometry(Auth),width=0.1,byid=TRUE),gBuffer(geometry(Obs.i), width=bufferS))[[1]]
  #for (a in 1:dim(Modi@data)[1]){# too slow
  #if(gDistance(geometry(Obs.i), geometry(Mod)[a,]) <= bufferS ) outlist=c(outlist,a)	
  #}
  return(outlist)	
} 
# #
getdsn<-function(tt){
  if(attr(ogrListLayers(tt),"driver")=="GML")return(tt)
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
    Meta.all <- xmlParse(Meta, isURL= TRUE)#isUrl(Meta))
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
  for (c in colnames(datU)){
    if (c %in% colnames(dat))dat[,c]=datU[,c]
    else {
      temp=colnames(dat)
      dat=cbind(dat,datU[,c])
      colnames(dat)=c(temp,c)
    }
  }
  return(dat)
}#


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
################################################################################################
########################


testInit <-function(){
  #setwd("C:\\Users\\ezzjfr\\Documents\\R_scripts\\JKWData4Pillar5_proxmitySuitabilityPOlygonScore\\JKWData\\")
  #inputObservations<<- "SnowdoniaNationalParkJapaneseKnotweedSurvey_AllPoints_EnglishCleaned_final.shp"
  setwd("C:\\Users\\ezzjfr\\Documents\\R_scripts\\JKWData4Pillar5_proxmitySuitabilityPOlygonScore\\")
  inputObservations<<- "SnowdoniaNationalParkJapaneseKnotweedSurvey.shp"
  
  
  #setwd("/Users/lgzdl/Documents/Dids/DidsE/COBWEB/Co-Design/JKW knotweed (Snodonian)/DidData/")	
  #inputObservations<<-"SnowdoniaNationalParkJapaneseKnotweedSurvey_AllPoints_EnglishCleaned_final.shp"
    
  UUIDFieldName<<-"Iden"     #string
  UUIDFieldName<<-"timestamp"     #string
  
  inputAuthData <<-"JK_SNP_COFNOD.shp"     #shp
  AuthUUIDFieldName<<-"NULL"
  ScopeLevel<<-"feature"
  AuthMeta<<-NULL
  ObsMeta<<-inputObservations
  VolMeta<<-inputObservations
  BufferSizeProx<<-88# 800 # as a test with the sigmoid distance weighting auth at 20% of 800=160 still have a full weigth 
  NbSpecies<<-1 # same or forced by InAttribFieldName=NULL
  sFUN<<-"max"
  UsaThresh<<-"c(0.8_60_20)"
  
}

#################################################################
#libraries to read gml  or shapefile or geoJSON or ....
# see possible file formats  ogrDrivers()   ...
#wps.off
#testInit() # to be commented when in the WPS
#wps.on
######
######
UsaThresh= eval(parse(text= gsub("_",",", UsaThresh)))
names(UsaThresh)=c("DQ_04","DQ_14","DQ_16")
#####################
library(XML)
library(rgdal)
library(rgeos)
library(sp)


Obsdsn= inputObservations #getdsn(inputObservations) #"." 
Authdsn = inputAuthData #getdsn(inputModData)  #"."


inputObservations=ogrListLayers(Obsdsn)[1] # supposed only one layer
inputAuthData =ogrListLayers(Authdsn)[1] # supposed only one layer

GML=attr(ogrListLayers(Obsdsn),"driver")=="GML" 

Obs <-readOGR(Obsdsn,layer= inputObservations) # 
Auth <-readOGR(Authdsn,layer= inputAuthData) # or use readShp

#ObsAttrib=Obs@data[,c(UUIDFieldName)] # ID attribute with UUID 
#ModAttrib=Mod@data[,c(ModUUIDFieldName ,ModAttribFieldName)]
# kind of clip Auth to buffer obs
clipDist=800
RectObs=gBuffer(bboxAsPol(Obs),width=clipDist)
LesA=gBinarySTRtreeQuery(gBuffer(Auth,width=0.1,byid=TRUE),RectObs)[[1]]
Auth = Auth[LesA,]	#eg pour Woodland on passe de 58480 - 618 useful

# metaQ as matrices/vector
ObsMetaQ=ObsMeta
AuthMetaQ=AuthMeta
VolMetaQ=VolMeta # "sting names"
#then
if(!is.null(ObsMeta) && ObsMeta == Obsdsn)ObsMetaQ=Obs@data # shp or gml idem otherwise will be xml from a CSW
if(!is.null(VolMeta) && VolMeta == Obsdsn)VolMetaQ=Obs@data
if(!is.null(AuthMeta) && AuthMeta == Authdsn) AuthMetaQ =Auth@data


ObsMetaQ=GetSetMetaQ(ObsMetaQ,listQ=c(1,4,14,16),Idrecords= Obs@data[,UUIDFieldName] )
if(is.null(AuthUUIDFieldName) || AuthUUIDFieldName=="NULL") {
  AuthMetaQ=GetSetMetaQ(AuthMetaQ,listQ=c(14,16,17,18), Idrecords = 1:dim(Auth)[1],scope='feature')
} else {
  AuthMetaQ=GetSetMetaQ(AuthMetaQ,listQ=c(14,16,17,18), Idrecords = Auth@data[,AuthUUIDFieldName],scope='feature')
}
VolMetaQ=GetSetMetaQ(VolMetaQ,listQ=21:25, Idrecords =Obs@data[,UUIDFieldName],scope='volunteer')

####################
# default init settings in case of no quality metadata DQ_14 DQ_16  for obs et Mod   CSQ

####################

### loop for each citizen data
for (i in 1:dim(Obs@data)[1]){
#for (i in 1:10){
  bufferS= BufferSizeProx 
  if(!is.na(ObsMetaQ[i,"DQ_14"]) && ObsMetaQ[i,"DQ_14"]!=888)bufferS=bufferS+ObsMetaQ[i,"DQ_14"] #halo from GPS
  auth=findProximityFeatures(Obs[i,],bufferS)# (Obs[i,],Mod,bufferS) # i
  if(!is.null(auth)) {		
    Res=pillar4.ProximitySuitabilityScore(Obs[i,],Auth[auth,],bufferS, ObsMetaQ[i,],AuthMetaQ[auth,],VolMetaQ[i,])
    ObsMetaQ[i,]=Res$ObsMetaQ ; AuthMetaQ[auth,]=Res$AuthMetaQ ; VolMetaQ[i,]=Res$VolMetaQ
  }	
  
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
  colnames(AuthMetaQ)=paste(substring(inputModData,1,7),colnames(AuthMetaQ),sep="_")
  Mod@data=cbind(Mod@data, AuthMetaQ)	
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

localDir=getwd()
if(is.null(UpdatedObs))UpdatedObs=paste(inputObservations,"outP4PSPS",sep="")


if(GML) writeOGR(Obs,localDir, layer=UpdatedObs, driver="GML" ,overwrite_layer=TRUE)
if(!GML) writeOGR(Obs,localDir, layer=UpdatedObs, driver="ESRI Shapefile" ,overwrite_layer=TRUE)



cat(paste("Saved Destination: ", localDir, "\n with \n",UpdatedObs, " .gml or .shp ",sep=""), "\n" )

# wps.out: id=UpdatedObs, type=shp , title = Observation and metadata for quality updated, abstract= each feature in the collection ; 


# old out ObsMetaQ.output, xml, title = Observation metadata for quality updated, abstract= each feature in the collection 
# old out AuthMetaQ.output, xml, title = Auth metadata updated if asked for, abstract= each feature in the collection
# old out UserMetaQ.ouput, xml, title = User metadata for quality updated, abstract= each feature in the collection

# outputs  by WPS4R