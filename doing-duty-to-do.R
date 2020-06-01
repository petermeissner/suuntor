# script for extracting data from suunto watch for storage and use at hompage

# packages
library(XML)
library(data.table)
library(dplyr)
library(jsonlite)
library(stringr)
library(lubridate)


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


# analytics data
df <-
  data_df_all %>%
  select(
    Activity,
    ActivityType,
    Distance,
    Duration,
    Energy,
    DateTime
  ) %>%
  filter(
    ActivityType == 3
  ) %>%
  mutate(
    duration_min = round(as.numeric(as.character(Duration)) / 60, 2),
    date         = as.Date(substring(DateTime, 1,10)),
    kj           = round(as.numeric(as.character(Energy))/1000),
    kcal         = round(as.numeric(as.character(Energy))/4184),
    distance     = round(as.numeric(as.character(Distance))/1000, 2),
    kmh          = round(distance / (duration_min / 60), 2),
    mkm          =
      paste0(
        floor(duration_min / distance),
        ":",
        str_pad(ceiling(((duration_min/distance) %% 1) * 60), width = 2, side = "left", pad = "0")
      ),
    year = year(date),
    week = week(date)
  )  %>%
  select(
    date,
    distance,
    duration_min,
    kmh,
    mkm,
    kj,
    kcal,
    year,
    week
  ) %>%
  group_by(year, week) %>%
  mutate(
    dist_weekly = sum(distance),
    kcal_weekly = sum(kcal)
  ) %>%
  ungroup() %>%
  as.data.frame()%>%
  arrange(
    -as.integer(date)
  )

writeLines(
  toJSON(
    x      = list(run_data = df),
    pretty = TRUE
  ),
  "./data/suunto_data_analytics.json"
)


# add everything to repo
try({
  system("git add *")
  system("git status")
  system(paste0("git commit -m ", '"update ',as.character(Sys.time()),'"'))
  system("git push")
})















