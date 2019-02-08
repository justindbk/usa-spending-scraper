## This script scrapes USASpending.gov for aggregate spending totals in counties

library(tidyverse)
library(rvest)
library(httr)
library(jsonlite)

## Read in list of counties to scrape, with full FIPS code and county name (for error checking)
counties <- read_csv("../../Data/counties_list.csv")
counties$countyfips <- gsub("\\S{2}(\\S{3})","\\1",counties$fips)
counties$countyfips[grep("NA",counties$countyfips)] <- NA
# remove rows that might return API errors:
counties <- counties %>%
	filter(!is.na(countyfips)) %>%
	filter(fips != "00000") %>%
	filter(!is.na(state_abb))


baseurl <- "https://api.usaspending.gov/api/v2/"
endpoint <- "search/transaction_spending_summary/"
years <- c(2008:2018) # designate years you want to scrape
# nrow(counties)
# doesn't seem to like doing a vector of all counties at once, so separating this out
# lengthlist <- c(seq(1,nrow(counties),by=100),nrow(counties)+1)
allyears <- NULL
thisyear <- NULL
for(i in years){
	thiscounty <- NULL
	thisyear <- NULL
	for(j in 1:length(counties$fips)){
		params <- list(scope = "place_of_performance",
									 geo_layer = "county",
									 geo_layer_filters = array(counties$fips[j]),
									 filters = list(
									 	time_period = data.frame("start_date" = paste0(i,"-01-01"),
									 													 "end_date" = paste0(i,"-12-31"))
									 ))
		# toJSON(params,pretty=T) # in case you want to check what this looks like in JSON
		resp <- POST(url = paste0(baseurl,endpoint), 
								 body = params,encode = "json"
								 # body = upload_file("params.json"),
		)
		json <- content(resp, "text",encoding = "UTF-8")
		API_data <- fromJSON(json,flatten = T)
		if(length(API_data$results)>0){
			API_results <- API_data$results %>%
				rename(usaspending = aggregated_amount) 
			
			if(nrow(API_results)>1){
				# remove different names:
				API_results <- API_results %>%
					filter(tolower(gsub("(\\w+) .*","\\1",display_name))==tolower(gsub("(\\w+) .*","\\1",counties$county_name.x[j])))
				# then sum for all 
				API_results <- API_results %>%
					group_by(shape_code) %>%
					summarize(usaspending = sum(usaspending))
				
			} else{
				API_results <- API_results %>%
					select(-display_name)
			}
			
			thiscounty <- left_join(counties[j,], API_results,by=c("fips" = "shape_code"))
			thisyear <- bind_rows(thisyear,thiscounty)
		}
	}
	thisyear$year <- i
	allyears <- bind_rows(allyears,thisyear)
	
}

# checking results:
View(allyears)
# looks like some problems with duplicate counties for each county code. need to fix this
dupes <- allyears %>%
	filter(fips %in% unique(allyears$fips[which(duplicated(allyears[,c("fips","county_name.x","year")]))])) %>%
	arrange(fips)
dim(dupes)
# re-ran with duplicate checking added into loop, and now no duplicates



save(allyears,file="../../Data/usa_spending_grants.RData")
write_csv(allyears,path = "../../Data/usa_spending_grants.csv")
# this returns the sum of "federal_action_obligation" according to the API documentation page:
# https://github.com/fedspendingtransparency/usaspending-api/blob/dev/usaspending_api/api_docs/api_documentation/advanced_award_search/spending_by_geography.md

