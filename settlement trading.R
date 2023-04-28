# Taipower historical settlement trading #####
# WebScraping from 2021/11/26

# library
library(rvest)
library(magrittr)
library(jsonlite)
library(dplyr)
library(lubridate)
library(openxlsx)

# create date and variables
date <- as.character(seq(date("2021-11-16"), Sys.Date(), by = 1))

var <- c("datetime",
	"srBid", "srBidQse", "srPrice",
	"supBid", "supBidQse", "supPrice")

df <- NULL

# loop
for (i in date){

  url <- paste0("https://etp.taipower.com.tw/api/infoboard/settle_value/query?startDate=", i)
  
  # JSON file to data frame
  data <- read_html(url) %>%
  	html_nodes("p") %>%
  	html_text %>%
  	fromJSON
  
  data <- data$data
  
  # datetime form
  data <- data %>%
  	mutate(datetime = ymd_hm(paste0(tranDate, " ", tranHour)))
  
  data <- data %>%
  	select(!!var)
  
  df <- rbind(df, data)

}

head(df)

# sr: 即時備轉, sup: 補充備轉
# Bid: 得標容量(國營)(MW), BidQse: 得標容量(民營)(MW), Price: 結清價格(元 / MW·h)

# Quant = Bid + BidQse
df <- df %>%
	mutate(month = format(df$datetime, "%Y-%m"),
		srQuant = srBid + srBidQse,
		supQuant = supBid + supBidQse) 

# monthly weighted average price, weight = Quant
month_w_avg_price <- df %>%
	group_by(month) %>%
	summarise(
		w.avg.srPrice = weighted.mean(srPrice, w = srQuant, na.rm = TRUE),
		w.avg.supPrice = weighted.mean(supPrice, w = supQuant, na.rm = TRUE))

# mean without weight
#df %>%
#	group_by(month) %>%
#	summarise(
#		across(ends_with("Price"), mean, na.rm = TRUE, .names = "avg.{.col}")) 

# output
setwd("C:/Users/PC622R/Desktop/using R/電力交易平台")

output <- list(歷史結清價格與交易量 = df, 月均價 = month_w_avg_price)

write.xlsx(output, file = "歷史結清價格與交易量.xlsx")



