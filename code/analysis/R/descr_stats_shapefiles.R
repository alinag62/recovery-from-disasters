#Calculate descr.stat. of ADM1/ADM2 in different countries
# clear
rm(list=ls())

# set seed
set.seed(123)

# load packages
library('ncdf4')
library('raster')
library('rgdal')
library('rgeos')
library('sf')
library('maptools')
library('data.table')
library('geosphere')
library('ncdump')
library('xtable')
library(foreign)

setwd("/Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters")

#open counries' shapefiles and calculate areas
# india_adm2 <- shapefile("./data/firm-data/India/Shapefile/IND_adm_shp/IND_adm2.shp")
# crs(india_adm2)
# india_adm2$area_sqkm <- area(india_adm2) / 1000000

# indonesia_adm2 <- shapefile("./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2.shp")
# crs(indonesia_adm2)
# indonesia_adm2$area_sqkm <- area(indonesia_adm2) / 1000000
# median(indonesia_adm2$area_sqkm)
#write.dta(data.frame(indonesia_adm2$area_sqkm), "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/adm2_areas.dta")

# colombia_adm2 <- shapefile("./data/firm-data/Colombia/Shapefile/COL_adm_shp/COL_adm2.shp")
# crs(colombia_adm2)
# colombia_adm2$area_sqkm <- area(colombia_adm2) / 1000000
# 
# colombia_adm1 <- shapefile("./data/firm-data/Colombia/Shapefile/COL_adm_shp/COL_adm1.shp")
# crs(colombia_adm1)
# colombia_adm1$area_sqkm <- area(colombia_adm1) / 1000000

stats <- data.frame(matrix(nrow = 4, ncol = 5))
colnames(stats) <- c("Min", "5pc", "Mean", "95pc", "Max")
row.names(stats) <- c("India ADM2", "Indonesia ADM2", "Colombia ADM2", "Colombia ADM1")
stats[1,] <- c(min(india_adm2$area_sqkm), quantile(sort(india_adm2$area_sqkm), probs = c(.05)), mean(india_adm2$area_sqkm), quantile(sort(india_adm2$area_sqkm), probs = c(.95)), max(india_adm2$area_sqkm))
stats[2,] <- c(min(indonesia_adm2$area_sqkm), quantile(sort(indonesia_adm2$area_sqkm), probs = c(.05)), mean(indonesia_adm2$area_sqkm), quantile(sort(indonesia_adm2$area_sqkm), probs = c(.95)), max(indonesia_adm2$area_sqkm))
stats[3,] <- c(min(colombia_adm2$area_sqkm), quantile(sort(colombia_adm2$area_sqkm), probs = c(.05)), mean(colombia_adm2$area_sqkm), quantile(sort(colombia_adm2$area_sqkm), probs = c(.95)), max(colombia_adm2$area_sqkm))
stats[4,] <- c(min(colombia_adm1$area_sqkm), quantile(sort(colombia_adm1$area_sqkm), probs = c(.05)), mean(colombia_adm1$area_sqkm), quantile(sort(colombia_adm1$area_sqkm), probs = c(.95)), max(colombia_adm1$area_sqkm))

print(xtable(stats, type = "latex", caption="Descriptive Statistics for Regions' Areas (in sq km)"), file = "output/general/tables/adm_regions_areas.tex", caption.placement = "top")

indonesia_adm2 <- shapefile("./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IDN_adm2.shp")
crs(indonesia_adm2)
indonesia_adm2$area_sqkm <- area(indonesia_adm2) / 1000000
indonesia_df <- data.frame(matrix(nrow = 283, ncol = 2))
indonesia_df$ID_2 <- indonesia_adm2$ID_2
indonesia_df$area_sqkm <- indonesia_adm2$area_sqkm
indonesia_df <- subset(indonesia_df, select=-c(X1, X2))

write.csv(indonesia_df, "./data/firm-data/Indonesia/Shapefile/IDN_adm_shp/IND_adm2_areas.csv")

# median(indonesia_adm2$area_sqkm)


