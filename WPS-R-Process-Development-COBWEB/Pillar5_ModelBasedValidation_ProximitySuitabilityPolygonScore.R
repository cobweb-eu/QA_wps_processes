#################################################################
# FP7 project COBWEB 
#  QAQC   Octobre 2015
# pillar5 Model-Based Validation
#            
# Dr Didier Leibovici, Dr Julian Rosser and Pr Mike Jackson University of Nottingham
#
# as process part of the WPS
# input format and output format of the data and metadata 
# are managed within the java wrapper from 52N
# testInit() is a test setting up the inputs and outputs parameters when ran only from within R alone
#
# pillar5.ModelBasedValidation.xxxx 
#   where xxxx is the name of the particular QC test
################################################################
# pillar5. ModelBasedValidation.ProximitySuitabilityPolygonScore 
################################################################
#   deriving the likelihood of the observed occurrence (citizen captured data) from polygon proximity 
#         with given model-estimated likelihood areas (given data with a field scoring the habitat likelihood )
#   QC mostly estimating the classification correctness in relation to geometry proximity for the Obs to given modelled polygons of habitat with likelihood associated for a given species. 
# DQGVQCSQ:("DQ_UsabilityElement","DQ_ThematicClassificationCorrectness","DQ_AbsoluteExternalPositionalAccuracy", "DQ_RelativeInternalPositionalAccuracy","GVQ_PositiveFeedback","GVQ_NegativeFeedback","CSQ_Judgement",                         "CSQ_Reliability","CSQ_Validity","CSQ_Trust","CSQ_NbContributions")  
#################################################################


#1=getNodeSet(xx,"//gmd:DQ_DataQuality[.//gmd:MD_ScopeCode[@codeListValue='dataset'] ]//gmd:DQ_RelativeInternalPositionalAccuracy[.//gmd:measureDescription/gco:CharacterString/text()='geographic']//gco:Record")

##################################################################
#describtion set for WPS4R
# input  set for 52North WPS4R
# output set for 52North WPS4R

# wps.des: id = Pillar5.ModelBasedValidation.ProximitySuitabilityPolygonScore, title = Pillar 5 ModelBasedValidation.ProximitySuitabilityPolygonScore, 
# abstract = QC scoring classification correctness in relation to geometry proximity for the Obs to given modelled polygons of habitat with likelihood associated for a given species. DQGVQCSQ:("DQ_UsabilityElement" "DQ_ThematicClassificationCorrectness" "DQ_AbsoluteExternalPositionalAccuracy" "DQ_RelativeInternalPositionalAccuracy" "GVQ_PositiveFeedback" "GVQ_NegativeFeedback" "CSQ_Judgement" "CSQ_Reliability" "CSQ_Validity" "CSQ_Trust" "CSQ_NbContributions");

# wps.in: inputObservations, shp_x, title = Observation(s) input, abstract = gml or shp of the citizen observations; 
# wps.in: UUIDFieldName, string, value = Iden, title = the ID fieldname of the volunteer which will be also in ObsMeta if not NULL and VolMeta,  abstract = record identifier in the inputObservations; 

# wps.in: inputModData, application/x-zipped-shp, title = habitat modelled data, abstract = gml or shp of the habitat modelled data; 
# wps.in: ModAttribFieldName, string, value= GRIDCODE, title = Habitat likelihood attribute Name, abstract = likelihood attribute names as habitat for the species encoded. e.g. 0 / 1 / 2 / 3  for None / Low / Medium / High  or quantitative;
# wps.in: ModUUIDFieldName, string,  value= ID, title = the  Mod ID fieldname, abstract = record identifier; 
# wps.in: Qual2QuantEncoding, string, value= 0, title = Qualitative to Quantitative encoding, abstract= e.g. "cbind(c(0 1 2 3)  c(0 0.25 0.65 0.90))"as a R vector when reasoning on ordinal values as quantitative or "QUANT" meaning it is quantitativ;
# wps.in: ScopeLevel, string, value= feature, title= scope as dataset or feature, abstract= if quality is given at feature level for the authoritative data use " feature";


# wps.in: ModMeta, string, value= NULL, title = modelled habitat metadata, abstract= modelled habitat metadata which can be  NULL or xml file or same as inputModData; 
# wps.in: ObsMeta, string, value= NULL, title = Observation metadata, abstract= can be NULL in an xml file or as inputObservations. If given will update the metadata record(s); 
# wps.in: VolMeta, string, value= NULL, title = Volunteer metadata, abstract= can be NULL in an xml file or as inputObservations. If given will update the metadata record(s); 


# wps.in: BufferSizeProx, double, value= 120, title = location proximity, abstract = buffer size in meters to intersect citizen data position with habitat data. Note that The largest BufferSizeProx is the most confidence is given to nearest habitat likelihood (as well as potententially including more habitat locations);
# wps.in: sFUN, string, value= max, title = summary function on weigths of likelihood, abstract = "max" or "mean" on the weigths for each Attrib value (qualitative) or weithed summary of the Attrib. Attrib is the habitat likelihhod of the species;
# wps.in: AttrQuanti, boolean, value=TRUE, title = Likelihood Attribute Q, abstract = "TRUE" or "FALSE"  to consider the attribute as quantitative. Use of Qual2QuantEncoding for numerical values when ordinal;
# wps.in: UsaThresh, string, value= values, title= Usability thresholds for quality elements: DQ_ThematicClassificationCorrectness DQ_AbsoluteExternalPositionalAccuracy and DQ_RelativeInternalPositionalAccuracy, abstract=Thresholds to derive DQ_Usability. The input is an R vector like c(0.80 50 20) where position accuracies are in meters and classification correctness is a percentage;


####### codelist initialisation if needed

#####################ISO10157#############
DQ=c("DQ_UsabilityElement","DQ_CompletenessCommission","DQ_CompletenessOmission","DQ_ThematicClassificationCorrectness",
"DQ_NonQuantitativeAttributeCorrectness","DQ_QuantitativeAttributeAccuracy","DQ_ConceptualConsistency","DQ_DomainConsistency","DQ_FormatConsistency","DQ_TopologicalConsistency","DQ_AccuracyOfATimeMeasurement","DQ_TemporalConsistency","DQ_TemporalValidity","DQ_AbsoluteExternalPositionalAccuracy","DQ_GriddedDataPositionalAccuracy","DQ_RelativeInternalPositionalAccuracy")
####################GeoViQUA basic########
GVQ=c("GVQ_PositiveFeedback","GVQ_NegativeFeedback") #can be used also for user
################# Stakeholder Quality Model 
CSQ=c("CSQ_Ambiguity","CSQ_Vagueness","CSQ_Judgement","CSQ_Reliability","CSQ_Validity","CSQ_Trust","CSQ_NbContributions")
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
pillar5.ProximitySuitabilityPolygonScore <-function(Obs.i,Mod,bufferS, ObsMetaQ=NULL,ModMetaQ=NULL,VolMetaQ=NULL){
	#pillar5.ModelBasedValidation.ProximitySuitabilityPolygonScore(mod.i,ObsMetaQ[i,],ModMetaQ,VolMetaQ[i,])
 
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
		
		matchQualOrd<-function(vect, Qual2QuantEncoding){
			# Qual2QuantEncoding="cbind(c(0,1,2), c(0.20, 0.55, 0.75))"
			# Qual2QuantEncoding="cbind(c('Low",'Medium','High'), c(0.20, 0.55, 0.75))"
			QQnu=eval(parse(text= gsub("_",",",Qual2QuantEncoding)))
			vect=mapply(FUN=function(x){QQnu[ QQnu[,1]==x,2]},vect)
		return(as.numeric(vect))	
		}#end of matchQualOrd
		
		summaryFunction<-function(wei,vect,AttrQuanti,Qual2QuantEncoding,sFUN){
			if(AttrQuanti){
				if(toupper(Qual2QuantEncoding) !="QUANT") vect=matchQualOrd(vect, Qual2QuantEncoding)
				if(tolower(sFUN)=="max") out=max(wei*vect)
				if(tolower(sFUN)=="mean") out=mean(wei*vect)
			}
			else{
				if(tolower(sFUN)=="max") out=aggregate(wei,list(vect),FUN=max)
				else out=aggregate(wei,list(vect),FUN=mean)
				out=out[ out[,2]==max(out[,2]) ,1 ] # factor label of the max
				if(toupper(Qual2QuantEncoding) !="QUANT") out=matchQualOrd(out, Qual2QuantEncoding)
			}
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
	
	dist=vecDistTo(Obs.i,Mod) # decrF plato max and min hardcoded for now
	if(!any(dist<=bufferS))return(list("ObsMetaQ"=ObsMetaQ, "ModMetaQ"=ModMetaQ, "VolMetaQ"=VolMetaQ))	
	
	Mod=Mod[dist<=bufferS,]
	dist=dist[dist<=bufferS]
	if(!any(dist==0)){
	    wei=StandDecreaseDist(dist)*RelativeAreas(Obs.i,Mod) #0 1
	    score=summaryFunction(wei, Mod@data[, ModAttribFieldName],AttrQuanti, Qual2QuantEncoding,sFUN)
	}
	else 
		{   lePol=Mod[dist==0,]# could be more than one
			if(gArea(Obs.i)!=0){
				score=(1-(gArea(Obs.i)-gArea(gIntersection(Obs.i,lePol)))/gArea(Obs.i))
				if(AttrQuanti)
				score=score*mean(matchQualOrd(lePol@data[, ModAttribFieldName], Qual2QuantEncoding)) 
				else score=score*max(matchQualOrd(lePol@data[, ModAttribFieldName], Qual2QuantEncoding))
			}
			else score=max(matchQualOrd(lePol@data[, ModAttribFieldName], Qual2QuantEncoding))
	}
	## reasoning on score to quality
	##
	##ObsMeta,listQ=c(DQlookup[c(1,4,14,16),]
		## DQ_CLassificationCorrectness
	 ObsMetaQ[,"DQ_04"]=score #DQ_04 
	## DQ_AbsoluteExternalPositionalAccuracy # DQ_14
	 # ObsMetaQ[3] must be already in
	## DQ_RelativeInternalPositionalAccuracy # DQ_16
	       
	 if(any(!is.na(ModMetaQ[,"DQ_16"]))) {    
	  if(any(dist<=0.25* BufferSizeProx))ObsMetaQ[,"DQ_16"]=mean(c(ObsMetaQ[,"DQ_16"],ModMetaQ[dist<=0.25* BufferSizeProx,"DQ_16"]),na.rm=TRUE)
	  } # updates/ takes relative position accuracy from nearest Mod
	  
	  if(any(!is.na(ModMetaQ[,"DQ_14"]))) {    
	  if(any(dist<=0.25* BufferSizeProx))ObsMetaQ[,"DQ_14"]=mean(c(ObsMetaQ[,"DQ_14"],ModMetaQ[dist<=0.25* BufferSizeProx,"DQ_14"]),na.rm=TRUE)
	  } # updates/ takes absolute position accuracy from nearest Mod
	  
	## DQ_Usability  DQ_ThematicClassificationCorrectness DQ_AbsoluteExternalPositionalAccuracy DQ_Relative...
	    # 1 4 14 16
	    #browser()
	 if(ObsMetaQ[,"DQ_04"] >=UsaThresh["DQ_04"] & ObsMetaQ[,"DQ_14"]<=UsaThresh["DQ_14"] & ObsMetaQ[,"DQ_16"]<=UsaThresh["DQ_16"]){
	     ObsMetaQ["DQ_01"]=score  # DQ_01
	     #UsaThresh= c(x,y,z) "DQ_4", "DQ_14", "DQ_16)
	 } 
	 else {ObsMetaQ[,"DQ_01"]=score
	 	if(ObsMetaQ[,"DQ_04"]<UsaThresh["DQ_04"])ObsMetaQ[,"DQ_01"]=score^2/UsaThresh["DQ_04"]
	 	if(ObsMetaQ[,"DQ_14"]>UsaThresh["DQ_14"] && ObsMetaQ[,"DQ_14"]!=888)ObsMetaQ[,"DQ_01"]=score*UsaThresh["DQ_14"]/ObsMetaQ[,"DQ_14"] #
	 	if(ObsMetaQ[,"DQ_16"]>UsaThresh["DQ_14"] && ObsMetaQ[,"DQ_16"]!=888)ObsMetaQ[,"DQ_01"]=score*UsaThresh["DQ_16"]/ObsMetaQ[,"DQ_16"]
	 }
	## GVQ_PositiveFeedback   GVQ_NegativeFeedback
	if(ObsMetaQ[,"DQ_01"]>=0.80) ModMetaQ[,"GVQ_01"]=ModMetaQ[,"GVQ_01"]+1 # nb tot of feedback is the sum
	if(ObsMetaQ[,"DQ_01"]<=0.20) ModMetaQ[,"GVQ_02"]=ModMetaQ[,"GVQ_02"]+1
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
	
				
return(list("ObsMetaQ"=ObsMetaQ, "ModMetaQ"=ModMetaQ, "VolMetaQ"=VolMetaQ))	
}#

### 
##
findMatchFeature<-function(Obs.i,Mod,bufferSo=100){
 # polygon including the point
 # or
 # closest point or line
 # here distances or need a spatial! request!
    outlist=gBinarySTRtreeQuery(geometry(Mod),gBuffer(geometry(Obs.i), width=bufferSo))[[1]]
   #f
  for (a in outlist){
   if(!is.null(gIntersection(geometry(Obs.i), geometry(Mod)[a,])) )return(a)
  }
return(NULL)	
} 
# #

findProximityFeatures<-function(Obs.i,bufferS){  #(Obs.i,Mod,bufferS){
  # polygon close by obsi
  # or
  # closest point or line
  # here distances or need a spatial! request!
  outlist=c(NULL)
  # select from index and then from proximity
  outlist=gBinarySTRtreeQuery(geometry(Mod),gBuffer(geometry(Obs.i), width=bufferS))[[1]]
  #for (a in 1:dim(Modi@data)[1]){# too slow
  #if(gDistance(geometry(Obs.i), geometry(Mod)[a,]) <= bufferS ) outlist=c(outlist,a)    
  #}
  return(outlist)    
} 

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
	# create a vector/matrix withe values or "0" otherwise
	#
	# are encode using DQlookup[,1]
	# then to be passed either
	
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
		for (j in listQ){
			if (DQlookup[j,1] %in% colnames(Meta)) MetaQ[,DQlookup[j,1]]=Meta@data[,DQlookup[j,1]]
			else if (DQlookup[j,2] %in% colnames(Meta)) MetaQ[,DQlookup[j,1]]=Meta@data[,DQlookup[j,2]]
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


#########################


testInit <-function(){
  setwd("C:\\Users\\ezzjfr\\Documents\\R_scripts\\JKWData4Pillar5_proxmitySuitabilityPOlygonScore\\")
	inputObservations<<-"SnowdoniaNationalParkJapaneseKnotweedSurvey.shp" #shp
	UUIDFieldName<<-"Iden"     #string 
	inputModData<<-"JKWrisk_10mSquares.shp"     #shp
  inputModData<<-"JKWrisk_10mSquares_subset_10_features.shp"     #shp
	ModAttribFieldName<<-"GRIDCODE" # string
	ModUUIDFieldName<<-"ID"
	Qual2QuantEncoding<<-"cbind(c(0_1_2_3)_ c(0.0 _0.25 _0.65 _0.90))"
	ScopeLevel<<-"feature"
	ModMeta<<-NULL
	ObsMeta<<-NULL
	VolMeta<<-NULL
	BufferSizeProx<<-800 # as a test with the sigmoid distance weighting auth at 20% of 800=160 still have a full weigth 
	sFUN<<-"max"
	AttrQuanti<<-TRUE
	UsaThresh<<-"c(0.8_ 60_ 20)"	
}

#################################################################
#libraries to read gml  or shapefile or geoJSON or ....
# see possible file formats  ogrDrivers()   ...
# wps.off;
#testInit() # to be commented when in the WPS
# wps.on;
######


UsaThresh=eval(parse(text= gsub("_",",",UsaThresh)))
names(UsaThresh)=c("DQ_04","DQ_14","DQ_16")

library(XML)
library(rgdal)
library(rgeos)

 Obsdsn=getdsn(inputObservations) #"." 
 Moddsn=getdsn(inputModData)  #"."
  inputObservations=sub(Obsdsn,"",sub(".gml","",sub(".shp","", inputObservations,fixed=TRUE),fixed=TRUE),fixed=TRUE)#no .shp can be gml etc..
  inputModData =sub(Moddsn,"",sub(".gml","",sub(".shp","", inputModData,fixed=TRUE),fixed=TRUE),fixed=TRUE)
  
 
  
Obs <-readOGR(Obsdsn,layer= inputObservations) # 
Mod <-readOGR(Moddsn,layer=inputModData) # or use readShp
#Mod <-readShapePoly(inputModData) #Can use this


ObsAttrib=Obs@data[,c(UUIDFieldName)] # ID attribute with UUID 
ModAttrib=Mod@data[,c(ModUUIDFieldName ,ModAttribFieldName)]


# metaQ as matrices/vector

if(!is.null(ObsMeta) && ObsMeta == inputObservations)ObsMeta=Obs # shp or gml idem otherwise will be xml from a CSW
if(!is.null(VolMeta) && VolMeta == inputObservations)VolMeta=Obs
if(!is.null(ModMeta) && ModMeta == inputModData)ModMeta=Mod


ObsMetaQ=GetSetMetaQ(ObsMeta,listQ=c(1,4,14,16),Idrecords= ObsAttrib)
ModMetaQ=GetSetMetaQ(ModMeta,listQ=c(14,16,17,18), Idrecords = ModAttrib[,ModUUIDFieldName],scope='feature')
VolMetaQ=GetSetMetaQ(VolMeta,listQ=21:25, Idrecords =ObsAttrib,scope='volunteer')

####################
# default init settings in case of no quality metadata DQ_14 DQ_16  for obs et Mod   CSQ

  ####################

### loop for each citizen data
for (i in 1:length(ObsAttrib)){
#for (i in 1:10){
	bufferS= BufferSizeProx 
	 if(!is.na(ObsMetaQ[i,"DQ_14"]) && ObsMetaQ[i,"DQ_14"]!=888)bufferS=bufferS+ObsMetaQ[i,"DQ_14"] #halo from GPS
	mod.i=findProximityFeatures(Obs[i,],bufferS)   # (Obs[i,],Mod,bufferS) # i
	if(!is.null(mod.i)) {		
	  Res=pillar5.ProximitySuitabilityPolygonScore(Obs[i,],Mod[mod.i,],bufferS, ObsMetaQ[i,],ModMetaQ[mod.i,],VolMetaQ[i,])
	  ObsMetaQ[i,]=Res$ObsMetaQ
    ModMetaQ[mod.i,]=Res$ModMetaQ
    VolMetaQ[i,]=Res$VolMetaQ
	}	
} #for


####### metadata of data quality ouput
##	

outputForma="allinWFS" #  observations were in a WFS and we add on DQs ...!!!
		               #"CSW" or "SOS" a ISO19157 reporting is made and either 
		               #sent to a CSW or with the observations in O&M
fullQualityNames=FALSE

## all in WFS
if(outputForma=="allinWFS"){
	Obs@data=cbind(Obs@data,ObsMetaQ, VolMetaQ)	
}



#localDir=getwd()
#UpdatedObs=paste(inputObservations,"_pillar5_ProximitySuitabilityPolygonScore",sep="")
#writeOGR(Obs,localDir, UpdatedObs, driver="ESRI Shapefile" )
#UpdatedObs=paste(UpdatedObs,".shp",sep="")
#cat(paste("Saved Destination: ", localDir, "/",UpdatedObs,sep=""), "\n" )

UpdatedObs="out.shp"
writeOGR(Obs,UpdatedObs,"data","ESRI Shapefile")

#out processing
# wps.out: UpdatedObs, shp_x, returned geometry;
