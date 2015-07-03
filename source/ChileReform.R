# ChileReform.R v0.00              KEL / DCC               yyyy-mm-dd:2015-07-01
#---|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
#
# Runs spillover estimation from Chile using emergency contraceptive reform. Th-
# is file is a shortened and altered version of BirthEstimates.R from the morni-
# ng after pill paper.
#
#
# contact: damian.clarke@economics.ox.ac.uk

rm(list=ls())

#==============================================================================
#=== (1) Libraries, directories
#==============================================================================
require("MatchIt"  )
require("xtable"   )
require("rms"      )
require("plyr"     )
require("glmmML"   )
require("sandwich" )
require("stargazer")
require("lmtest"   )
require("plotrix"  )

brth.dir <- "~/universidades/Oxford/DPhil/Thesis/Teens/Data/Nacimientos/"
tab.dir  <- "~/investigacion/2014/Spillovers/tables/"
graf.dir <- "~/investigacion/2014/Spillovers/results/Chile/"


Names <- c("dom_comuna","trend","trend2","pill","mujer","party","votes"      ,
           "outofschool","healthspend","healthstaff","healthtraining"        , 
           "educationspend","femalepoverty","year","urban","educationmunicip",
           "condom","usingcont","femaleworkers","region","popln")

#==============================================================================
#=== (3) Load Data
#==============================================================================
f <- paste(brth.dir, "S1Data_granular_covars.csv", sep="")
orig <- read.csv(f)

#==============================================================================
#=== (4) Main Functions
#==============================================================================
stars <- function(p,B) {
    b <- ifelse(p < 0.01,
                paste(format(round(B,3),nsmall=3),"$^{***}$",sep=""),
                ifelse(p < 0.05,
                       paste(format(round(B,3),nsmall=3),"$^{**}$",sep=""),
                       ifelse(p < 0.1,
                              paste(format(round(B,3),nsmall=3),"$^{*}$",sep=""),
                              format(round(B,3),nsmall=3))))
    b  <- sub('-', '$-$', b)  
    return(b)
}

pillest <- function(outresults,d,n,regex,dim) {
    pillline <- grepl(regex,rownames(summary(outresults)$coefficients))
  
    if(dim==1|dim==3|dim==10) {
        beta <- summary(outresults)$coefficients[pillline,]["Estimate"]
        se   <- outresults$coefficients2[pillline,]["Std. Error"]
        if (dim==1) {p <- outresults$coefficients2[pillline,]["Pr(>|z|)"]}
        else {p <- outresults$coefficients2[pillline,]["Pr(>|t|)"]}
    }
    else {
        beta <- summary(outresults)$coefficients[pillline,][, "Estimate"]
        se   <- outresults$coefficients2[pillline,][, "Std. Error"]
        if (dim==11) {p <- outresults$coefficients2[pillline,][,"Pr(>|t|)"]}
        else {p    <- outresults$coefficients2[pillline,][, "Pr(>|z|)"]}
    }
  
    if (dim==1|dim==4) {
        null  <- glm(cbind(successes,failures) ~ 1, family="binomial",data=d)
        Lfull <- as.numeric(logLik(outresults))
        Lnull <- as.numeric(logLik(null))
        R2    <- 1 - Lfull/Lnull
    }
    if(dim==10|dim==11) {
        R2 <- summary(outresults)$r.squared
    }
    beta  <- stars(p,beta)
    se    <- paste("(", format(round(se,3),nsmall=3),")", sep="")
    R2    <- format(round(R2,3),nsmall=3)
    n     <- format(n,big.mark=",",scientific=F)
    
  
    return(list("b" = beta, "s" = se, "p" = p, "r" = R2, "n" = n))
}

robust.se <- function(model, cluster) {
    M <- length(unique(cluster))
    N <- length(cluster)
    K <- model$rank
    dfc <- (M/(M - 1)) * ((N - 1)/(N - K))
    uj <- apply(estfun(model), 2, function(x) tapply(x, cluster, sum));
    rcse.cov <- dfc * sandwich(model, meat = crossprod(uj)/N)
    rcse.se <- coeftest(model, rcse.cov)
    return(list(rcse.cov, rcse.se))
}

closegen <- function(d1,d2,dat) {
    dat2 <- dat
		# EUCLIDEAN DISTANCE
    dat2$newvar <- NA  
    dat2$newvar[dat2$pilldistance > d1 & dat2$pilldistance <= d2 &
                !(dat2$pilldistance)==0] <- 1
    dat2$newvar[is.na(dat2$newvar)]<-0

		# ROAD DISTANCE
    dat2$newvar2 <- NA  
    dat2$newvar2[dat2$roadDist/1000 > d1 & dat2$roadDist/1000 <= d2 &
                !(dat2$roadDist)==0] <- 1
    dat2$newvar2[is.na(dat2$newvar2)]<-0

		# TRAVEL TIME
    dat2$newvar3 <- NA  
    dat2$newvar3[dat2$travelTime/60 > d1 & dat2$travelTime/60 <= d2 &
                !(dat2$travelTime)==0] <- 1
    dat2$newvar3[is.na(dat2$newvar3)]<-0

    names(dat2)<-c(names(dat),paste('close',d2,sep=""),paste('road',d2,sep=""),
									 paste('time',d2,sep=""))
    return(dat2)
}

datcollapse <- function(age_sub,order_sub,ver,dat) {

    dat <- dat[dat$age %in% age_sub,]
    dat <- dat[(dat$order %in% order_sub) | !(dat$pregnant),]
    dat$popln <- ave(dat$n,dat$dom_comuna,dat$year,FUN=sum)
    if(ver==2) {
        dat <- dat[dat$pregnant==1,]
    }
    dat <- closegen(0,10,dat)
    dat <- closegen(10,20,dat)
    dat <- closegen(20,30,dat)
    dat <- closegen(30,40,dat)
    
    dat$failures <- (1-dat$pregnant)*dat$n
    dat$successes <- dat$pregnant*dat$n

    fmod <- aggregate.data.frame(dat[,c("failures","successes")],
                                 by=list(dat$close10,dat$close20,dat$close30,
                                     dat$close40,dat$road10,dat$road20      ,
                                     dat$road30,dat$road40,dat$time10       ,
                                     dat$time20,dat$time30,dat$time40       ,
                                     dat$dom_comuna,dat$year-2005           ,
                                     (dat$year-2005)^2,dat$pill,dat$mujer   ,
                                     dat$party,dat$votop,dat$outofschool    ,
                                     dat$healthspend,dat$healthstaff        ,
                                     dat$healthtraining,dat$educationspend  ,
                                     dat$femalepoverty,dat$urbBin,dat$year  ,
                                     dat$educationmunicip,dat$condom        ,
                                     dat$usingcont,dat$femaleworkers        ,
                                     dat$region,dat$popln),
                                 function(vec) {sum(na.omit(vec))})
    names(fmod) <- c("close10","close20","close30","close40","road10"     ,
                     "road20","road30","road40","time10","time20","time30",
                     "time40",Names,"failures","successes")
    fmod$healthstaff      <- fmod$healthstaff/100000
    fmod$healthspend      <- fmod$healthspend/100000
    fmod$healthtraining   <- fmod$healthtraining/100000
    fmod$educationspend   <- fmod$educationspend/100000
    fmod$educationmunicip <- fmod$educationmunicip/100000
    fmod$meanP            <- ave(fmod$pill, group=fmod$dom_comuna)

    return(fmod)
}


#==============================================================================
#=== (5) Estimating functions
#==============================================================================
spillovers <- function(age_sub,order_sub) {

    formod <- datcollapse(age_sub, order_sub,1,orig)
    

    xspill0 <- glm(cbind(successes,failures) ~ factor(dom_comuna)         + 
                  factor(dom_comuna):trend + factor(year) + factor(pill)  + 
                  factor(party) + factor(mujer) + votes + outofschool     + 
                  educationspend + educationmunicip + healthspend         + 
                  healthtraining + healthstaff + femalepoverty + condom   + 
                  femaleworkers,
                  family="binomial",data=formod)
    clusters <-mapply(paste,"dom_comuna.",formod$dom_comuna,sep="")
    xspill0$coefficients2 <- robust.se(xspill0,clusters)[[2]]

    xspill1 <- glm(cbind(successes,failures) ~ factor(dom_comuna)         + 
                  factor(dom_comuna):trend + factor(year) + factor(pill)  + 
                  factor(party) + factor(mujer) + votes + outofschool     + 
                  educationspend + educationmunicip + healthspend         + 
                  healthtraining + healthstaff + femalepoverty + condom   + 
                  femaleworkers + factor(close10),
                  family="binomial",data=formod)
    clusters <-mapply(paste,"dom_comuna.",formod$dom_comuna,sep="")
    xspill1$coefficients2 <- robust.se(xspill1,clusters)[[2]]

    xspill2 <- glm(cbind(successes,failures) ~ factor(dom_comuna)         + 
                  factor(dom_comuna):trend + factor(year) + factor(pill)  + 
                  factor(party) + factor(mujer) + votes + outofschool     + 
                  educationspend + educationmunicip + healthspend         + 
                  healthtraining + healthstaff + femalepoverty + condom   + 
                  femaleworkers + factor(close10) + factor(close20),
                  family="binomial",data=formod)
    clusters <-mapply(paste,"dom_comuna.",formod$dom_comuna,sep="")
    xspill2$coefficients2 <- robust.se(xspill2,clusters)[[2]]

    xspill3 <- glm(cbind(successes,failures) ~ factor(dom_comuna)         + 
                  factor(dom_comuna):trend + factor(year) + factor(pill)  + 
                  factor(party) + factor(mujer) + votes + outofschool     + 
                  educationspend + educationmunicip + healthspend         + 
                  healthtraining + healthstaff + femalepoverty + condom   + 
                  femaleworkers + factor(close10) + factor(close20)       +
                  factor(close30), family="binomial",data=formod)
    clusters <-mapply(paste,"dom_comuna.",formod$dom_comuna,sep="")
    xspill3$coefficients2 <- robust.se(xspill3,clusters)[[2]]

    xspill4 <- glm(cbind(successes,failures) ~ factor(dom_comuna)         + 
                  factor(dom_comuna):trend + factor(year) + factor(pill)  + 
                  factor(party) + factor(mujer) + votes + outofschool     + 
                  educationspend + educationmunicip + healthspend         + 
                  healthtraining + healthstaff + femalepoverty + condom   + 
                  femaleworkers + factor(close10) + factor(close20)       +
                  factor(close30) + factor(close40),
                  family="binomial",data=formod)
    clusters <-mapply(paste,"dom_comuna.",formod$dom_comuna,sep="")
    xspill4$coefficients2 <- robust.se(xspill4,clusters)[[2]]

    n  <- sum(formod$successes) + sum(formod$failures)
    s0 <- pillest(xspill0,formod,n,"pill",1)
    s1 <- pillest(xspill1,formod,n,"pill|close",4)
    s2 <- pillest(xspill2,formod,n,"pill|close",4)
    s3 <- pillest(xspill3,formod,n,"pill|close",4)
    s4 <- pillest(xspill4,formod,n,"pill|close",4)
  
    return(list(s0,s1,s2,s3,s4))
}


rangeest <- function(age_sub,order_sub,measure,title,xlabl){

    formod <- datcollapse(age_sub, order_sub,1,orig)
    drops <- c("close15","close30","close45","road15","road30","road45",
 							 "time15","time30","time45")
    formod[,!(names(formod) %in% drops)]
    
    xrange <- glm(cbind(successes,failures) ~ factor(dom_comuna)          + 
                  factor(dom_comuna):trend + factor(year) + factor(pill)  +
                  factor(party) + factor(mujer) + votes + outofschool     + 
                  educationspend + educationmunicip + healthspend         + 
                  healthtraining + healthstaff + femalepoverty + condom   +
                  femaleworkers, family="binomial",data=formod)
    pillline  <- grepl("pill",rownames(summary(xrange)$coefficients))
    closeline <- grepl("closemarg",rownames(summary(xrange)$coefficients))  
    pillbeta  <- summary(xrange)$coefficients[pillline,]["Estimate"]
    pillse    <- summary(xrange)$coefficients[pillline,]["Std. Error"]
    closebeta <- summary(xrange)$coefficients[closeline,]["Estimate"]
    closese   <- summary(xrange)$coefficients[closeline,]["Std. Error"]
    distance  <- 0
    
    for(i in seq(2.5,45,2.5)) {
        cat(i,"\n")
        dat <- orig
        dat <- dat[dat$age %in% age_sub,]
        dat <- dat[(dat$order %in% order_sub) | !(dat$pregnant),]  
		    dat$popln <- ave(dat$n,dat$dom_comuna,dat$year,FUN=sum)
        n1  <- names(dat)
        dat <- closegen(0,i,dat)
        dat <- closegen(i,i+2.5,dat)
        
        dat$failures  <- (1-dat$pregnant)*dat$n
        dat$successes <- dat$pregnant*dat$n    
        names(dat) <- c(n1,"c1","c2","r1","r2","t1","t2","failures","successes")  

				if(measure=="dist") { 
					formod <- aggregate.data.frame(dat[,c("failures","successes")],
                    by=list(dat$c1,dat$c2,dat$dom_comuna,dat$year-2005         ,
		 									 (dat$year-2005)^2,dat$pill,dat$mujer,dat$party,dat$votop,
											 dat$outofschool,dat$healthspend,dat$healthstaff         ,
											 dat$healthtraining,dat$educationspend,dat$femalepoverty ,
											 dat$urbBin,dat$year,dat$educationmunicip,dat$condom     ,
										   dat$usingcont,dat$femaleworkers,dat$region,dat$popln),
														function(vec) {sum(na.omit(vec))})
				}
				if(measure=="road") { 
					formod <- aggregate.data.frame(dat[,c("failures","successes")],
                    by=list(dat$r1,dat$r2,dat$dom_comuna,dat$year-2005         ,
		 									 (dat$year-2005)^2,dat$pill,dat$mujer,dat$party,dat$votop,
											 dat$outofschool,dat$healthspend,dat$healthstaff         ,
											 dat$healthtraining,dat$educationspend,dat$femalepoverty ,
											 dat$urbBin,dat$year,dat$educationmunicip,dat$condom     ,
										   dat$usingcont,dat$femaleworkers,dat$region,dat$popln),
														function(vec) {sum(na.omit(vec))})
				}
				if(measure=="time") {
					formod <- aggregate.data.frame(dat[,c("failures","successes")],
                    by=list(dat$t1,dat$t2,dat$dom_comuna,dat$year-2005         ,
		 									 (dat$year-2005)^2,dat$pill,dat$mujer,dat$party,dat$votop,
											 dat$outofschool,dat$healthspend,dat$healthstaff         ,
											 dat$healthtraining,dat$educationspend,dat$femalepoverty ,
											 dat$urbBin,dat$year,dat$educationmunicip,dat$condom     ,
										   dat$usingcont,dat$femaleworkers,dat$region,dat$popln),
														function(vec) {sum(na.omit(vec))})
				}
        names(formod) <- c("close1","closemarg",Names,"failures","successes")
        
        xrange <- glm(cbind(successes,failures) ~ factor(dom_comuna)          + 
                      factor(dom_comuna):trend + factor(year)  + factor(pill) + 
                      factor(party) + factor(mujer) + votes + outofschool     + 
                      educationspend + educationmunicip + healthspend         + 
                      healthtraining + healthstaff + femalepoverty + condom   + 
                      femaleworkers + factor(close1) + factor(closemarg),
                      family="binomial",data=formod)
        pline     <- grepl("pill",rownames(summary(xrange)$coefficients))
        cline     <- grepl("closemarg",rownames(summary(xrange)$coefficients))  
        pillbeta  <- c(pillbeta,summary(xrange)$coefficients[pline,]["Estimate"])
        pillse    <- c(pillse,summary(xrange)$coefficients[pline,]["Std. Error"])
        closebeta <- c(closebeta,summary(xrange)$coefficients[cline,]["Estimate"])
        closese   <- c(closese,summary(xrange)$coefficients[cline,]["Std. Error"])
        distance  <- c(distance, i)  
    }

    postscript(paste(graf.dir,title,sep=""),horizontal = FALSE, 
							 onefile = FALSE, paper = "special",height=7, width=9)
	  plot(distance,pillbeta, type="b",ylim=c(-0.10,-0.02),lwd=2,pch=20,
         col="darkgreen", ylab="Estimate of Effect on Treated Cluster",
				 xlab=xlabl)
    points(distance,pillbeta-1.96*pillse,type="l",lty=3,pch=20)
    points(distance,pillbeta+1.96*pillse,type="l",lty=3,pch=20)
    legend("topright",legend=c("Point Estimate","95% CI"),
           text.col=c("darkgreen","black"),pch=c(20,NA),lty=c(1,3),
           col=c("darkgreen","black"))
    dev.off()

    
    return(data.frame(distance,pillbeta,pillse,closebeta,closese))
}

event <- function(age_sub,order_sub) {
    formod <- datcollapse(age_sub,order_sub,1,orig)
    formod <- formod[with(formod,order(dom_comuna,trend)), ]
		formod$closeagg = formod$close10 + formod$close20 + formod$close30

    formod$pillbinary <- ave(formod$pill,formod$dom_comuna,FUN=sum)
    formod$treatCom[formod$pillbinary>0]  <- 1
    formod$treatCom[formod$pillbinary==0] <- 0
    formod$pilltotal <- ave(formod$pill,formod$dom_comuna,FUN=cumsum)

    formod$nopill <- 0
    formod$nopill[formod$pilltotal==0] <- 1
    formod           <- formod[with(formod,order(dom_comuna,trend,decreasing=T)), ]
    formod$add       <- ave(formod$nopill,formod$dom_comuna,FUN=cumsum)

    formod <- formod[with(formod,order(dom_comuna,trend)), ]
    formod$closebinary <- ave(formod$closeagg,formod$dom_comuna,FUN=sum)
    formod$closeCom[formod$closebinary>0]  <- 1
    formod$closeCom[formod$closebinary==0] <- 0
    formod$closetotal <- ave(formod$closeagg,formod$dom_comuna,FUN=cumsum)

    formod$noclose <- 0
    formod$noclose[formod$closetotal==0] <- 1
    formod           <- formod[with(formod,order(dom_comuna,trend,decreasing=T)), ]
    formod$addC      <- ave(formod$noclose,formod$dom_comuna,FUN=cumsum)

    formod$pilln5[formod$add==5 & formod$treatCom==1]   <- 1
    formod$pilln5[is.na(formod$pilln5)]                 <- 0
    formod$pilln4[formod$add==4 & formod$treatCom==1]   <- 1
    formod$pilln4[is.na(formod$pilln4)]                 <- 0
    formod$pilln3[formod$add==3 & formod$treatCom==1]   <- 1
    formod$pilln3[is.na(formod$pilln3)]                 <- 0
    formod$pilln2[formod$add==2 & formod$treatCom==1]   <- 1
    formod$pilln2[is.na(formod$pilln2)]                 <- 0
    formod$pilln1[formod$add==1 & formod$treatCom==1]   <- 1
    formod$pilln1[is.na(formod$pilln1)]                 <- 0
    formod$pillp0[formod$pill==1 & formod$pilltotal==1] <- 1
    formod$pillp0[is.na(formod$pillp0)]                 <- 0
    formod$pillp1[formod$pill==1 & formod$pilltotal==2] <- 1
    formod$pillp1[is.na(formod$pillp1)]                 <- 0
    formod$pillp2[formod$pill==1 & formod$pilltotal==3] <- 1
    formod$pillp2[is.na(formod$pillp2)]                 <- 0

    formod$closen5[formod$addC==5 & formod$closeCom==1]   <- 1
    formod$closen5[is.na(formod$closen5)]                 <- 0
    formod$closen4[formod$addC==4 & formod$closeCom==1]   <- 1
    formod$closen4[is.na(formod$closen4)]                 <- 0
    formod$closen3[formod$addC==3 & formod$closeCom==1]   <- 1
    formod$closen3[is.na(formod$closen3)]                 <- 0
    formod$closen2[formod$addC==2 & formod$closeCom==1]   <- 1
    formod$closen2[is.na(formod$closen2)]                 <- 0
    formod$closen1[formod$addC==1 & formod$closeCom==1]   <- 1
    formod$closen1[is.na(formod$closen1)]                 <- 0
    formod$closep0[formod$closeagg==1 & formod$closetotal==1] <- 1
    formod$closep0[is.na(formod$closep0)]                     <- 0
    formod$closep1[formod$closeagg==1 & formod$closetotal==2] <- 1
    formod$closep1[is.na(formod$closep1)]                     <- 0
    formod$closep2[formod$closeagg==1 & formod$closetotal==3] <- 1
    formod$closep2[is.na(formod$closep2)]                     <- 0


    eventS  <- glm(cbind(successes,failures) ~ factor(year)                      +
                   factor(dom_comuna) + factor(dom_comuna):trend + votes         +
                   factor(party) + factor(mujer) + outofschool + educationspend  +
                   educationmunicip + healthspend + healthtraining + healthstaff +
                   femalepoverty + femaleworkers + condom + factor(pilln5)       +
                   factor(pilln4) + factor(pilln2) + factor(pilln1)              +
                   factor(pillp0) + factor(pillp1) + factor(pillp2)              +
                   factor(closen5) + factor(closen4) + factor(closen2)           +
                   factor(closen1) + factor(closep0) + factor(closep1)           +
                   factor(closep2),
                   family="binomial", data=formod)
    clusters <-mapply(paste,"dom_comuna.",formod$dom_comuna,sep="")
    eventS$coefficients2 <- robust.se(eventS,clusters)[[2]]


    pillline <- grepl("pill",rownames(summary(eventS)$coefficients))
    beta <- summary(eventS)$coefficients[pillline,][, "Estimate"]
    se   <- eventS$coefficients2[pillline,][, "Std. Error"]

    closeline <- grepl("close",rownames(summary(eventS)$coefficients))
    Cbeta <- summary(eventS)$coefficients[closeline,][, "Estimate"]
    Cse   <- eventS$coefficients2[closeline,][, "Std. Error"]
    
    return(list("bP" = beta, "sP" = se, "bC" = Cbeta, "sC" = Cse,
                "eventyr" = c(-5,-4,-2,-1,0,1,2)))
}


#==============================================================================
#=== (6) Run estimates
#==============================================================================
c1519 <- spillovers(age_sub = 15:19, order_sub = 1:100)
c2034 <- spillovers(age_sub = 20:34, order_sub = 1:100)
c3549 <- spillovers(age_sub = 35:49, order_sub = 1:100)
cAll  <- spillovers(age_sub = 15:49, order_sub = 1:100)

#==============================================================================
#=== (7) Export results
#==============================================================================
caption <- 'Treatment Effects and Spillovers: Chile'
xvar    <- 'Treatment&'
xv1     <- 'Close 1&'
xv2     <- 'Close 2&'
xv3     <- 'Close 3&'
xv4     <- 'Close 4&'


p    <- c1519[[1]]
c1   <- c1519[[2]]
c2   <- c1519[[3]]
c3   <- c1519[[4]]
c4   <- c1519[[5]]
sp   <- '\\\\'
a    <- '&'
obs  <- 'Mean&'
R2   <- 'Regions$\\times$ Time&'
rD   <- orig[orig$age %in% 15:19,]
rate <- round(sum(rD$n[rD$pregnant==1])/
             (sum(rD$n[rD$pregnant==0])+sum(rD$n[rD$pregnant==1])),3)

to <-file(paste(tab.dir,"spill1519Chile.tex", sep=""))
writeLines(
    c('\\begin{table}[htpb!]',
      paste('\\caption{', caption, ' (15-19 year olds)}',sep=""),
      '\\vspace{-2mm}',
      '\\label{Stab:spill1519}',
      '\\begin{center}',
      '\\begin{tabular}{lccccc} \\toprule',
      '&Pr(Birth)&Pr(Birth)&Pr(Birth)&Pr(Birth)&Pr(Birth)\\\\',
      '&(1)&(2)&(3)&(4)&(5)\\\\ \\midrule',
      '&&&&& \\\\',
      paste(xvar,p$b[1],a,c1$b[1],a,c2$b[1],a,c3$b[1],a,c4$b[1],sp,sep=""),
      paste(a   ,p$s[1],a,c1$s[1],a,c2$s[1],a,c3$s[1],a,c4$s[1],sp,sep=""),
      paste(xv1        ,a,c1$b[2],a,c2$b[2],a,c3$b[2],a,c4$b[2],sp,sep=""),
      paste(a          ,a,c1$s[2],a,c2$s[2],a,c3$s[2],a,c4$s[2],sp,sep=""),
      paste(xv2        ,a        ,a,c2$b[3],a,c3$b[3],a,c4$b[3],sp,sep=""),
      paste(a          ,a        ,a,c2$s[3],a,c3$s[3],a,c4$s[3],sp,sep=""),
      paste(xv3        ,a        ,a        ,a,c3$b[4],a,c4$b[4],sp,sep=""),
      paste(a          ,a        ,a        ,a,c3$s[4],a,c4$s[4],sp,sep=""),
      paste(xv4        ,a        ,a        ,a        ,a,c4$b[5],sp,sep=""),
      paste(a          ,a        ,a        ,a        ,a,c4$s[5],sp,sep=""),
      '& & & & & \\\\',
      paste(obs,rate,a,rate,a,rate,a,rate,a,rate,sp,sep=""),
      paste(R2,'1,929&1,929&1,929&1,929&1,929\\\\ \\midrule',sep=""),
      '\\multicolumn{6}{p{12.4cm}}{\\begin{footnotesize}\\textsc{Notes}:     ',
      'Each column represents a separate difference-in-differences regression',
      ' including full time and municipal fixed effects and linear trends by ',
      'municipality. Standard errors are clustered at the level of the       ',
      'geographic region of treatment (municipality). Close variables are    ',
      'included in bins of 10km, so Close 1 refers to distances of [0,10)km, ',
      'Close 2 refers to [10,20)km, and so forth. Models are estimated using ',
      'a binary (logit) model for birth versus no birth. Coefficients are    ',
      'expressed as log odds.\\end{footnotesize}}\\\\',
      '\\bottomrule\\end{tabular}\\end{center}\\end{table}'),
    to)
close(to)


p    <- c2034[[1]]
c1   <- c2034[[2]]
c2   <- c2034[[3]]
c3   <- c2034[[4]]
rD   <- orig[orig$age %in% 20:34,]
rate <- round(sum(rD$n[rD$pregnant==1])/
             (sum(rD$n[rD$pregnant==0])+sum(rD$n[rD$pregnant==1])),3)

to <-file(paste(tab.dir,"spill2034Chile.tex", sep=""))
writeLines(
    c('\\begin{table}[htpb!]',
      paste('\\caption{', caption, ' (20-34 year olds)}',sep=""),
      '\\vspace{-2mm}',
      '\\label{Stab:spill2034}',
      '\\begin{center}',
      '\\begin{tabular}{lcccc} \\toprule',
      '&Pr(Birth)&Pr(Birth)&Pr(Birth)&Pr(Birth)\\\\',
      '&(1)&(2)&(3)&(4)\\\\ \\midrule',
      '&&&& \\\\',
      paste(xvar,p$b[1],a,c1$b[1],a,c2$b[1],a,c3$b[1],sp,sep=""),
      paste(a   ,p$s[1],a,c1$s[1],a,c2$s[1],a,c3$s[1],sp,sep=""),
      paste(xv1        ,a,c1$b[2],a,c2$b[2],a,c3$b[2],sp,sep=""),
      paste(a          ,a,c1$s[2],a,c2$s[2],a,c3$s[2],sp,sep=""),
      paste(xv2        ,a        ,a,c2$b[3],a,c3$b[3],sp,sep=""),
      paste(a          ,a        ,a,c2$s[3],a,c3$s[3],sp,sep=""),
      paste(xv3        ,a        ,a        ,a,c3$b[4],sp,sep=""),
      paste(a          ,a        ,a        ,a,c3$s[4],sp,sep=""),
      '& & & & \\\\',
      paste(obs,rate,a,rate,a,rate,a,rate,sp,sep=""),
      paste(R2,'1,929&1,929&1,929&1,929\\\\ \\midrule',sep=""),
      '\\multicolumn{5}{p{10.2cm}}{\\begin{footnotesize}\\textsc{Notes}:     ',
      'Refer to notes in table \\ref{Stab:spill1519}.\\end{footnotesize}}\\\\',
      '\\bottomrule\\end{tabular}\\end{center}\\end{table}'),
    to)
close(to)


p    <- c3549[[1]]
c1   <- c3549[[2]]
rD   <- orig[orig$age %in% 35:49,]
rate <- round(sum(rD$n[rD$pregnant==1])/
             (sum(rD$n[rD$pregnant==0])+sum(rD$n[rD$pregnant==1])),3)

to <-file(paste(tab.dir,"spill3549Chile.tex", sep=""))
writeLines(
    c('\\begin{table}[htpb!]',
      paste('\\caption{', caption, ' (35-49 year olds)}',sep=""),
      '\\vspace{-2mm}',
      '\\label{Stab:spill3549}',
      '\\begin{center}',
      '\\begin{tabular}{lcc} \\toprule',
      '&Pr(Birth)&Pr(Birth)\\\\',
      '&(1)&(2)\\\\ \\midrule',
      '&& \\\\',
      paste(xvar,p$b[1],a,c1$b[1],sp,sep=""),
      paste(a   ,p$s[1],a,c1$s[1],sp,sep=""),
      paste(xv1        ,a,c1$b[2],sp,sep=""),
      paste(a          ,a,c1$s[2],sp,sep=""),
      '& & \\\\',
      paste(obs,rate,a,rate,sp,sep=""),
      paste(R2,'1,929&1,929\\\\ \\midrule',sep=""),
      '\\multicolumn{3}{p{5.2cm}}{\\begin{footnotesize}\\textsc{Notes}:     ',
      'Refer to notes in table \\ref{Stab:spill1519}.\\end{footnotesize}}\\\\',
      '\\bottomrule\\end{tabular}\\end{center}\\end{table}'),
    to)
close(to)

#==============================================================================
#=== (8) Event studies
#==============================================================================
e1 <- event(age_sub = 15:19, order_sub = 1:100)
e2 <- event(age_sub = 20:34, order_sub = 1:100)


postscript(paste(graf.dir,"Event1519treat.eps",sep=""),
           horizontal = FALSE, onefile = FALSE, paper = "special",
           height=7, width=9)

plotCI(e1$eventyr,e1$bP,ui=e1$bP+1.96*e1$sP,li=e1$bP-1.96*e1$sP,
       ylim=c(-0.3,0.10), ylab="Estimate", xlab="Event Year",
       cex.lab=1.25, cex.axis=1.25, cex.main=1.25, cex.sub=1.25)

points(e1$eventyr,e1$bP,type="l",lwd=2,pch=20)
abline(h =  0  , lwd=1, col="gray60", lty = 2)
abline(v = -0.1, lwd=2, col="red")
dev.off()

postscript(paste(graf.dir,"Event1519close.eps",sep=""),
           horizontal = FALSE, onefile = FALSE, paper = "special",
           height=7, width=9)

plotCI(e1$eventyr,e1$bC,ui=e1$bC+1.96*e1$sC,li=e1$bC-1.96*e1$sC,
       ylim=c(-0.3,0.10), ylab="Estimate", xlab="Event Year",
       cex.lab=1.25, cex.axis=1.25, cex.main=1.25, cex.sub=1.25)

points(e1$eventyr,e1$bC,type="l",lwd=2,pch=20)
abline(h =  0  , lwd=1, col="gray60", lty = 2)
abline(v = -0.1, lwd=2, col="red")
dev.off()
