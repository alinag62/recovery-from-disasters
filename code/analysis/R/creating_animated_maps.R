library(gganimate)
library(magick)
library(ggplot2)
library(dplyr)
library(tidyr)

setwd("/Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters")

#Indonesia
# mpga_aw <- list.files("./output/Indonesia", pattern = "^gif_mpga_aw",full.names = TRUE)
# mpga_aw_list <- lapply(mpga_aw, image_read)
# mpga_aw_joined <- image_join(mpga_aw_list)
# mpga_aw_animated <- image_animate(mpga_aw_joined, fps = 2)
# image_write(image = mpga_aw_animated, path = "./output/Indonesia/animated_map_mpga_aw.gif")
# 
# num_qs <- list.files("./output/Indonesia", pattern = "^gif_num_qs_aw",full.names = TRUE)
# num_qs_list <- lapply(num_qs, image_read)
# num_qs_joined <- image_join(num_qs_list)
# num_qs_animated <- image_animate(num_qs_joined, fps = 2)
# image_write(image = num_qs_animated, path = "./output/Indonesia/animated_map_num_qs.gif")

#India
# mpga_aw_india <- list.files("./output/India", pattern = "^gif_mpga_aw",full.names = TRUE)
# mpga_aw_india_list <- lapply(mpga_aw_india, image_read)
# mpga_aw_india_joined <- image_join(mpga_aw_india_list)
# mpga_aw_india_animated <- image_animate(mpga_aw_india_joined, fps = 2)
# image_write(image = mpga_aw_india_animated, path = "./output/India/animated_map_mpga_aw.gif")
# 
# num_qs_india <- list.files("./output/India", pattern = "^gif_num_qs_aw",full.names = TRUE)
# num_qs_india_list <- lapply(num_qs_india, image_read)
# num_qs_india_joined <- image_join(num_qs_india_list)
# num_qs_india_animated <- image_animate(num_qs_india_joined, fps = 2)
# image_write(image = num_qs_india_animated, path = "./output/India/animated_map_num_qs.gif")
# 

# Indonesia WB

mpga_aw <- list.files("./output/Indonesia_worldbank/eq", pattern = "^gif_mpga_aw",full.names = TRUE)
mpga_aw_list <- lapply(mpga_aw, image_read)
mpga_aw_joined <- image_join(mpga_aw_list)
mpga_aw_animated <- image_animate(mpga_aw_joined, fps = 2)
image_write(image = mpga_aw_animated, path = "./output/Indonesia_worldbank/eq/animated_map_mpga_aw.gif")

num_qs <- list.files("./output/Indonesia_worldbank/eq", pattern = "^gif_num_qs_aw",full.names = TRUE)
num_qs_list <- lapply(num_qs, image_read)
num_qs_joined <- image_join(num_qs_list)
num_qs_animated <- image_animate(num_qs_joined, fps = 2)
image_write(image = num_qs_animated, path = "./output/Indonesia_worldbank/eq/animated_map_num_qs.gif")


#Tropical Cyclones
hurrInd <- list.files("./output/Indonesia/maps", pattern = "^hurr_scale_",full.names = TRUE)
hurrInd_list <- lapply(hurrInd, image_read)
hurrInd_joined <- image_join(hurrInd_list)
hurrInd_animated <- image_animate(hurrInd_joined, fps = 2)
image_write(image = hurrInd_animated, path = "./output/Indonesia/maps/hurr_scale_annual.gif")

hurrVnm <- list.files("./output/Vietnam/maps", pattern = "^hurr_scale_",full.names = TRUE)
hurrVnm_list <- lapply(hurrVnm, image_read)
hurrVnm_joined <- image_join(hurrVnm_list)
hurrVnm_animated <- image_animate(hurrVnm_joined, fps = 2)
image_write(image = hurrVnm_animated, path = "./output/Vietnam/maps/hurr_scale_annual.gif")

