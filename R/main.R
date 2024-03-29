#' Fetch Survey Data From Formr
#'
#' @param formr_email string the mail address of the formr account
#' @param formr_password string the password of the formr account
#' @param initial_survey_name string the internal formr name of the initial survey
#' @param daily_survey_name  string the internal formr name of the daily survey
#' @param final_survey_name  string the internal formr name of the final survey
#'
#' @export
#'
#' @examples fetch_survey_data("test@test.de", "passwort123", "initial_survey", "daily_survey")
fetch_survey_data <- function(formr_email, formr_password, initial_survey_name, daily_survey_name, final_survey_name) {
  if (missing(formr_email) || missing(formr_password)) {
    print("Formr Login-Informationen fehlen!")
  } else {
    formr::formr_connect(formr_email, formr_password)

    if(missing(initial_survey_name)) {
      print("Kein Parameter für Namen der initialen Umfrage angegeben.")
    } else {
      initial_survey <- formr::formr_raw_results(initial_survey_name)
      assign("initial_survey", initial_survey, envir = .GlobalEnv)
    }

    if(missing(daily_survey_name)) {
      print("Kein Parameter für Namen der täglichen Umfrage angegeben.")
    } else {
      daily_survey <- formr::formr_raw_results(daily_survey_name)
      assign("daily_survey", daily_survey, envir = .GlobalEnv)
    }

    if(missing(final_survey_name)) {
      print("Kein Parameter für Namen der finalen Umfrage angegeben.")
    } else {
      final_survey <- formr::formr_raw_results(final_survey_name)
      assign("final_survey", final_survey, envir = .GlobalEnv)
    }
  }
}


#' Function that returns esm and screen time data of all survey participants
#'
#' @param previous_data data.frame already fetched before (can be left empty)
#'
#' @export
#'
#' @examples
#' data <- get_all_data()
#' write.csv(data, "all_data.csv", na = "", row.names = FALSE)
get_all_data <- function(previous_result = NULL) {
  env <- globalenv()
  all_sessions <- unique(na.omit(env$daily_survey$session))
  ignored_columns <- c("modified", "ended", "expired", "participant_email", "participant_api_key")
  assign('ignored_columns', ignored_columns, envir = .GlobalEnv)
  all_data <- NULL
  for (id in all_sessions) {
    # get the participants daily survey data
    daily_survey_data <- get_daily_survey_data(id)

    # filter already included dates
    previous_data <- previous_result[which(previous_result$session == id),]
    if (!is.null(previous_data) && nrow(previous_data) > 0) {
      daily_survey_data <- subset(daily_survey_data, !(daily_survey_data$date %in% previous_data$date) )
    }

    # get participants screen time data from the start to end of the survey
    screen_time_data <- get_screen_time_data_for_date(
      id,
      strftime(daily_survey_data$date[1], "%Y-%m-%d %H:%M:%S"),
      strftime(daily_survey_data$date[nrow(daily_survey_data)], "%Y-%m-%d %H:%M:%S")
    )

    # initial data
    initial_survey_data <- get_initial_survey_data(id)

    # final data
    final_survey_data <- get_final_survey_data(id)

    # merge data
    if (!is.null(screen_time_data) && nrow(screen_time_data) > 0) {
      result <- merge(daily_survey_data, screen_time_data, by = "date", all=TRUE)
    } else {
      result <- daily_survey_data
    }

    # merge with previous data
    if (!is.null(previous_data) && nrow(previous_data) > 0) {
      result <- plyr::rbind.fill(result, previous_data)
    }

    result <- transform(result, session = id)
    result <- merge(result, initial_survey_data, by = "session", all = TRUE)

    if (!is.null(final_survey_data) && nrow(final_survey_data) > 0) {
      result <- merge(result, final_survey_data, by = "session", all=TRUE)
    }

    if (!is.null(all_data)) {
      all_data <- plyr::rbind.fill(all_data, result)
    } else {
      all_data <- result
    }
    rm("daily_survey_data", "screen_time_data", "initial_survey_data", "final_survey_data", "previous_data", "result")
  }
  return(all_data)
}


#' Function to retrieve a single data set
#'
#' @param session_id string session id of the participant
#' @param rescue_time_api_key string rescue time api key of the participant
#' @param scope string rescue time scope (usually 'Activity')
#' @param all_data data.frame the data of all participants
#'
#' @return data.frame containing only the individuals data enriched with detailed screen time data
#' @export
#'
#' @examples
#' all_data <- read.csv("all_data.csv")
#' data <- get_single_data("1", "ABC", "Activity", all_data)
#' write.csv(data, "single_data.csv", na = "", row.names = FALSE)
get_single_data <- function(session_id, rescue_time_api_key, scope, all_data) {
  single_data <- all_data[which(grepl(session_id, all_data$session)),]
  if (!is.na(rescue_time_api_key)) {
    # get participants screen time data
    screen_time_data <- rescuetimewrapper::get_rescue_time_data(
      rescue_time_api_key,
      single_data$date[1],
      single_data$date[nrow(single_data)],
      scope,
      TRUE
    )
    screen_time_data <- add_prefix_to_columns(screen_time_data, "st_detailed", c("Date"))

    result <- merge(single_data, screen_time_data, by.x = "date", by.y = "Date", all=TRUE)
    return(result)
  } else {
    return(single_data)
  }
}



#' Helper function to get screen time data for a specific user on a specific day
#'
#' @param session string - internal formr session id
#' @param startdate string provided like "YYYY-mm-DD"
#' @param enddate string provided like "YYYY-mm-DD"
#'
#' @return data.frame with screen time data for session
get_screen_time_data_for_date <- function(session, startdate, enddate) {
  index <- which(grepl(session, initial_survey$session))
  key <- initial_survey[index, "participant_api_key"]

  # set start time to 00:00:00
  startdate <- strptime(startdate, "%Y-%m-%d %H:%M:%S")
  lubridate::hour(startdate) <- 0
  lubridate::minute(startdate) <- 0
  lubridate::second(startdate) <- 0
  startdate <- strftime(startdate, "%Y-%m-%d %H:%M:%S")

  # set end date to 23:59:59
  enddate <- strptime(enddate, "%Y-%m-%d %H:%M:%S")
  lubridate::hour(enddate) <- 23
  lubridate::minute(enddate) <- 59
  lubridate::second(enddate) <- 59
  enddate <- strftime(enddate, "%Y-%m-%d %H:%M:%S")

  # only query if a key is provided
  if (!is.na(key) && nchar(key) > 5) {
    tryCatch({
      data <- rescuetimewrapper::get_rescue_time_data_anonymized(key, startdate, enddate, "Category", TRUE)
      if (!is.null(data) && ncol(data) > 0) {
        colnames(data)[colnames(data) == "Date"] <- "date"
        data <- add_prefix_to_columns(data, "st", c("date", "session"))
        data <- transform(data, date = strftime(strptime(date, "%Y-%m-%d"), "%Y-%m-%d"))
        return(data)
      } else {
        return(c())
      }
    },
    error=function(cond) {
      message(paste("An error occured when fetching the screen time data for session ", key))
      message(". Error: ")
      message(cond)
      return(NULL)
    }
    )

  } else {
    return(c())
  }
}



#' Helper Method to add a prefix to all columns (which are not excluded)
#'
#' @param data data.frame with columns
#' @param prefix string prefix to be added
#' @param ignored_column_names list columns to be ignored
#'
#' @return data.frame with renamed columns
#'
#' @examples
#' data <- add_prefix_to_columns(data, "prefix", c("id"))
add_prefix_to_columns <- function(data, prefix, ignored_column_names) {
  for (i in 1:ncol(data)) {
    current_col_name <- colnames(data)[i]
    if (!current_col_name %in% ignored_column_names) {
      colnames(data)[i] <- tolower(paste(prefix, colnames(data)[i], sep = "_"))
    }
  }
  return(data)
}



#' Function that retreives the daily survey data of an participant
#'
#' @param id string the id of the participant
#'
#' @return data.frame with all daily survey entries from the participant
get_daily_survey_data <- function(id) {
  # get data
  data <- daily_survey[which(grepl(id, daily_survey$session)),]
  # remove ignored columns
  data <- data[ , -which(names(data) %in% ignored_columns)]
  # transform date to string
  data <- transform(data, created = strftime(strptime(created, "%Y-%m-%d %H:%M:%S"), "%Y-%m-%d"))
  # add prefixes to each column
  data <- add_prefix_to_columns(data, "esm", c("session","created"))
  # rename created column with date
  colnames(data)[colnames(data) == "created"] <- "date"
  # order data by date
  data <- data[order(data$date),]
  return(data)
}



#' Function that retrieves initial survey data of an participant
#'
#' @param id string session id of the participant
#'
#' @return data.frame with initial survey data
get_initial_survey_data <- function(id) {
  # get data for participant
  data <- initial_survey[which(grepl(id, initial_survey$session)),]
  # remove ignored columns
  data <- data[ , -which(names(data) %in% c(ignored_columns, "created"))]
  # add prefixes to each column
  data <- add_prefix_to_columns(data, "general", c("session"))
  return(data)
}


#' Function that retrieves final survey data of an participant
#'
#' @param id string session id of the participant
#'
#' @return data.frame with initial survey data
get_final_survey_data <- function(id) {
  if (exists("final_survey")) {
    # get data for participant
    data <- final_survey[which(grepl(id, final_survey$session)),]
    if (!is.null(data) && ncol(data) > 0 && nrow(data) > 0) {
      # remove ignored columns
      data <- data[ , -which(names(data) %in% c(ignored_columns, "created"))]
      # add prefixes to each column
      data <- add_prefix_to_columns(data, "final", c("session"))
      return(data)
    } else {
      return(NULL)
    }

  } else {
    return(NULL)
  }
}
