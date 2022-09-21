IS.RRS.PASG.KM
library(ggthemes)
library(tidyverse)
library(gganimate)
#install.packages("WDI")
#install.packages("RJSONIO")
library(RJSONIO)
library(WDI)
#Let's see if we can find a code for export?

WDIsearch(string='Railways, Passengers ', field='name', cache=NULL)

#Ahha, seems like "NE.EXP.GNFS.CD" (Export of Goods and Services) will do it...
NE.EXP.GNFS.CD
#(There are also codes for Export of Goods and Services for males and females separately)

df.railway=WDI(country="all", indicator=c("IS.RRS.PASG.KM"), start=2001, end=2022)

library(ggplot2)
#Alfred used a boxplot to provide an overview of the range of life expectanices across 
#countries over a period of year. The outliers during the 1990s really jumped out:
g=ggplot()+geom_boxplot(data=df.exp,aes(x=year,y=IS.RRS.PASG.KM, group=year))
g=g+theme(axis.text.x = element_text(angle = 45, hjust = 1))
g
library(tidyverse)

#Let's filter the data to tunnel down and look to see which country or countries the outliers correspond to:



#Rwanda is notable, so let's overlay the numbers for Export of Goods and Services in Rwanda on the chart:
df1.railway<-df.railway %>% filter(country=='Pakistan'|country=='India'|country=="China"|country=="Japan")
ggplot(df1.railway,aes(x=year,y=IS.RRS.PASG.KM,color=country))+geom_line()+labs(
  title="Export of goods and service in current USD",x="year",
  y="current USD", caption = "Source:WDI")+theme_minimal()
## Animated one
an<-ggplot(df1.exp,aes(x=year,y=NE.EXP.GNFS.CD,color=country))+geom_line()+labs(
  title="Export of goods \n and service in \n current USD",x="year",
  y="current USD", caption = "Source:WDI")

an+transition_reveal(year)




g=ggplot(df.exp)+geom_line(data=subset(df.exp,country%in%c('Pakistan', 'India','Bangladesh')),aes(x=year,y=NE.EXP.GNFS.CD),col='red')
g
#So what's causing the drop Export of Goods and Services? One way of exploring this problem is to 
#look at the Export of Goods and Services figures for other countries with known problems over a
#particular period to see if their Export of Goods and Services figures have a similar signature 
#over that particular period. So for example, let's bring in in data for Kenyan life
#expectancy - does the Aids epidemic that hit that country have a similar signarture
#effect?

g=ggplot(df.exp)+geom_line(data=subset(df.exp,country=='Bangladesh'),aes(x=year,y=NE.EXP.GNFS.CD),col='green')
g
#How about Uganda, which suffered similarly?

g=g+geom_line(data=subset(df.exp,country=='India'),aes(x=year,y=NE.EXP.GNFS.CD),col='blue')
g
#Neither of those traces appear to have the same signature as the Rwandan curve.
#So might there be another cause? How about civil war? For example, Bangladesh 
#suffered a civil war in the early 1970s - what was the effect on Export of Goods and Services 
#over that period?

g=g+geom_line(data=subset(df.exp,country=='Bangladesh'),aes(x=year,y=NE.EXP.GNFS.CD),col='purple')
g
#Ah ha - that has a marked similarity, to the eye at least...

#Search for mortaility indicators

Data<-WDI(indicator = c("EG.ELC.ACCS.ZS", # access to electricity
                        "BN.CAB.XOKA.GD.ZS", # current account balance
                        "IC.BUS.DFRN.XQ", # ease of doing business
                        "FP.CPI.TOTL.ZG", # CPI
                        "FR.INR.LNDP"), # interest rate spread
          start = 1960, end = 2020) %>% as_tibble() 
Data
Data<-Data %>%
  rename(elecperpop = 4,
         cab = 5,
         edb = 6,
         cpi = 7,
         ratespread = 8) 


library(stevemisc)
Data %>%
  filter(country == "Pakistan") %>%
  mutate(cpiprop = cpi/100) %>% # going somewhere with this...
  ggplot(.,aes(year, cpiprop)) + 
  theme_steve_web() + post_bg() +
  geom_bar(stat="identity", alpha=.8, fill="#619cff", color="black") +
  scale_x_continuous(breaks = seq(1960, 2020, by = 10)) +
  # Below is why I like proportions
  scale_y_continuous(labels = scales::percent) +
  labs(x = "", y = "Consumer Price Index (Annual %)",
       caption = "Data: International Monetary Fund, via {WDI}",
       title = "The Consumer Price Index (Annual %) in Pakistan, 1960-2020",
       subtitle = "International events,debt and currency devaluations will account for the spikes you see.")

n<-10000
x<-runif(n)
x_n<-cumsum(x)/(1:n)
plot(1:n,x_n)

