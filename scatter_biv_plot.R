# plot Karl suggested
#
#   display the lengths and category of indiviual bivalents
# display as points / scatter plot

library(ggplot2)
library(plyr)
#setup scaffold made of lines with gplot that make 4 quardrants

#############
# LOAD DATA #
#############
setwd("C:/Users/alpeterson7/Documents/IJmacro_repo/")
load(file="manual_SC_data_setup.RData")


#remove XY from male measures
male_biv_measures <- male_biv_measures[ !grepl("XY", male_biv_measures$blobjectClass) , ]

################
# cal mean IFD #
################

#the mean IFD can be ploted onto these plots


###############
# SET UP PLOT #
###############
#seperate plots by sexs and strains
#ggplot scatter, x axis objclass, y axis sc length

scatter_biv <-  ggplot(female_biv_measures, 
      aes(x=blobjectClass, y=SC.length) ) + 
     ggtitle("Female Bivalent Measures") +
  scale_fill_manual(values = c("purple","black","red", "black"))

  scatter_biv + geom_jitter(width = 0.20) + 
  facet_wrap( ~ strain, scales = "free_x", ncol = 4)  

#color refrence
#"#56B4E9", "#56B4E9", G?, #"blue", "blue",  LEWES?  #"cadetblue", "cadetblue",  WSB #"lightblue",
#"coral1",  "coral1",   PWD  #"#E69F00","#E69F00",  MSM?  #"yellowgreen" - CAST

colors <- c("#56B4E9", "cadetblue","coral1", "#E69F00" )

#male data (seperate plots by strain)
scatter_biv <-  ggplot(male_biv_measures, 
     aes(x=blobjectClass, y=SC.length) ) + 
  ggtitle("Male Bivalent Measures") +  scale_fill_manual(values = c("purple","black","red", "black"))
  
scatter_biv + geom_jitter(width = 0.20) + 
  facet_wrap( ~ strain, scales = "free_x", ncol = 4) 



#c("#56B4E9", "cadetblue","coral1", "#E69F00" )

########
# Save #
########

setwd("C:/Users/alpeterson7/Documents/IJmacro_repo")

dev.copy(png,'Biv_scatter_plot_female.png')
dev.off()
dev.copy(png,'Biv_scatter_plot_male.png')
dev.off()


#color reference
# = c("#56B4E9","darkcyan", "aquamarine4", "cadetblue", #blues
#       "indianred","#E69F00","coral1",            #reds
#       "darkolivegreen4", "seagreen3"           #green