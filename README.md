
# Wellbeing Study Helper

## Installation

You can install the this package via the remotes package.

``` r
remotes.install_github(repo = "tud-ise/wellbeing-study-helper")
```

## Example

The Package offers the functionality to receive data from a formr survey and query rescue time data.  

### All Data
  
To query all data you need to do the following.

``` r
# load the library
library(increasingwellbeing)

# fetch the survey results and provide the formr mail adress and passwort 
# aswell as the internal name of the initial, daily and final survey name
fetch_survey_data("test@test.de", "passwort123", "initial_survey", "daily_survey", "final_survey")

# execute function to combine fetch surveys + screen time data
data <- get_all_data()

# write data to csv file
write.csv(data, "all_data.csv", na = "", row.names = FALSE)
```

To query the data intermediately, you can execute the get_all_data() Function multiple times and provide the results of the previous run to avoid fetching the same data multiple times.

``` r
# load the library
library(increasingwellbeing)

# fetch survey for the first time
fetch_survey_data("test@test.de", "passwort123", "initial_survey", "daily_survey", "final_survey")
intermediate_data <- get_all_data()

# store data
write.csv(intermediate_data, "intermediate_data.csv", na = "", row.names = FALSE)

# 14 days later

# read data again
intermediate_data <- read.csv("intermediate_data.csv")

# fetch current survey results
fetch_survey_data("test@test.de", "passwort123", "initial_survey", "daily_survey", "final_survey")

# call function to combine data and provide previous data
data <- get_all_data(intermediate_data)

# write data into csv file
write.csv(data, "all_data.csv", na = "", row.names = FALSE)
```

### Single Data
You also have the possibility to receive an individuals data set with non-anonymized screen time data.
Due to privacy issues, you need to provide the all_data as well as your session id and your rescue time api key:

``` r
# load the library
library(increasingwellbeing)

# read the provide dataset with all data into a variable
all_data <- read.csv("all_data.csv")

# get your single data set by providing your session id, your RescueTime API Key, 
# your scope (you probably want to put 'Acitivity' here) and the previously loaded data set
data <- get_single_data("1", "ABC", "Activity", all_data)

# write data into file
write.csv(data, "single_data.csv", na = "", row.names = FALSE)
```
