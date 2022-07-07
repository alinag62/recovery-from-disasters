rm(list=ls())

# load packages

library(lpirfs)
library(dplyr)

#--------------------------------------------------#
# 0. Set data paths and several variables manually
#--------------------------------------------------#

path = "/Users/alina/Library/CloudStorage/Box-Box/recovery-from-disasters/"
setwd(path)
panel <- read.csv("data/firm-data/Vietnam/tropical_cyclones/winds_firm_data_ready2regress.csv")

#order columns and sort by id and year
panel <- panel[order(panel$plant, panel$year),]
panel <- panel  %>%
  dplyr::select(plant, year, everything())



results_panel <- lp_lin_panel(data_set = panel[!is.na(panel$log_L)&(panel$log_L!=-Inf),],
                              endog_data = "log_L", shock = "storm_pop_only",
                              hor = 5, confint = 1.96, panel_effect = "twoways")
plot(results_panel)


results_panel2 <- lp_lin_panel(data_set = panel[!is.na(panel$log_L)&(panel$log_L!=-Inf),],
                              endog_data = "log_L", shock = "storm_pop_only",
                              hor = 5, confint = 1.96, panel_effect = "twoways",
                              cumul_mult = FALSE, diff_shock = FALSE)

plot(results_panel2)


results_panel3 <- lp_lin_panel(data_set = panel[!is.na(panel$log_L)&(panel$log_L!=-Inf),],
                              endog_data = "log_L", shock = "storm_pop_only",
                              hor = 5, confint = 1.96, panel_effect = "twoways",robust_cluster = "vcovDC")


plot(results_panel3)


results_panel4 <- lp_lin_panel(data_set = panel[!is.na(panel$log_L)&(panel$log_L!=-Inf),],
                              endog_data = "log_L", shock = "storm_pop_only",
                              hor = 3, confint = 1.96, panel_effect = "twoways")


plot(results_panel4)






