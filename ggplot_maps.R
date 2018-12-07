# MAKING MAPS IN GGPLOT2#

#Making maps in ggplot can be tricky but below you will find a solid example of how to make basic maps. 
#More advanced steps will be included at the end (adding layers of your own data, important shape files from GIS, etc). 

#Here are a couple of tutorial links
#tutorial link: http://eriqande.github.io/rep-res-web/lectures/making-maps-with-R.html
#tutorial link: http://www.molecularecologist.com/2012/09/making-maps-with-r/


###MAKING A BASIC MAP IN GGPLOT

#Call the following packages at the start just to be sure you have everything you need. 

library(ggplot2)
library(ggmap)
detach("package:ggmap", unload=TRUE)
library(maps)
library(mapdata)
library(maptools)
library(scales) #for transparency
library(mapproj) #for projected maps
library(rgdal)
library(GISTools)  
library(devtools)
library(ggsn) #for north arrows and scale
library(ggthemes)
library(Rmisc)
library(sp)
library(raster)
library(reshape)
library(plyr)


# STEP 1: Learn how to make call maps of specific areas
#I'm using the worldHires database build into ggmap here, but you can use others if you want
###make a few test maps
map("worldHires", "Belize", col='gray90', fill=TRUE) #makes a map of Belize (entire country)

map("worldHires", "Mexico", col='gray', fill=TRUE) #makes a map of Mexico (entire country)

#How to limit the map by lat/long
map("worldHires","Mexico", xlim=c(-92.0,-86.0),ylim=c(15.5,22.0), col="gray90", fill=TRUE) 

map("worldHires", "Belize", xlim=c(-89.5, -87.5), ylim=c(15.5, 19.0), col="gray90", fill=TRUE)

map("worldHires", "Guatemala", col='gray90', fill=TRUE)
map("worldHires", "Honduras", col='gray90', fill=TRUE)

#all of this allows you to see maps of the areas specified. But you can't import them into ggplot unless you define them

#STEP 2: Define the areas you want to use in your ggplot map and trim them by lat/long to make a composite maps

#define countries and regions you want to use (can use xlim and ylim to limit lat and long but this is easier to do later)
belize<-map_data("worldHires", "Belize", xlim=c(-89.5,-87.5),ylim=c(15.5,19.0))

mexico<-map_data("worldHires", "Mexico", xlim=c(-89.5,-87.5),ylim=c(15.5,19.0))

guat<-map_data("worldHires", "Guatemala")

hon<-map_data("worldHires", "Honduras")

panama<-map_data("worldHires", "Panama")

us<-map_data("worldHires", "US")

#Here I have defined Mexico and Belize (and trimmed them by lat and long) as well as Guatemala, Honduras, Panama, and the US.
#I can now read all of these into ggplot and trim the maps to my liking. 

#STEP 3: Make a map in ggplot
#Use geom_polygon function in ggplot to import your countries (or whatever you are mapping)
#See examples below 

##Example 1:Belize Map######
pd<- position_dodge(0.1) #if stuff on the map overlaps, have it 'dodge' along the x-axis by 0.1 unit (not necessary with the basemap, but we will need this later)

bz<-ggplot()+ #note: I have named my ggplot map 'bz' so I can call it easier in the future
  geom_polygon(data=belize, aes(x=long, y=lat, group= group), fill='gray70', color='black')+ #makes Belize
  geom_polygon(data=mexico, aes(x=long, y=lat, group=group), fill='gray70', color='black')+ #makes Mexico
  geom_polygon(data=guat, aes(x=long, y=lat, group=group), fill='gray70', color='black')+ #makes Guatemala
  geom_polygon(data=hon, aes(x=long, y=lat, group=group), fill='gray70', color='black')+ #makes Honduras
  coord_fixed(xlim = c(-89.3, -83.0),  ylim = c(15.2, 21.5), ratio = 1)+ #trims the map to these x and y limits. This step is KEY
  theme_classic()

bz #produces my Belize regions base map

##Example 2: Florida Keys Map

pd<- position_dodge(0.03) 

Fl<-ggplot()+
  geom_polygon(data=us, aes(x=long, y=lat, group= group), fill='gray70', color='black')+
  #geom_polygon(data=mexico, aes(x=long, y=lat, group=group), fill='gray70', color='black')+
  #geom_polygon(data=guat, aes(x=long, y=lat, group=group), fill='gray70', color='black')+
  #geom_polygon(data=hon, aes(x=long, y=lat, group=group), fill='gray70', color='black')+
  coord_fixed(xlim = c(-82.30, -80.10),  ylim = c(24.5, 25.75), ratio = 1)+
  theme_bw()
Fl

#that's how you make simple maps. See below for additional info (how to add points, how to add shape file layers)

#####################################################################################################

###MORE ADVANCED MAP MAKING IN GGPLOT (R as GIS)

#Adding your own points to a basemap. 

#Let's take one of our examples from above--> Using the map 'bz' that I made above
#I want to add points on the map that represent my sampling sites. This is no problem for anyone who knows how to use ggplot
#You simply add geom_points

#first, read in your file
a=read.csv('points.csv') #this is the datafile that contains my points with lat and long. Make sure each point is it's own row (data in long form)
#Are your data in the wrong format? Check out the plyr and dplyr libraries for melt and dcast functions (or google 'short form to long form in r')

bz+ 
  geom_point(data=a, aes(x=Longitude, y=Latitude, color=reef.zone, shape=species), position=pd, size=2) #boom, basemap + sampling sites!


#### HOW TO IMPORT A SHAPE FILE AS A LAYER IN GGPLOT ####
#this one is actually less easy, but R can read shapefiles (w/ correct libraries loaded--GIStools for example)
#A shapefile can be exported from a GIS software. It will export in 3 parts: a database file (.dbf), a shape file (.shp), and a .shx file. You need ALL 3 in your working directory for this to work!!!!
#NOTE: just a reminder, make sure your .shp, .shx, and .dbf files are all in the working directory when loading in a shape file!

#Load in the shape file
reeflocs<-readOGR(dsn=".", layer="wcmc_coral_reef_locs")###here I am loading the WCMC global coral reef location database shapefile
#note: this process takes time! Be patient. If you are loading a massive dataset consider using a more powerful machine or run R through a supercomputer

#get coordinates for your layer 
reeflocs1<-as.data.frame(coordinates(reeflocs)) #GIS files are complicated, but basically there is a data array in the file. You only need certain information from that array. In this case, you need coordinates in lat and long. You can bind the coordinates to a 2-dimensional data frame using this command

head(reeflocs1) #you should see lat and long columns populated with point data. This is all you need!




##Lakes and Rivers
ne_rivers <- readOGR('ne_10m_rivers_lake_centerlines.shp',
                     'ne_10m_rivers_lake_centerlines')

quick.subset <- function(x, longlat){ #makes a function to pull out the info we need to make rivers
  
  # longlat should be a vector of four values: c(xmin, xmax, ymin, ymax)
  x@data$id <- rownames(x@data)
  
  x.f = fortify(x, region="id")
  x.join = join(x.f, x@data, by="id")
  
  x.subset <- subset(x.join, x.join$long > longlat[1] & x.join$long < longlat[2] &
                       x.join$lat > longlat[3] & x.join$lat < longlat[4])
  
  x.subset
}

domain <- c(-89.0, -86.5, 15.0, 18.00) #define x/y limits

river.subset <- quick.subset(ne_rivers, domain) #subset the rivers shp file
head(river.subset)
rivers<-as.data.frame(river.subset)
head(rivers)

##Belize Rivers
bz_rivers<-readOGR(dsn=".", layer="BLZ_water_lines_dcw")
#bz_rivers<- readOGR('BLZ_water_lines_dcw.shp',
                    'BLZ_water_lines')
head(bz_rivers)
str(bz_rivers)
bz_riv.subset<-quick.subset(bz_rivers, domain)
bz_riv.subset

ggplot()+
  #geom_path(data=river.subset, aes(x=long, y=lat, group=group), color="blue")+
  geom_path(data=bz_rivers, aes(x=long, y=lat, group=group), color='blue')
  geom_polygon(data=belize, aes(x=long, y=lat, group= group), fill='gray70', color='black') #makes Belize
  


##Add the shape file data to your map!

#let's use 'bz' again

bz+ geom_point(data=reeflocs1, aes(x=V1, y=V2), color='firebrick',size=0.0001) #I use geom_point because I want to see points at each lat and long in the shape file. Each point represents a distinct reef unit
#you can change colors as with all ggplot items. Same with size. I made mine very small because there are thousands of points and I didn't want them to drown out my other data. 



##RGOOGLEMAPS
library(RgoogleMaps)
library(ggmap)
mapImageData1 <- get_map(location = c(lon = -80, lat = 24.75),
                         color = "color",
                         source = "google",
                         maptype = "satellite",
                         zoom = 17)

mbrs_bbox=read.csv('mbrs_bbox.csv')
bbox <- make_bbox(lat = lat, lon = lon, data = mbrs_bbox)

mbrs<-get_map(location = bbox, source = "google", maptype = "hybrid")
ggmap(mbrs)+geom_point(data=reeflocs1, aes(x=V1, y=V2), color='firebrick4',size=0.0001)



###SPECIAL NOTE ABOUT GGPLOT: 

#See the code below. Each line represents a unique plot element. Note that ggplot layers these items. If there is overlap the last thing in the code will be the top layer. That means the first line of the map code is the bottom layer. 



pd<- position_dodge(0.1) 

a1=read.csv('prelim_mp.csv')
head(a1)


ggplot()+
  geom_path(data=bz_rivers, aes(x=long, y=lat, group=group), color='black')
  

bz<-ggplot()+
  geom_polygon(data=belize, aes(x=long, y=lat, group= group), fill='gray60', color='white')+
  geom_polygon(data=mexico, aes(x=long, y=lat, group=group), fill='gray50', color='white')+
  geom_polygon(data=guat, aes(x=long, y=lat, group=group), fill='gray50', color='white')+
  geom_polygon(data=hon, aes(x=long, y=lat, group=group), fill='gray50', color='white')+
  geom_point(data=reeflocs1, aes(x=V1, y=V2), color='gray70',size=0.0001)+	
  geom_point(data=a1, aes(x=long, y=lat, size=a1$Mppercm, color=site))+
  coord_fixed(xlim = c(-89.2, -87.5),  ylim = c(15.7, 18.35), ratio = 1)+
  geom_path(data=river.subset, aes(x=long, y=lat, group=group), color="black")+
  geom_path(data=bz_rivers, aes(x=long, y=lat, group=group), color='black')+
  theme_classic()+
  scale_color_manual(values=c("#FFCCCC", "#FF99CC", "#CC6699", "#993366"), labels=c("Belize City\nBack Reef", "Dangriga\nBack Reef", "Gladden Spit\nBack Reef", "Sapodilla Cayes\nBack Reef"))+
  labs(color="Site", size="Microplastics per/nsquare cm")+
  #scale_size_manual(color="white")+
  theme(
    panel.background = element_rect(fill = "transparent") # bg of the panel
    , plot.background = element_rect(fill = "transparent") # bg of the plot
    , panel.grid.major = element_blank() # get rid of major grid
    , panel.grid.minor = element_blank() # get rid of minor grid
    , legend.background = element_rect(fill = "transparent") # get rid of legend bg
    #, legend.box.background = element_rect(fill = "transparent") # get rid of legend panel bg
    , legend.text=element_text(color="white"),
      axis.text = element_text(color="white"),
    legend.title = element_text(colour="white"),
      axis.ticks=element_line(colour="white"),
      axis.title=element_text(color="white")
    ,legend.position=c(1.1,0.35)
    ,legend.key.size = unit(1.5, 'lines')
    ,legend.spacing.y = unit(-0.5, 'cm'))
bz

ggsave(bz, filename = "mp_poster_map.png",  bg = "transparent")



USAMap +
  2
geom_point(aes(x=lon, y=lat), data=mv_num_collisions, col="orange", alpha=0.4, size=mv_num_collisions$collisions*circle_scale_amt) + 
  3
scale_size_continuous(range=range(mv_num_collisions$collisions))



##map for Lauren's bacteria paper

bac<-read.csv('bac.csv')
head(bac)
reeflocs2=read.csv('globalreeflocs.csv') #global reef locations downloaded from the WCMC (2010 ARCGIS shape file was converted to csv for easier use with shiny apps)
head(reeflocs2)
##subset reeflocs to be only Belize
reeflocs3<-subset(reeflocs2, V1<=-87.5 & V1>=-89.5 & V2<=19.0 & V2>=15.5)
head(reeflocs3)

shapes<-c(21,22,23,24)

pd<- position_dodge(0.1) #if stuff on the map overlaps, have it 'dodge' along the x-axis by 0.1 unit (not necessary with the basemap, but we will need this later)

bz<-ggplot()+ #note: I have named my ggplot map 'bz' so I can call it easier in the future
  geom_polygon(data=belize, aes(x=long, y=lat, group= group), fill='gray70', color='black')+ #makes Belize
  geom_polygon(data=mexico, aes(x=long, y=lat, group=group), fill='gray70', color='black')+ #makes Mexico
  geom_polygon(data=guat, aes(x=long, y=lat, group=group), fill='gray70', color='black')+ #makes Guatemala
  geom_polygon(data=hon, aes(x=long, y=lat, group=group), fill='gray70', color='black')+ #makes Honduras
  geom_point(data=reeflocs3, aes(x=V1, y=V2), color='gray70',size=0.0001)+	
  geom_point(data=bac, aes(x=long, y=lat, fill=Reef.Zone, shape=Site), size=5)+
  scale_shape_manual(values=shapes) + 
  coord_fixed(xlim = c(-89.2, -87.5),  ylim = c(15.7, 18.35), ratio = 1)+ #trims the map to these x and y limits. This step is KEY
  theme_classic()
bz


