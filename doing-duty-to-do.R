# script for extracting data from suunto watch for storage and use at hompage

# packages
library(XML)
library(data.table)
library(dplyr)
library(jsonlite)


# functions
get_data <- function(xml){
  tmp <- xpathApply(xml, "//*[local-name() = 'Header']", xmlToList)[[1]]
  tmp <- as.data.frame(t(unlist(tmp)))
  return(tmp)
}


# data extraction
files <- dir(path.expand("~/AppData/Roaming/Suunto/Moveslink2"), pattern="sml", full.names = TRUE)

# storing raw in data path
dir.create("data", showWarnings = FALSE)
file.copy(files, "./data")



# parsing data
XML     <- lapply(files, xmlParse)
DATA    <- lapply(XML, get_data)
data_df <- rbindlist(DATA, fill=TRUE)



# loading already stored data
if( file.exists("suunto_data.Rdata") ){
  load("suunto_data.Rdata")
}else{
  data_df_all <- data.frame()
}


# combining both data sources
data_df_all <- unique(rbind(data_df, data_df_all))
save(data_df_all, file="suunto_data.Rdata")


# write to json
writeLines(
  toJSON(
    x      = list(run_data = data_df_all),
    pretty = TRUE
  ),
  "./data/suunto_data.json"
)



















