# |  (C) 2008-2018 Potsdam Institute for Climate Impact Research (PIK),
# |  authors, and contributors see AUTHORS file
# |  This file is part of MAgPIE and licensed under GNU AGPL Version 3
# |  or later. See LICENSE file or go to http://www.gnu.org/licenses/
# |  Contact: magpie@pik-potsdam.de

##########################################################
#### MAgPIE output generation ####
##########################################################

library(lucode)

runOutputs <- function(runscripts=NULL, submit=NULL) {

  get_line <- function(){
    # gets characters (line) from the terminal or from a connection
    # and returns it
    if(interactive()){
      s <- readline()
    } else {
      con <- file("stdin")
      s <- readLines(con, 1, warn=FALSE)
      on.exit(close(con))
    }
    return(s);
  }


  choose_module <- function(Rfolder,title="Please choose an outputmodule") {
    forder <- paste0(Rfolder,"/order.cfg")
    if(file.exists(forder)) {
      order <- grep("(#|^$)",readLines(forder),invert=TRUE,value=TRUE)
      if(length(order)==0) order <- NULL
    } else {
      order <- NULL
    }
    module <- gsub("\\.R$","",grep("\\.R$",list.files(Rfolder), value=TRUE))
    #sort modules based on order.cfg
    module <- intersect(union(order,module),module)
    cat("\n",title,":\n", sep="")
    cat(paste(1: length(module), gsub("_"," ",module,fixed=TRUE), sep=": " ),sep="\n")
    cat("Number: ")
    identifier <- get_line()
    identifier <- as.numeric(strsplit(identifier,",")[[1]])
    if (any(!(identifier %in% 1:length(module)))) stop("This choice (",identifier,") is not possible. Please type in a number between 1 and ",length(module))
    return(module[identifier])
  }

  choose_submit <- function(title="Please choose run submission type") {
    slurm <- suppressWarnings(ifelse(system2("srun",stdout=FALSE,stderr=FALSE) != 127, TRUE, FALSE))
    modes <- c("Direct execution",
               "Background execution",
               "SLURM submission",
               "SLURM submission (16GB memory)",
               "SLURM submission (32GB memory)",
               "SLURM submission (medium)",
               "SLURM submission (16GB memory, medium)",
               "SLURM submission (32GB memory, medium)",
               "Debug mode")
    if(!slurm) modes <- modes[-3:-8]
    cat("\n",title,":\n", sep="")
    cat(paste(1:length(modes), modes, sep=": " ),sep="\n")
    cat("Number: ")
    identifier <- get_line()
    identifier <- as.numeric(strsplit(identifier,",")[[1]])
    if(slurm) {
      comp <- switch(identifier,
                     "1" = "direct",
                     "2" = "background",
                     "3" = "slurm",
                     "4" = "slurm16gb",
                     "5" = "slurm32gb",
                     "6" = "slurmmedium",
                     "7" = "slurm16gbmedium",
                     "8" = "slurm32gbmedium",
                     "9" = "debug")
    } else {
      comp <- switch(identifier,
                     "1" = "direct",
                     "2" = "background",
                     "3" = "debug")
    }
    if(is.null(comp)) stop("This type is invalid. Please choose a valid type")
    return(comp)
  }

  runsubmit <- function(runscripts, submit) {
    for(rout in runscripts){
      name   <- paste0("./scripts/start/",rout,".R")

      if(!file.exists(name)) {
        warning("Script ",name, " could not be found. Skip execution!")
        next
      }

      cat("Executing",name,"\n")
      srun_command <- paste0("srun --job-name=",rout," --output=",rout,"-%j.out --mail-type=END")
      if(submit=="direct") {
        tmp.env <- new.env()
        tmp.error <- try(sys.source(name,envir=tmp.env))
        if(!is.null(tmp.error)) warning("Script ",name," was stopped by an error and not executed properly!")
        rm(tmp.env)
      } else if(submit=="background") {
        log <- format(Sys.time(), paste0(rout,"-%Y-%H-%M-%S-%OS3.log"))
        system2("Rscript",name, stderr = log, stdout = log, wait=FALSE)
      } else if(submit=="slurm") {
        system(paste0(srun_command," --qos=short Rscript ",name), wait=FALSE)
        Sys.sleep(1)
      } else if(submit=="slurm16gb") {
        system(paste0(srun_command," --qos=short --mem-per-cpu=16000 Rscript ",name), wait=FALSE)
        Sys.sleep(1)
      } else if(submit=="slurm32gb") {
        system(paste0(srun_command," --qos=short --mem-per-cpu=32000 Rscript ",name), wait=FALSE)
        Sys.sleep(1)
      } else if(submit=="slurmmedium") {
        system(paste0(srun_command," --qos=medium Rscript ",name), wait=FALSE)
        Sys.sleep(1)
      } else if(submit=="slurm16gbmedium") {
        system(paste0(srun_command," --qos=medium --mem-per-cpu=16000 Rscript ",name), wait=FALSE)
        Sys.sleep(1)
      } else if(submit=="slurm32gbmedium") {
        system(paste0(srun_command," --qos=medium --mem-per-cpu=32000 Rscript ",name), wait=FALSE)
        Sys.sleep(1)
      } else if(submit=="debug") {
        tmp.env <- new.env()
        sys.source(name,envir=tmp.env)
        rm(tmp.env)
      } else {
        stop("Unknown submission type")
      }
    }
  }



  if(is.null(runscripts)) runscripts <- choose_module("./scripts/start",
                                                      "Choose start script")
  if(is.null(submit))     submit     <- choose_submit("Choose submission type")

  runsubmit(runscripts, submit)
}


runscripts <- submit <- NULL
readArgs("runscripts","submit", .silent=TRUE)
runOutputs(runscripts=runscripts, submit=submit)
