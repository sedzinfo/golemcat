##########################################################################################
# CAT SESSION: one adaptive test across one or more scales, one scale at a time. Plain
# functions on a list, so the two tabs of the app share them and they can be tested
# without shiny.
##########################################################################################
#' Start an adaptive test
#'
#' Starts a computerized adaptive test (CAT) over the chosen scales of an item bank,
#' one scale at a time, in the order given. Within a scale, each next item is the most
#' informative one left (\code{\link{next_item_rsm}}); after each answer the ability is
#' estimated again by EAP (\code{\link{eap_est_rsm}}), with the normal prior of the
#' scale, over a grid of \eqn{\pm 6} prior standard deviations. A scale stops when the
#' standard error, divided by the prior standard deviation, is at most
#' \code{se_threshold}, or when its items run out; the test then moves to the next scale.
#'
#' Abilities and standard errors are reported standardized per scale (divided by the
#' prior standard deviation), so the same threshold is the same target in every scale:
#' a threshold \code{se} aims at a reliability of about \eqn{1 - se^2}.
#'
#' @param bank An item bank read with \code{\link{read_item_bank}}.
#' @param scales The scales to test, in order.
#' @param se_threshold Standardized standard error at which a scale stops.
#'
#' @return A CAT session: a list to pass to \code{\link{cat_answer}},
#'   \code{\link{cat_item}} and \code{\link{cat_results}}. Its \code{stage} is
#'   \code{"testing"} until the last scale stops, then \code{"done"}; \code{progress}
#'   has one row per scale and \code{log} one row per answer.
#' @family CAT session
#' @export
#'
#' @examples
#' q <- ipip50()
#' s <- cat_start(q$bank, scales = "Extraversion", se_threshold = 0.45)
#' while (s$stage == "testing") s <- cat_answer(s, 4) # always "Moderately accurate"
#' cat_results(s)
#' s$log
cat_start <- function(bank, scales = unique(bank$scale), se_threshold = 0.45) {
  scales <- as.character(scales)
  unknown <- setdiff(scales, bank$scale)
  if (!length(scales)) stop("choose at least one scale", call. = FALSE)
  if (length(unknown)) stop("not in the item bank: ", paste(unknown, collapse = ", "), call. = FALSE)
  s <- list(
    stage = "testing",
    bank = bank,
    scales = scales,
    se_threshold = se_threshold,
    progress = data.frame(
      scale = scales,
      total = vapply(scales, function(x) sum(bank$scale == x), integer(1), USE.NAMES = FALSE),
      answered = 0L,
      theta = NA_real_,
      se = NA_real_,
      status = "pending",
      stringsAsFactors = FALSE
    ),
    log = data.frame(
      step = integer(0), scale = character(0), question = character(0),
      answer = integer(0), theta = numeric(0), se = numeric(0), stringsAsFactors = FALSE
    )
  )
  cat_start_scale(s, 1L)
}
##########################################################################################
#
##########################################################################################
#' Start one scale of a CAT session
#'
#' @param s A CAT session.
#' @param idx Index of the scale in \code{s$scales}.
#'
#' @return The session, with the first item of the scale selected.
#' @noRd
cat_start_scale <- function(s, idx) {
  d <- s$bank[s$bank$scale == s$scales[idx], ]
  s$idx <- idx
  s$scale_meta <- d
  s$scale_matrix <- as.matrix(d[, c("lambdaj", "delta1", "delta2", "delta3", "delta4")])
  s$prior <- c(d$prior_mean[1], d$prior_sd[1])
  s$administered <- integer(0)
  s$responses <- integer(0)
  s$theta <- s$prior[1]
  s$se <- NA_real_
  s$current_item <- next_item_rsm(theta = s$theta, bank = s$scale_matrix, out = integer(0))$item
  s$progress$status[idx] <- "in progress"
  s
}
##########################################################################################
#
##########################################################################################
#' The item to show now
#'
#' @param s A CAT session.
#'
#' @return A list with the \code{scale}, the \code{stem} (\code{NA} when the bank has
#'   none) and the \code{question} of the current item, or \code{NULL} when the test is
#'   done.
#' @family CAT session
#' @export
#'
#' @examples
#' s <- cat_start(ipip50()$bank, scales = "Openness")
#' cat_item(s)
cat_item <- function(s) {
  if (s$stage != "testing") return(NULL)
  row <- s$scale_meta[s$current_item, ]
  list(scale = row$scale, stem = row$stem, question = row$question)
}
##########################################################################################
#
##########################################################################################
#' Answer the current item
#'
#' Scores the answer (category \code{answer - 1}, or \code{5 - answer} on a reversed
#' item), estimates the ability and its standard error again, and either selects the
#' next item of the scale or, when the scale stops, moves to the next scale or ends the
#' test.
#'
#' @param s A CAT session.
#' @param answer The answer, 1 to 5, as shown to the person (before any reversal).
#'
#' @return The updated session.
#' @family CAT session
#' @export
#'
#' @examples
#' s <- cat_start(ipip50()$bank, scales = "Openness")
#' s <- cat_answer(s, 5)
#' s$progress
cat_answer <- function(s, answer) {
  if (s$stage != "testing") stop("the test is already done", call. = FALSE)
  answer <- as.integer(answer)
  if (length(answer) != 1 || is.na(answer) || answer < 1L || answer > 5L) {
    stop("the answer must be 1, 2, 3, 4 or 5", call. = FALSE)
  }
  # rsm category 0..4; reverse-keyed items were recoded 6 - answer before the mirt fit
  x <- if (s$scale_meta$reverse[s$current_item]) 5L - answer else answer - 1L
  s$administered <- c(s$administered, s$current_item)
  s$responses <- c(s$responses, x)

  mat_admin <- s$scale_matrix[s$administered, , drop = FALSE]
  # grid of +/- 6 prior sd: the default -4..4 truncates the posterior on scales with sd > 2
  lim <- s$prior[1] + c(-6, 6) * s$prior[2]
  theta <- eap_est_rsm(mat_admin, s$responses, priorPar = s$prior, lower = lim[1], upper = lim[2], nqp = 61)
  se <- eap_se_rsm(theta, mat_admin, s$responses, priorPar = s$prior, lower = lim[1], upper = lim[2], nqp = 61)
  s$theta <- theta
  s$se <- se
  theta_z <- (theta - s$prior[1]) / s$prior[2]
  se_z <- se / s$prior[2]

  idx <- s$idx
  n_admin <- length(s$administered)
  s$progress$answered[idx] <- n_admin
  s$progress$theta[idx] <- theta_z
  s$progress$se[idx] <- se_z
  s$log <- rbind(s$log, data.frame(
    step = nrow(s$log) + 1L,
    scale = s$scales[idx],
    question = s$scale_meta$question[s$administered[n_admin]],
    answer = answer,
    theta = theta_z,
    se = se_z,
    stringsAsFactors = FALSE
  ))

  if (se_z <= s$se_threshold || n_admin >= nrow(s$scale_matrix)) {
    s$progress$status[idx] <- "completed"
    if (idx < length(s$scales)) {
      s <- cat_start_scale(s, idx + 1L)
    } else {
      s$stage <- "done"
    }
  } else {
    s$current_item <- next_item_rsm(theta, s$scale_matrix, out = s$administered)$item
  }
  s
}
##########################################################################################
#
##########################################################################################
#' Results of a CAT session
#'
#' The standardized ability of each scale, its standard error, and the percentile: the
#' share of the population of the calibration sample expected below that ability,
#' assuming a normal distribution (\code{pnorm} of the standardized ability).
#'
#' @param s A CAT session.
#'
#' @return A data frame, one row per scale: \code{scale}, \code{theta} and \code{se}
#'   (standardized), \code{percentile} (0 to 100), \code{answered}, \code{total} and
#'   \code{status}.
#' @family CAT session
#' @export
#'
#' @examples
#' s <- cat_start(ipip50()$bank, scales = c("Openness", "Neuroticism"))
#' while (s$stage == "testing") s <- cat_answer(s, 2)
#' cat_results(s)
cat_results <- function(s) {
  p <- s$progress
  data.frame(
    scale = p$scale,
    theta = p$theta,
    se = p$se,
    percentile = 100 * stats::pnorm(p$theta),
    answered = p$answered,
    total = p$total,
    status = p$status,
    stringsAsFactors = FALSE
  )
}
