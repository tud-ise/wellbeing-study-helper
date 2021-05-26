
# Wellbeing Study Helper

## Installation

You can install the this package via the remotes package.

``` r
remotes.install_github(repo = "tud-ise/wellbeing-study-helper")
```

## Example

The Package offers the functionality to receive data from a formr survey and query rescue time data.  

### All Data
  
To query all data you need to do the following:

``` r
library(increasingwellbeing)
fetch_survey_data("test@test.de", "passwort123", "initial_survey", "daily_survey", "final_survey")
data <- get_all_data()
write.csv(data, "all_data.csv", na = "", row.names = FALSE)
```

### Single Data
You also have the possibility to receive an individuals data set with non-anonymized screen time data.
Due to privacy issues, you need to provide the all_data as well as your session id and your rescue time api key:

``` r
library(increasingwellbeing)
all_data <- read.csv("all_data.csv")
data <- get_single_data("1", "ABC", "Activity", all_data)
write.csv(data, "single_data.csv", na = "", row.names = FALSE)
```
