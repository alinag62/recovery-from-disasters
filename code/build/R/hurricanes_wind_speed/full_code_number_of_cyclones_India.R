##---------------------------------------------------
## This is R code for creatind maximum wind speeds     
## from tropical cyclones on ADM2 level                   
## Author: Alina Gafanova                 
##---------------------------------------------------
rm(list=ls())

# load packages

library(prob)
library(dplyr)
library(tidyr)
library(ggplot2)
library(geosphere)
library(tidyverse)
library(readr)
library(raster)
library(sf)
library(exactextractr)
library(lubridate)
library(collapse)
library(terra)

#--------------------------------------------------#
# 0. Set data paths and several variables manually
#--------------------------------------------------#

path = "/Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters/"

#years for start and finish of the analysis (the same as hurricane data file)
year_min = 1975
year_max = 2011

#path to shape files of the country on 2 levels
ADM2_path = paste(path, "data/firm-data/India/Shapefile/IND_adm_shp/IND_adm2.shp", sep="")
ADM0_path = paste(path, "data/firm-data/India/Shapefile/IND_adm_shp/IND_adm0.shp", sep="")

#unique geographical ID in ADM2 shape file 
ID_2 = "ID_2"

#path to a 0.1x0.1deg grid for a country and its 200km buffer (created in QGIS): vector
grid_vect_path = paste(path, "data/tropical-cyclones/intermediate/India/grid_0p1deg.shp", sep="")

#path to a 0.1x0.1deg grid for a country and its 200km buffer (created in QGIS): raster
grid_rast_path = paste(path, "./data/tropical-cyclones/intermediate/India/grid_0p1deg.tif", sep="")

#path to country-specific hurricane data: shape file of hurricanes' eyes in 200km buffer (created in QGIS)
hurr_path = paste(path, "data/tropical-cyclones/intermediate/India/subset_1975_2011_200km.shp", sep="")

#path to individual storm files and main hurricane folder for the country
hurr_ind_storms = paste(path, "data/tropical-cyclones/intermediate/India/csvs", sep="")
hurr_country_storms = paste(path, "data/tropical-cyclones/intermediate/India", sep="")

##########################
#NO MANUAL CHANGES BELOW
##########################

#path to all hurricane data
hurr_all_path = paste(path, "data/tropical-cyclones/raw/IBTrACS-points/IBTrACS.ALL.list.v04r00.points.shp", sep="")

#path to a main folder with various gpw population data 
gpw_pop_main_path = paste(path, "data/population/intermediate/global_annual_gpw", sep="")

#--------------------------------------------------#
# 1. Load and clean data
#--------------------------------------------------#

setwd(path)

#load shape files 
ADM2 <- st_read(ADM2_path)
ADM2 <- subset(ADM2, select=c(ID_2))
ADM0 <- st_read(ADM0_path)

#load hurricane data and get unique hurricane IDs
hurr <- st_read(hurr_path)
crs <- st_crs(hurr)
hurr_unique <- unique(hurr$SID)

#load all hurricanes and subset by unique IDs for that country (to get full data on locations)
hurr_all <- st_read(hurr_all_path)
hurr_subset_by_id <- hurr_all[hurr_all$SID %in% hurr_unique,]

#clean hurr_subset_by_id
hurr_subset_by_id$ISO_TIME <- ISOdate(hurr_subset_by_id$year, hurr_subset_by_id$month, hurr_subset_by_id$day, hurr_subset_by_id$hour, hurr_subset_by_id$min)
hurr_subset_by_id <- subset(hurr_subset_by_id, TRACK_TYPE == "main")
hurr_subset_by_id$V_m <- hurr_subset_by_id$USA_WIND
names(hurr_subset_by_id)[names(hurr_subset_by_id) == "STORM_SPD"] <- "V_h"
hurr_subset_by_id <- st_drop_geometry(subset(hurr_subset_by_id, select=c("SID", "ISO_TIME","LON","LAT","V_m","V_h")))
#rm(hurr_all)

#load grids in a vector format (two of the same grids: I need to modify it but I need to use it later)
grid <- st_read(grid_vect_path)
grid <- st_transform(grid, crs = crs)
grid2 <- st_read(grid_vect_path)
grid2 <- st_transform(grid2, crs = crs) 

#load grid in a raster format
gridRaster <- raster(grid_rast_path)

#--------------------------------------------------#
# 2. Setting models' parameters
#--------------------------------------------------#

#fixed in a model
S <- 1 
F_land <- 0.8
F_water <- 1

#arbitrary choice from possible scenarios (can be modified!)
B <- 1.3
R_m <- 60000

#-----------------------------------------------------#
# 3. Clean (and re-scale) data on sustained wind speeds
#-----------------------------------------------------#

#exclude spurs
hurr <- subset(hurr, TRACK_TYPE == "main")

#check if all the US data is from JTWC source 
#NA: means that the data was interpolated by IBTrACS from 6 to 3 hours
stopifnot(unique(hurr$USA_AGENCY) %in% c("jtwc_io", "jtwc_wp","jtwc_ep","jtwc_cp","jtwc_sh", NA ))

#only keep JTWC (US) agency data (main method)
hurr$V_m <- hurr$USA_WIND

#rename translation speed
names(hurr)[names(hurr) == "STORM_SPD"] <- "V_h"

#only save a subset of columns that we will use from now on
hurr <- hurr[c("SID","DIST2LAND","NATURE", "LAT", "LON", "V_m", "V_h", "USA_PRES","year","month","day","hour","min", "geometry")]

#--------------------------------------------------#
# 4. Add locations from points outside the buffer
#--------------------------------------------------#

#sort hurricane subset by id and time
hurr <- hurr[with(hurr, order(SID, year, month, day, hour, min)),]
hurr$ISO_TIME <- ISOdate(hurr$year, hurr$month, hurr$day, hurr$hour, hurr$min)
hurr_subset_by_id <- hurr_subset_by_id[with(hurr_subset_by_id, order(SID, ISO_TIME)),]

#drop observations that are not full hours (No observations like this in Vietnam Data)
hurr <- subset(hurr, min==0)

#drop storms with no reported winds at all
hurr <- hurr %>% 
  group_by(SID) %>% 
  mutate(sum_winds = sum(V_m, na.rm = TRUE)) %>% 
  ungroup()
hurr <- hurr[hurr$sum_winds!=0,]
hurr <- subset(hurr, select = -c(sum_winds))

#add "start" date and time
hurr <- hurr %>% 
  group_by(SID) %>% 
  mutate(start = min(ISO_TIME, na.rm = TRUE)) %>% 
  ungroup()

#add "end" date and time
hurr <- hurr %>% 
  group_by(SID) %>% 
  mutate(end = max(ISO_TIME, na.rm = TRUE)) %>% 
  ungroup()

#add a column to hurr to indicate points that are in the buffer
hurr$buff <- 1

#merge with full location dataset
hurr_subset_by_id <- merge(hurr_subset_by_id, hurr, by = c("SID", "ISO_TIME", "LAT", "LON","V_m","V_h"), all.x=TRUE)
hurr_subset_by_id[is.na(hurr_subset_by_id$buff),]$buff <- 0

#sort again by id and time (just in case)
hurr_subset_by_id <- hurr_subset_by_id[with(hurr_subset_by_id, order(SID, ISO_TIME)),]

#fill in start of the storm
hurr_subset_by_id <- hurr_subset_by_id %>% 
  group_by(SID) %>% 
  fill(start, .direction = "updown") %>% 
  ungroup()

#fill in end of the storm
hurr_subset_by_id <- hurr_subset_by_id %>% 
  group_by(SID) %>% 
  fill(end, .direction = "updown") %>% 
  ungroup()

#drop all observations that are before the first buffer observation
hurr_subset_by_id <- hurr_subset_by_id %>% filter(ISO_TIME>=start)

#drop all observations that are later than t+1 after the last buffer observation
hurr_subset_by_id <- hurr_subset_by_id %>% filter(ISO_TIME<=end+1)

#we can replace hurr by hurr_subset_by_id 
hurr <- hurr_subset_by_id
rm(hurr_subset_by_id)
hurr <- subset(hurr, select = -c(start))

#--------------------------------------------------#
# 5. Interpolate wind data to hourly intervals
#--------------------------------------------------#

#rename ISO column
names(hurr)[names(hurr) == "ISO_TIME"] <- "ISO"

#drop storms with 1 observation only (impossible to calculate winds)
hurr <- hurr %>% add_count(SID)
hurr <- hurr[hurr$n!=1,]
hurr <- subset(hurr, select = -c(n))

#create a period ID for each storm
hurr$stormPeriod <- with(hurr, ave(rep(1, nrow(hurr)), SID, FUN = seq_along))
#count obs per ID 
hurr <- hurr %>% add_count(SID)

#calculate time difference between each observation within storm
hurr <- hurr[with(hurr, order(SID, ISO)),]
hurr$time_diff <- NA
hurr[2:nrow(hurr), ]$time_diff <- as.numeric(diff(hurr$ISO))
hurr[hurr$stormPeriod == 1,]$time_diff <- 0
hurr$lead <- lead(hurr$time_diff)
hurr[is.na(hurr$lead),]$lead <- 0

#create empty rows for hourly data
s <- rep(sequence(nrow(hurr)), hurr$lead + 1)
hurr <- hurr[s,]
hurr[duplicated(s),] <- NA
hurr <- hurr[c("SID","DIST2LAND","NATURE", "LAT", "LON", "V_m", "V_h","ISO","year","geometry","buff","USA_PRES")]

#fill in SIDs, nature of storm, year
hurr <- hurr %>% fill(SID, .direction = "down")
hurr <- hurr %>% fill(NATURE, .direction = "down")
hurr <- hurr %>% fill(year, .direction = "down")
hurr <- hurr %>% fill(buff, .direction = "down")

#fill in columns with linear interpolation: dist2land, V_m, V_h, time, USA_PRES
hurr <- hurr %>%
  group_by(SID) %>%
  mutate(interpDist = zoo::na.approx(DIST2LAND, na.rm=FALSE)) %>% 
  ungroup()
hurr$DIST2LAND <- hurr$interpDist
hurr <- subset(hurr, select = -c(interpDist))

hurr <- hurr %>%
  group_by(SID) %>%
  mutate(interpV_m = zoo::na.approx(V_m, na.rm = FALSE)) %>% 
  ungroup()
hurr$V_m <- hurr$interpV_m
hurr <- subset(hurr, select = -c(interpV_m))

hurr <- hurr %>%
  group_by(SID) %>%
  mutate(interpV_h = zoo::na.approx(V_h, na.rm = FALSE)) %>% 
  ungroup()
hurr$V_h <- hurr$interpV_h
hurr <- subset(hurr, select = -c(interpV_h))

hurr <- hurr %>%
  group_by(SID) %>%
  mutate(interpTime = zoo::na.approx(ISO, na.rm = FALSE)) %>% 
  ungroup()
hurr$ISO <- as.POSIXlt(hurr$interpTime, origin = "1970-01-01", tz="GMT")
hurr <- subset(hurr, select = -c(interpTime))

hurr <- hurr %>%
  group_by(SID) %>%
  mutate(interpPres = zoo::na.approx(USA_PRES, na.rm = FALSE)) %>% 
  ungroup()
hurr$USA_PRES <- hurr$interpPres
hurr <- subset(hurr, select = -c(interpPres))

#fill in columns with splines: position
hurr <- hurr %>%
  group_by(SID) %>%
  mutate(interpLon = zoo::na.spline(LON, na.rm = FALSE)) %>% 
  ungroup()
hurr$LON <- hurr$interpLon
hurr <- subset(hurr, select = -c(interpLon))

hurr <- hurr %>%
  group_by(SID) %>%
  mutate(interpLat = zoo::na.spline(LAT, na.rm = FALSE)) %>% 
  ungroup()
hurr$LAT <- hurr$interpLat
hurr <- subset(hurr, select = -c(interpLat))

#get "next" cyclone location row
hurr <- hurr %>%
  group_by(SID) %>%
  mutate(LON_t_plus1 = lead(LON, order_by=SID))

hurr <- hurr %>%
  group_by(SID) %>%
  mutate(LAT_t_plus1 = lead(LAT, order_by=SID))

#if missing DIST2LAND it means it's interpolated location data that we don't need anymore
#since DIST2LAND is never missing in the original data
hurr <- hurr[!is.na(hurr$DIST2LAND),]

#keep only buff==1
hurr <- hurr[hurr$buff==1,]
hurr <- subset(hurr, select = -c(buff))

#drop "last" observation since we can't calculate wind speed for it
hurr <- hurr[!is.na(hurr$LON_t_plus1),]
hurr <- hurr[!is.na(hurr$LAT_t_plus1),]

#drop sequences of missing winds (either end or beginning of the storm)
hurr <- hurr[!is.na(hurr$V_m),]

#--------------------------------------------------#
# 5. Add model parameters to the dataset
#--------------------------------------------------#

#friction parameter depends on whether eye is on land or water
hurr$F <- F_water
hurr[hurr$DIST2LAND==0,]$F <- F_land

#other parameters are universal
hurr$S <- S
hurr$B <- B
hurr$R_m <- R_m

#reset geometries (with interpolated values)
hurr <- st_as_sf(hurr, coords = c("LON", "LAT"), sf_column_name = "geometry", remove = FALSE)
hurr <- hurr %>% st_set_crs(crs)

#check if splines are good enough - plot one hurricane
#ggplot() + 
#    geom_sf(data = hurr[hurr$SID==hurr$SID[400],]["year"] , fill = NA) 

#---------------------------------------------------#
# 6. Run the main algorithm: one cyclone ID per loop
#---------------------------------------------------#

#new list of unique hurricanes (after dropping data)
hurr_unique2 <- unique(hurr$SID)

#for (i in hurr_unique2[5]){
for (i in hurr_unique2){
  print(i)
  save = data.frame()
  
  #subset with 1 hurricane
  oneHurr <- subset(hurr, SID==i)
  oneHurr <- oneHurr[with(oneHurr, order(ISO)),]
  
  #200km buffers
  oneHurr_buffers_200km <- st_buffer(oneHurr, dist=200000)
  
  #loop through the coordinates
  for (j in 1:nrow(oneHurr_buffers_200km)) {
    #for (j in 1:2) {
    oneBuffer <- st_intersection(grid, oneHurr_buffers_200km[j,])
    print(dim(oneBuffer)[1])
    if (dim(oneBuffer)[1]!=0) {
      oneBuffer$site_latitude <- oneBuffer$bottom+(oneBuffer$top-oneBuffer$bottom)/2
      oneBuffer$site_longitude <- oneBuffer$left+(oneBuffer$right-oneBuffer$left)/2
      oneBuffer <- subset(oneBuffer, select = -c(top, bottom, left, right))
      
      # Calculate radial distances
      oneBuffer$R <- distHaversine(as.matrix(st_drop_geometry(oneBuffer[,c("site_longitude","site_latitude")])), +
                                     as.matrix(st_drop_geometry(oneBuffer[,c("LON","LAT")])))
      
      # Calculate clockwise angles 
      eye <- as.matrix(st_drop_geometry(oneBuffer[,c("LON","LAT")]))
      site <- as.matrix(st_drop_geometry(oneBuffer[,c("site_longitude","site_latitude")]))
      next_eye <- as.matrix(st_drop_geometry(oneBuffer[,c("LON_t_plus1","LAT_t_plus1")]))
      
      #bearing - between eye and next position
      oneBuffer$bearing_eye_next <- bearing(eye, next_eye)
      oneBuffer$bearing_eye_next[oneBuffer$LON > oneBuffer$LON_t_plus1] <-  +
        360 + oneBuffer$bearing_eye_next[oneBuffer$LON > oneBuffer$LON_t_plus1]
      
      #bearing - between eye and point
      oneBuffer$bearing_eye_site <- bearing(site, eye)
      oneBuffer$bearing_eye_site[oneBuffer$site_longitude > oneBuffer$USA_LON] <- +
        360 + oneBuffer$bearing_eye_site[oneBuffer$site_longitude > oneBuffer$USA_LON]
      oneBuffer$T <- oneBuffer$bearing_eye_site - oneBuffer$bearing_eye_next +180
      
      # Calculate the Speeds at each point
      oneBuffer$V_s <- with(oneBuffer, F*(V_m - S* (1-sin(T* pi/180))*V_h*0.5)* +
                              ((R_m/R)^B*exp(1-(R_m/R)^B))^(0.5))*0.514444
      
      #clean and save to csv
      oneBuffer <-subset(oneBuffer, select=c("year","site_latitude","site_longitude","V_s"))
      oneBuffer <-st_drop_geometry(oneBuffer)
      save <- rbind(save, oneBuffer)
      save <- save %>% group_by(site_latitude, site_longitude, year) %>%
        summarize(V_s = max(V_s, na.rm = TRUE), .groups = 'keep')
    }
    else{
      next
    }
  }
  write.csv(save, file = paste(hurr_ind_storms,"/", i,".csv",sep=''))
}

#-----------------------------------------------------#
# 7. Create a file with max wind for each year-location
#-----------------------------------------------------#

allCSV <- list.files(path=hurr_ind_storms, full.names = TRUE) %>% 
  lapply(read_csv) %>% 
  bind_rows 

allCSV <- subset(allCSV, select = -c(...1))

#add number of cyclones based on Saffir-Simpson Scale
allCSV$storm <- 0
allCSV$one <- 0
allCSV$two <- 0
allCSV$three <- 0
allCSV$four <- 0
allCSV$five <- 0

if(sum(allCSV$V_s>17) > 0){
  allCSV[allCSV$V_s>17,]$storm <- 1
}
if(sum(allCSV$V_s>32) > 0){
  allCSV[allCSV$V_s>32,]$one <- 1
}
if(sum(allCSV$V_s>42) > 0){
  allCSV[allCSV$V_s>42,]$two <- 1
}
if(sum(allCSV$V_s>49) > 0){
  allCSV[allCSV$V_s>49,]$three <- 1
}
if(sum(allCSV$V_s>58) > 0){
  allCSV[allCSV$V_s>58,]$four <- 1
}
if(sum(allCSV$V_s>70) > 0){
  allCSV[allCSV$V_s>70,]$five <- 1
}

#take annual maximum and sum number of storms
allCSV <- allCSV %>% group_by(site_latitude, site_longitude, year) %>%
  summarize(V_s = max(V_s, na.rm = TRUE), storm = sum(storm, na.rm = TRUE), 
    one = sum(one, na.rm = TRUE), two = sum(two, na.rm = TRUE),
    three = sum(three, na.rm = TRUE), four = sum(four, na.rm = TRUE),
      five = sum(five, na.rm = TRUE), .groups = 'keep')

write.csv(allCSV, file = paste(hurr_country_storms,"/maxWinds.csv",sep=""))
rm(allCSV, save, hurr, oneHurr, oneBuffer, oneHurr_buffers_200km, eye, next_eye, site)
rm(B, G, hurr_unique, hurr_unique2, i, I, j, R_m, s, S)

#-----------------------------------------------------#
# 8. Create a full coordinate-year panel with winds
#-----------------------------------------------------#

dt <- read.csv(file = paste(hurr_country_storms,"/maxWinds.csv",sep=""))
dt <- subset(dt, select = -c(X))

years<- rep(seq(year_min,year_max), dim(grid)[1])
grid$site_latitude <- grid$bottom+(grid$top-grid$bottom)/2
grid$site_longitude <- grid$left+(grid$right-grid$left)/2
grid <- st_drop_geometry(grid)
grid <- subset(grid, select = -c(left, right, top, bottom, id))
grid$rep <- year_max - year_min + 1

m <- rep(sequence(nrow(grid)), grid$rep)
grid <- grid[m,]
grid[duplicated(m),] <- NA

#fill in data for each observation
grid$year <- years
grid <- grid %>% fill(site_latitude, .direction = "down")
grid <- grid %>% fill(site_longitude, .direction = "down")
grid <- subset(grid, select = -c(rep))

#merge to get the full panel
panel <- merge(grid, dt, by = c("site_latitude", "site_longitude", "year"), all = TRUE)
panel[is.na(panel$V_s),]$V_s <- 0
panel[panel$V_s<0,]$V_s <- 0
panel[is.na(panel$storm),]$storm <- 0
panel[is.na(panel$one),]$one <- 0
panel[is.na(panel$two),]$two <- 0
panel[is.na(panel$three),]$three <- 0
panel[is.na(panel$four),]$four <- 0
panel[is.na(panel$five),]$five <- 0

write.csv(panel, file = paste(hurr_country_storms,"/maxWinds_with0.csv",sep=""))
rm(panel, grid, dt, m, years)

#---------------------------------------------------------------#
# PLOT A FEW RASTERS AND SEE IF IT MAKES SENSE
#---------------------------------------------------------------#

# collapsed <- collap(panel, V_s ~ site_latitude + site_longitude)
# grid2$site_latitude <- grid2$bottom+(grid2$top-grid2$bottom)/2
# grid2$site_longitude <- grid2$left+(grid2$right-grid2$left)/2
# data2plot <- merge(grid2, collapsed, by = c("site_latitude", "site_longitude"))
# 
# ggplot(data2plot) +
#   geom_sf(aes(fill = V_s), color = NA) +
#   scale_fill_gradient(low = 'white', high = 'red', name = "Sustained Wind Speed (m/s)") +
#   geom_sf(data = ADM2['ID_2'], fill = NA)

#---------------------------------------------------------------#
# 9. Rescale winds from 0.1deg to 30arcsec and add pop data
#---------------------------------------------------------------#

panel <- read.csv(paste(hurr_country_storms,"/maxWinds_with0.csv",sep=""))
panel <- subset(panel, select = -c(X))
#we need X coordinate first, Y coordinate second for rasterFromXYZ
panel<-panel[,c('site_longitude','site_latitude',names(panel)[3:10])]

#loop through years
for (y in year_min:year_max) {
  
  #load grid with population data 
  pop_raster <-raster(paste(gpw_pop_main_path,
                            "/gpw-v4-population-count-", y, ".tif",sep=""))
  
  #subset winds to one year per iteration and convert to raster
  winds_raster <- rasterFromXYZ(panel[panel$year==y,], digits=1, crs = crs(pop_raster))
  
  # crop population data to country extents
  pop_raster <- terra::crop(pop_raster, winds_raster, snap="out")
  
  #downscale wind raster to population
  winds_raster <- raster::resample(winds_raster, pop_raster,method="ngb")
  
  #convert population data to dataframe
  pop_df <- as.data.frame(pop_raster, xy=TRUE, centroids=TRUE)
  rm(pop_raster)
  
  #convert wind raster to dataframe
  winds_df <- as.data.frame(winds_raster, xy=TRUE, centroids=TRUE)
  rm(winds_raster)
  
  #create a column for coordinates (faster merge)
  pop_df <-  pop_df %>%
    mutate(coord = paste0(x, y, sep=""))
  winds_df <- winds_df %>%
    mutate(coord = paste0(x, y, sep=""))
  
  #merge winds and population 
  winds_df <- subset(winds_df, select = -c(x,y))
  merged <- merge(pop_df, winds_df, by = 'coord')
  rm(pop_df, winds_df)
  
  #rename columns
  merged <- subset(merged, select = -c(coord))
  names(merged)[names(merged) == paste("gpw.v4.population.count.",y, sep="")] <- "pop"
  
  #drop NA values (I accidentally added weird coords in matlab, change it after)
  merged <- merged[!is.na(merged$V_s),]
  print(dim(merged))
  
  #replace by 0 if winds are less than 17m/s
  merged[merged$V_s<17,]$V_s <- 0
  
  #save files to a new folder (year by year)
  write.csv(merged, file = paste(hurr_country_storms,"/annual_winds_with_population/wind_and_pop_",y,".csv",sep=""))
  rm(merged)
}

rm(panel)


#---------------------------------------------------------------#
# 10. Aggregate to ADM2 level
#---------------------------------------------------------------#

#load new 30sec grid again
panel <- read.csv(paste(hurr_country_storms,"/maxWinds_with0.csv",sep=""))
panel <- subset(panel, select = -c(X))
panel <- panel[,c(2,1,3:10)]
pop_raster <-raster(paste(gpw_pop_main_path,
                          "/gpw-v4-population-count-2000.tif",sep=""))
winds_raster <- rasterFromXYZ(panel[panel$year==2000,], digits=1, crs = crs(pop_raster))
pop_raster <- terra::crop(pop_raster, winds_raster, snap="out")
rm(panel, winds_raster)

#rasterize shapefile with ADM2 to the grid
grid_regions <- exact_extract(pop_raster, ADM2, include_xy=TRUE, force_df=TRUE, include_cols= ID_2)
grid_regions <- bind_rows(grid_regions)
grid_regions <- subset(grid_regions, select = -value)
names(grid_regions)[names(grid_regions) == "x"] <- "site_longitude"
names(grid_regions)[names(grid_regions) == "y"] <- "site_latitude"
#round up coordinates to avoid weird results
grid_regions$site_longitude <- round(grid_regions$site_longitude,4)
grid_regions$site_latitude <- round(grid_regions$site_latitude,4)

#dataset to append
dataset = data.frame()

# loop through annual files
for (y in year_min:year_max) {
  panel <- read.csv(paste(hurr_country_storms,"/annual_winds_with_population/wind_and_pop_",y,".csv",sep=""))
  panel <- subset(panel, select = -c(X))
  
  #round up coordinates to avoid weird results
  names(panel)[names(panel) == "x"] <- "site_longitude"
  names(panel)[names(panel) == "y"] <- "site_latitude"
  panel$site_longitude <- round(panel$site_longitude,4)
  panel$site_latitude <- round(panel$site_latitude,4)
  
  #merge regions with maximum winds observations
  windsLand <- merge(grid_regions, panel, by = c("site_latitude", "site_longitude"))
  windsLand <- subset(windsLand, select = -c(site_latitude, site_longitude))
  windsLand$ID_2 <- as.numeric(windsLand$ID_2)
  windsLand <- windsLand[with(windsLand, order(year, ID_2)), ]
  
  rm(panel)
  
  names(windsLand)[names(windsLand) == paste("gpw.v4.population.count.",y, sep="")] <- "pop"
  
  #add weights by ignoring 0 population (if less than 1 person per cell)
  windsLand$coverage_fraction_pop <- windsLand$coverage_fraction
  windsLand[windsLand$pop<1,]$coverage_fraction_pop <- 0
  
  #take a weighted average (I assume all grids have the same area here)
  windsLand <- windsLand %>%
    group_by(year, ID_2) %>% 
    mutate(weighted_V_s = weighted.mean(V_s, coverage_fraction,na.rm=TRUE),  
           weighted_storm = weighted.mean(storm, coverage_fraction,na.rm=TRUE),
           weighted_one = weighted.mean(one, coverage_fraction,na.rm=TRUE),
           weighted_two = weighted.mean(two, coverage_fraction,na.rm=TRUE),
           weighted_three = weighted.mean(three, coverage_fraction,na.rm=TRUE),
           weighted_four = weighted.mean(four, coverage_fraction,na.rm=TRUE),
           weighted_five = weighted.mean(five, coverage_fraction,na.rm=TRUE),
           weighted_pop_V_s = weighted.mean(V_s, coverage_fraction_pop,na.rm=TRUE),  
           weighted_pop_storm = weighted.mean(storm, coverage_fraction_pop,na.rm=TRUE),
           weighted_pop_one = weighted.mean(one, coverage_fraction_pop,na.rm=TRUE),
           weighted_pop_two = weighted.mean(two, coverage_fraction_pop,na.rm=TRUE),
           weighted_pop_three = weighted.mean(three, coverage_fraction_pop,na.rm=TRUE),
           weighted_pop_four = weighted.mean(four, coverage_fraction_pop,na.rm=TRUE),
           weighted_pop_five = weighted.mean(five, coverage_fraction_pop,na.rm=TRUE))
  
  #replace missing values in pop-weighted vars with 0 (it means all ADM2 cells are not populated)
  windsLand[is.na(windsLand$weighted_pop_V_s),]$weighted_pop_V_s <- 0
  windsLand[is.na(windsLand$weighted_pop_storm),]$weighted_pop_storm <- 0
  windsLand[is.na(windsLand$weighted_pop_one),]$weighted_pop_one <- 0
  windsLand[is.na(windsLand$weighted_pop_two),]$weighted_pop_two <- 0
  windsLand[is.na(windsLand$weighted_pop_three),]$weighted_pop_three <- 0
  windsLand[is.na(windsLand$weighted_pop_four),]$weighted_pop_four <- 0
  windsLand[is.na(windsLand$weighted_pop_five),]$weighted_pop_five <- 0
  
  windsLand <- subset(windsLand, select = -c(coverage_fraction,coverage_fraction_pop, V_s, storm, one, two, three, four, five,pop))
  windsLand <- distinct(windsLand)
  
  dataset <- rbind(dataset, windsLand)
  rm(windsLand)
}

#combine all csv files
write.csv(dataset, file = paste(hurr_country_storms,"/maxWindsADM2_with_population.csv",sep=""))



