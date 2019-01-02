All <- read.csv("~/Solar/Solar_Model/all_split2.csv",header = TRUE,stringsAsFactors=F, sep=",")
library(dplyr)
library(magrittr)
library(shiny)
library(anytime)
library(reshape2)
library(ggplot2)

mat = matrix(0, nrow = 12*24*365*4, ncol = 15)


# update

All %>%
  mutate_all(funs(ifelse(is.na(.), 0, .)))

All %<>%
  mutate_if(is.integer,as.numeric)

All %<>%
  mutate_if(is.numeric, funs(ifelse(is.na(.), 0, .)))

All[row.names(unique(All[,c("Day", "Month","Year")])),c(1:6,29)] -> sample_dates #sample dates give a unique day 
sample_dates$start <- sample_dates$Hour*60+sample_dates$Minute
sample_dates$len<- sample_dates$end <- sample_dates$over_thresh<- sample_dates$spare<- sample_dates$dead <- sample_dates$cumulative<- sample_dates$input_need <-0
sample_dates$daily<-12 # Daily kW load
sample_dates$start_hour  <- sample_dates$start_minutes <- sample_dates$end_hour  <- sample_dates$end_minutes <-0
sample_dates$night<-0
for (i in 1:nrow(sample_dates)) 
{
    sample_dates[i,]$cumulative<-
      sum(subset(All,(Year == sample_dates[i,]$Year)&(Month == sample_dates[i,]$Month)&(Day == sample_dates[i,]$Day))$PacTot)
tt <- subset(All,(Year == sample_dates[i,]$Year)&(Month == sample_dates[i,]$Month)&(Day == sample_dates[i,]$Day))
tt$spare<- (tt$PacTot>500)*(tt$PacTot-500)
tt$input_need<- (tt$PacTot<500)*(tt$PacTot-500)
tt$instp <- tt$PacTot/12
l <- nrow(tt)
if(l<1) {print(l)}
sample_dates[i,]$len<-l
my_end <- tt[l,]$Hour*60*60+tt[l,]$Minute*60+tt[l,]$Second
sample_dates[i,]$end <- my_end#/12 # NOTE Conversion to 5 second slots
sample_dates[i,]$start <- (tt[1,]$Hour*60*60+tt[1,]$Minute*60+tt[1,]$Second)#/12 # NOTE Conversion to 5 second slots
sample_dates[i,]$over_thresh <- sum(tt$PacTot>500)
sample_dates[i,]$spare <- sum(tt$spare)/12
sample_dates[i,]$dead <- (12*24)-l
sample_dates[i,]$input_need <- sum(tt$input_need)/12
#sample_dates[i,]$startsec <-  tt[1,]$Hour*60*60+tt[1,]$Minute*60+tt[1,]$Second
#sample_dates[i,]$endsec <-  tt[nrow(tt),]$Hour*60*60+tt[nrow(tt),]$Minute*60+tt[nrow(tt),]$Second
# Model
}

sample_dates$non_gen <- (12*24-sample_dates$len)*500/12
sample_dates$daily_need <- sample_dates$non_gen + (-sample_dates$input_need)

plot(sample_dates$dead)
lines(sample_dates$len)

sample_dates$diffs <- 0
for (i in 1:nrow(sample_dates)-1) 
{
  sample_dates[i,]$diffs<-sample_dates[i+1,]$ETotal - sample_dates[i,]$ETotal 
}

# Correct for collection gap 

sample_dates[sample_dates$diffs>50,]$diffs <- 30

plot(All[row.names(unique(All[,c("Day", "Month","Year")])),]$ETotal)

lines(sample_dates$start*33)

sample_dates$day_spare <- sample_dates$diffs-12
sample_dates[1,]$cumulative<-sample_dates[1,]$day_spare 
for (i in 2:nrow(sample_dates)) 
{
  sample_dates[i,]$cumulative<-sample_dates[i-1,]$cumulative + sample_dates[i,]$day_spare 
  sample_dates[i,]$night<-(((24*60*60) - sample_dates[i-1,]$end) + sample_dates[i,]$start)/(60*60)/2 # now in kwH/12 
# how much battery used at night
  night_need <- sample_dates[i,]$night * night_load
  if (night_need > sample_dates[i,]$battery){
    night_import <- night_need - sample_dates[i,]$battery
    sample_dates[i,]$battery<-0
  }
  else
  {
    sample_dates[i,]$battery <- sample_dates[i,]$battery - night_need
  }
}

# The number of generating slots per day hence calculate the non gen power requirements

sample_dates$non_gen <- (12*24-sample_dates$len)*500/12
sample_dates$daily_need <- sample_dates$non_gen-sample_dates$input_need

sample_dates$slot <- seq(1:nrow(sample_dates))


# Total under generating slots power need
# Total excess power from generation


# runExample("01_hello")
# All$date <- anytime::anytime(All$dd.MM.yyyy.HH.mm.ss)

#All$mydate <- as.character(as.Date(All$date))
#All$time <- format(All$date, "%T")


# small <- filter(All, date>"2018-07-01 07:44:21")

# not used? wframe <-data_frame(date=All$mydate,time=All$time,value=All$PacTot)

# not used? wframe2 <-data_frame(date=All$date,value=All$PacTot)

# achieve not used???? 

#achieve <- data.frame(date=Complete,count=0)

#for(i in 1:length(Complete)){
# achieve[i,2] <- nrow(filter(All, (mydate==Complete[i]$date) |   (PacTot>1400)))
#}

Total_list<-All_times<-timelist<-Time_list<-Date_list<-list()

# REMOVED BELOW
#for(i in 1:length(Complete)){
#timelist <- filter(All,as.Date(All$date) ==as.Date(Complete[i]))$time #ERROR HERE
#if(length(timelist)>0){
#  print(i)  
#print(timelist)
# All_times[i]<-timelist
#Total_list<-c(list(as.Date(Complete[i]),timelist),Total_list)

#Time_list<-c(timelist,Time_list)
#Date_list <- c(as.Date(Complete[i]),Date_list)
#}

#}


bigdata <- setNames(data.frame(matrix(ncol = 13, nrow = 0)), c("base_load","battery_size","slot","Day", "Month", "Year","bat_sat","export","import","start_hour","start_minutes","end_hour","end_minutes"))

Base_load <- 500
Night_Base_load <- 350

# Battery_Max <- 4000 # Battery capacity

for ( Battery_Max in c(0,8000,16000))#,24000,32000,40000))
{
  cat("\n",'--------------Battery Max-------------------- ', Battery_Max )  
  
sample_dates$battery <- sample_dates$bat_sat <- sample_dates$export<- sample_dates$import <- 0


# Get a day at a time
for (day_num in 1:nrow(sample_dates))
{
myday <- select(filter(All,Day==sample_dates[day_num,]$Day,Month==sample_dates[day_num,]$Month,Year==sample_dates[day_num,]$Year),Day, Month, Year, Hour, Minute, Second,PacTot )

if (day_num == 1) {last_battery =0} else {last_battery <- sample_dates[day_num,]$battery}
house_model<-data.frame(solar=myday$PacTot,demand=Base_load,battery=last_battery,grid=0,flow=0)
#house_model[1,]$battery <- 123 #sample_dates[day_num,]$battery
house_model$slot <- seq_len(nrow(house_model))

day_start <- myday[1,]$Hour*60*60+myday[1,]$Minute*60+myday[1,]$Second
day_end <- myday[nrow(myday),]$Hour*60*60+myday[nrow(myday),]$Minute*60+myday[nrow(myday),]$Second
# Model
# model a day
# battery start value, vector of 24 *12 5 minute power flows 
# battery capacity
# pass back vectors of energy needs and excess generation, total need, battery finish value


# house_model <- data.frame(demand = rep(500, slots), battery = rep(0, slots),
#                           solar = rep(0, slots), grid = rep(0, slots), flow = rep(0, slots)  ) 

 cat("\n",'--------------Daynum-------------------- ', day_num )
for(i in 2:nrow(house_model))
{
# At each step
  
  Residual_energy <- 0

  if (house_model[i,]$demand<= house_model[i,]$solar) # Enough solar?
   {
    Residual_energy <- house_model[i,]$solar - house_model[i,]$demand #  how much is left after meeting need
    Grid <- 0
 #   cat("\n",'Enough Solar ', i )
    if ((house_model[i-1,]$battery + Residual_energy) > Battery_Max) # Would this overflow battery?
    {
      house_model[i,]$grid <- Residual_energy - (Battery_Max - house_model[i-1,]$battery) # Yes so spare goes to grid
      house_model[i,]$battery <- Battery_Max # and battery is maxed out
      house_model[i,]$flow <- (Battery_Max - house_model[i-1,]$battery) 
      sample_dates[day_num,]$bat_sat <- sample_dates[day_num,]$bat_sat +1
    }
    else
    {
      house_model[i,]$battery <- house_model[i-1,]$battery + Residual_energy # No so add to battery (NB grid was zeroed above)
      house_model[i,]$flow <- Residual_energy
    }
}
else # not enough solar
{
  Residual_demand <- house_model[i,]$demand - house_model[i,]$solar
  if (Residual_demand>=house_model[i-1,]$battery )  # Would this exhaust battery?
  {
    # Yes so 
    house_model[i,]$battery <- 0 # actually exhaust it
    house_model[i,]$flow <- - house_model[i-1,]$battery # and record energy taken
    house_model[i,]$grid <- -(Residual_demand - house_model[i-1,]$battery)
  }  
else # no so take all from battery
    {
    house_model[i,]$battery <- house_model[i-1,]$battery - Residual_demand
    house_model[i,]$flow <- - Residual_demand
  
    }
  
  }

}

sample_dates[day_num,]$battery <- house_model[i,]$battery
sample_dates[day_num,]$export <- sum(subset(house_model,(grid > 0))$grid)
sample_dates[day_num,]$import <- - sum(subset(house_model,(grid < 0))$grid)

sample_dates[day_num,]$startsec <-  day_start
sample_dates[day_num,]$endsec <-  day_end

xymelt <- melt(house_model, id.vars = "slot")
#print(ggplot(xymelt, aes(x=slot,y = value, color = variable)) +
#theme_bw() +
#geom_line())


} 
# Now go through and calculate battery use each night

#for (day_num in 2:nrow(sample_dates))
#{
#  nightneed <- sample_dates[day_num,]$night

# add simulation run to big data 

bigdata <-rbind(bigdata,data.frame(Base_load,Battery_Max,select(sample_dates,Day,Month,Year,slot,bat_sat,export,import,start_hour,start_minutes,end_hour,end_minutes))
)

}


bigmelt <- melt(select(bigdata,Base_load,Battery_Max,slot,bat_sat,export,import), id.vars = c("slot","Base_load","Battery_Max"))


ggplot(bigmelt, aes(x=slot,y = value, color = variable)) +
theme_bw() +
geom_line() + facet_grid(Battery_Max ~ .)





# Battery model store (current_charge,offered) return new charge, battery_use, and remainder 

# current_charge <- current_charge + offered
# If offered > 0 
 
# if (current_charge > max_charge) { remainder <- current_charge - max_charge, current_charge <- max_charge}
# battery_flow <- battery_flow + ( max_charge - current_charge)

# else
# if current_charge < 0 { remainder <- current_charge, current_charge <- 0}
# battery_flow <- battery_flow + ( max_charge - current_charge)
max_charge <- 4000
battery <- function(old_current_charge,requested) 
{
  current_charge <- old_current_charge + requested  
  print(old_current_charge)
  print(requested)
  print(current_charge)
  battery_flow <- abs(requested)
  remainder <- 0
  if (current_charge > max_charge) 
  { 
    remainder <- current_charge - max_charge
    battery_flow <- max_charge - old_current_charge
    current_charge <- max_charge

  }

  if (current_charge < 0 )
  { 
    remainder <- current_charge
    battery_flow <-  old_current_charge + current_charge
    current_charge <- 0
  }
  # print(current_charge)
  # print(remainder)
  battery <- list(current_charge,remainder,battery_flow)
}

# demand =< solar? take from solar remainder -> battery and grid out
# demand > solar take from solar
# remainder <= battery take from battery
# remainder > battery take from battery remainder <- grid in
# 
# demand 
# Run model

# Handling night time
# work out how many 5 minute slots (but to dawn or split at midnig)



