# script for extracting data from suunto watch for storage and use at hompage

# packages
library(XML)
library(magrittr)
library(jsonlite)
library(rChartsCalmap) # devtools::install.packages('htmlwidgets'); devtools::install_github("ramnathv/rChartsCalmap");
library(hellno)



# data extraction
files <- dir(path.expand("~/AppData/Roaming/Suunto/Moveslink2"), pattern="sml", full.names = TRUE)

XML <- lapply(files, xmlParse)

get_data <- function(xml){
  tmp <- xpathApply(xml, "//*[local-name() = 'Header']", xmlToList)[[1]]
  tmp <- as.data.frame(t(unlist(tmp)))
  return(tmp)
}

DATA <- lapply(XML, get_data)
data_df <- do.call(rbind, DATA)



# loading already stored data
if( file.exists("suunto_data.Rdata") ){
  load("suunto_data.Rdata")
}else{
  data_df_all <- data.frame()
}


# combining both data sources
data_df_all <- unique(rbind(data_df, data_df_all))
save(data_df_all, file="suunto_data.Rdata")


# add data to homepage
writeLines(toJSON(data_df_all), "~/Dropbox/petermeissner.github.io/data/suunto_data.json")


# doing calender
calheatmap(
  x = "date",
  y = "Km",
  data = data.frame(
    Km   = as.numeric(data_df_all$Distance)/1000,
    date = substring(data_df_all$DateTime, 1, 10)
  ),
  domain = 'month',
  legend = seq(0, 20, 5),
  start = as.character(Sys.Date()-330),
  itemName = 'Km'
)


# updating homepage
wd <- getwd()
source("C:/Users/peter/Dropbox/petermeissner.github.io/_make_pages.Rexec")
setwd(wd)





















