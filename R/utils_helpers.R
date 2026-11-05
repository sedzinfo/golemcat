##########################################################################################
# TRAITS
##########################################################################################
#' What each Big Five trait means
#'
#' One line per trait for the results page: what a high and a low score usually mean.
#'
#' @return A data frame with the columns \code{scale}, \code{about}, \code{low} and
#'   \code{high}, one row per trait of \code{\link{ipip50}}.
#' @noRd
trait_info <- function() {
  data.frame(
    scale = c("Openness", "Conscientiousness", "Extraversion", "Agreeableness", "Neuroticism"),
    about = c(
      "Curiosity, imagination and interest in ideas, art and new experiences.",
      "Organisation, dependability and care for detail and duties.",
      "Sociability, talkativeness and energy in the company of others.",
      "Warmth, cooperation and concern for other people.",
      "How easily stress, worry and changes of mood are felt."
    ),
    low = c(
      "prefers the familiar and the practical",
      "flexible and spontaneous, sometimes less organised",
      "reserved, comfortable with time alone",
      "direct and competitive, puts own view first",
      "calm and even-tempered under pressure"
    ),
    high = c(
      "inventive and curious, enjoys new ideas",
      "organised, thorough and reliable",
      "outgoing, energetic and talkative",
      "friendly, trusting and helpful",
      "feels stress and worry more easily"
    ),
    stringsAsFactors = FALSE
  )
}
##########################################################################################
#
##########################################################################################
#' A percentile in words
#'
#' @param p Percentile, 0 to 100.
#'
#' @return A character vector such as \code{"higher than about 72\% of people"}.
#' @noRd
percentile_text <- function(p) {
  p <- pmin(pmax(round(p), 1), 99)
  ifelse(p >= 50,
    sprintf("higher than about %d%% of people", p),
    sprintf("lower than about %d%% of people", 100 - p)
  )
}
