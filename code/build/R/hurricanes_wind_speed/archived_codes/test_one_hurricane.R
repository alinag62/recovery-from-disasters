library("geosphere")



rm(list=ls())

setwd("/Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters/")
allCyclones <- read.csv(file = 'data/tropical-cyclones/raw/ibtracs.ALL.list.v04r00.csv')
katrinaAllVars <- subset(allCyclones, NAME=="KATRINA"&SEASON==2005)
katrina <- katrinaAllVars[c("ISO_TIME", "USA_LAT", "USA_LON", "USA_STATUS", "USA_WIND", "USA_RMW", "STORM_SPEED")]

monroe <- read.csv(file = "code/R/hurricanes_wind_speed/monroe_MI.csv")
monroe$lat <- (monroe$top-monroe$bottom)/2 + monroe$bottom
monroe$lon <- (monroe$right-monroe$left)/2 + monroe$left
monroe <- monroe[c("id", "lat", "lon")]

# coordinates to vectors
site_latitude <- monroe[2]
site_longitude <- monroe[3]

# extract parameters of a hurricane
# rmw - radius of maximum wind speed => change later to linearly interpolated one
rmw <- katrina$USA_RMW
s_par <- as.data.frame(rep(1.3, each = length(katrina$USA_RMW)))

#fixed model parameters: friction, gust and inflow angle for land;  
asymmetry_factor <- 1 #always fixed?; S
inflow_angle <- 40 #I
friction_factor <- 0.8 #F
gust_factor <- 1.5 #G

#add interpolation with specific step (1 hour? 1 minute?)
lat_vec <- katrina$USA_LAT
lon_vec <- katrina$USA_LON
wmax_vec <- katrina$USA_WIND #V_m

#let's assume forward and translational speeds mean the same
transl_vec <- katrina$STORM_SPEED #V_h

#use Haversine
#angle between eye and point
#using 2 bearings!



#radial distance between eye and point
distHaversine(c(0,0), c(1,3))
















