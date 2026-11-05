##########################################################################################
# ITEM BANK
##########################################################################################
# A questionnaire is two csv files. The item bank, one row per item:
#   scale, question        item text
#   a1, b1..b4, c          mirt rsm coefficients
#   prior_sd               sd of the latent theta distribution of the scale
#   stem                   optional, instruction shown above the item
#   reverse                optional TRUE/FALSE, the answer is reversed (6 - answer) before
#                          scoring, for items that were recoded that way before the mirt fit
# and the answer options (likert), one row per option: value 1..5, label.
# mirt rsm: P(X=k) proportional to exp(sum_{t<=k} (theta - b_t + c)), a1 fixed at 1. The engine
# (fct_rsm.R) uses exp(sum_{t<=k} (theta - (lambdaj + delta_t))), so lambdaj = -c and
# delta_t = b_t with D = 1. Mind the minus sign: lambdaj = +c only looks right on the first
# item of each scale, where mirt fixes c = 0.
# mirt fixes the latent mean at 0 and estimates the variance per scale, so the EAP prior is
# N(0, prior_sd) per scale, not N(0, 1).
##########################################################################################
#' Read an item bank
#'
#' Reads the item bank of a questionnaire, fitted with the rating scale model of
#' \code{mirt} (\code{itemtype = "rsm"}), and converts the coefficients to the form of
#' the engine (\code{\link{Pi_rsm}}): \eqn{\lambda_j = -c} and \eqn{\delta_t = b_t}.
#' It stops with a message naming the problem when the file is not a complete rating
#' scale bank, so that an app does not start and then fail on the first answer.
#'
#' The csv has one row per item, with the columns \code{scale} and \code{question}
#' (the text of the item); \code{a1}, \code{b1} to \code{b4} and \code{c}, the
#' coefficients of \code{mirt}; and \code{prior_sd}, the standard deviation of the
#' latent distribution of the scale, which \code{mirt} estimates. Optional columns:
#' \code{stem}, the instruction shown above the item, and \code{reverse}
#' (\code{TRUE}/\code{FALSE}), for items whose answers were reversed (6 - answer)
#' before the fit. Other columns are ignored.
#'
#' @param items_csv Path to the csv file, saved as UTF-8.
#'
#' @return A data frame, one row per item: \code{scale}, \code{question}, \code{stem},
#'   \code{reverse}, \code{lambdaj}, \code{delta1} to \code{delta4}, \code{prior_mean}
#'   (always 0) and \code{prior_sd}.
#' @family item bank
#' @export
#'
#' @examples
#' bank <- read_item_bank(system.file("extdata", "ipip50_items.csv", package = "golemcat"))
#' head(bank[, c("scale", "question", "reverse", "lambdaj")])
read_item_bank <- function(items_csv) {
  d <- utils::read.csv(items_csv, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
  pars <- c("a1", "b1", "b2", "b3", "b4", "c", "prior_sd")
  miss <- setdiff(c("scale", "question", pars), names(d))
  if (length(miss)) stop(items_csv, " is missing columns: ", paste(miss, collapse = ", "), call. = FALSE)
  if (nrow(d) == 0) stop(items_csv, " has no items (is it saved as UTF-8?)", call. = FALSE)
  if (any(grepl("^b[5-9]$", names(d)))) {
    stop(items_csv, " has more than 4 thresholds (b5...): the fit had more than 5 answer categories, ",
      "e.g. a 0 = missing code left in the data; the app needs exactly 5",
      call. = FALSE
    )
  }
  bad <- !stats::complete.cases(d[, pars]) | !is.finite(d$prior_sd) | d$prior_sd <= 0
  if (any(bad)) stop(items_csv, ": missing or invalid parameters in rows ", paste(which(bad) + 1, collapse = ", "), call. = FALSE)
  if (!all(d$a1 == 1)) stop(items_csv, ": a1 != 1, not a mirt rsm fit", call. = FALSE)
  shared <- tapply(seq_len(nrow(d)), d$scale, function(i) {
    all(sapply(d[i, c("b1", "b2", "b3", "b4", "prior_sd")], function(x) length(unique(x)) == 1))
  })
  if (!all(shared)) {
    stop(items_csv, ": b1..b4 and prior_sd must be the same for every item of a scale, not in: ",
      paste(names(shared)[!shared], collapse = ", "),
      call. = FALSE
    )
  }
  reverse <- if (is.null(d$reverse)) rep(FALSE, nrow(d)) else as.logical(d$reverse)
  if (anyNA(reverse)) stop(items_csv, ": reverse must be TRUE or FALSE in every row", call. = FALSE)
  data.frame(
    scale = d$scale,
    question = d$question,
    stem = if (is.null(d$stem)) NA_character_ else d$stem,
    reverse = reverse,
    lambdaj = -d$c,
    delta1 = d$b1, delta2 = d$b2, delta3 = d$b3, delta4 = d$b4,
    prior_mean = 0, prior_sd = d$prior_sd,
    stringsAsFactors = FALSE
  )
}
##########################################################################################
# LIKERT
##########################################################################################
#' Read the answer options
#'
#' Reads the answer options of a questionnaire: a csv with the columns \code{value}
#' (1 to 5) and \code{label}, from the lowest to the highest agreement. The answer
#' \code{v} is scored as category \code{v - 1} of the rating scale model
#' (\code{5 - v} on reversed items), so with the 4 thresholds \code{b1} to \code{b4}
#' there must be exactly the values 1 to 5.
#'
#' @param likert_csv Path to the csv file, saved as UTF-8.
#'
#' @return A data frame with the columns \code{value} and \code{label}, ordered by value.
#' @family item bank
#' @export
#'
#' @examples
#' read_likert(system.file("extdata", "ipip50_likert.csv", package = "golemcat"))
read_likert <- function(likert_csv) {
  l <- utils::read.csv(likert_csv, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
  if (!all(c("value", "label") %in% names(l))) stop(likert_csv, " must have columns value and label", call. = FALSE)
  l <- l[order(l$value), c("value", "label")]
  if (!identical(as.integer(l$value), 1:5)) stop(likert_csv, ": value must be 1, 2, 3, 4, 5 (one row per answer option)", call. = FALSE)
  l
}
##########################################################################################
# IPIP-50
##########################################################################################
#' The IPIP-50 Big Five questionnaire
#'
#' The questionnaire built into the app: the 50 items of the IPIP Big-Five Factor
#' Markers (Goldberg, 1992; public domain), 10 per trait, with the coefficients of a
#' rating scale model fitted with \code{mirt} to each trait separately, on the
#' responses of 19,718 people to the Big Five test of the Open-Source Psychometrics
#' Project. The 18 reverse-keyed items were reversed (6 - answer) before the fit.
#'
#' @return A list: \code{bank}, the item bank (see \code{\link{read_item_bank}}), with
#'   the traits in the order Openness, Conscientiousness, Extraversion, Agreeableness,
#'   Neuroticism, and \code{likert}, the five answer options (see
#'   \code{\link{read_likert}}).
#' @family item bank
#' @export
#'
#' @examples
#' q <- ipip50()
#' table(q$bank$scale)
#' q$likert
ipip50 <- function() {
  bank <- read_item_bank(app_sys("extdata", "ipip50_items.csv"))
  ocean <- c("Openness", "Conscientiousness", "Extraversion", "Agreeableness", "Neuroticism")
  bank <- bank[order(match(bank$scale, ocean)), ]
  rownames(bank) <- NULL
  list(bank = bank, likert = read_likert(app_sys("extdata", "ipip50_likert.csv")))
}
##########################################################################################
# CHECK AGAINST MIRT
##########################################################################################
#' Check an item bank against its mirt model
#'
#' Compares the response probabilities of the engine with those of the fitted
#' \code{mirt} model, item by item, so that a sign or mapping mistake does not go
#' unnoticed (a check on the first item alone passes either way, since \code{mirt}
#' fixes \code{c = 0} there). Items are matched by name: \code{make.names()} of the
#' question must be the item name in the model. Needs the \code{mirt} package.
#'
#' @param bank_scale The rows of one scale of an item bank read with
#'   \code{\link{read_item_bank}}.
#' @param mirt_model The \code{mirt} model fitted to that scale.
#' @param thetas Ability values at which the probabilities are compared.
#' @param tol Largest difference accepted.
#'
#' @return The largest difference, invisibly; a warning when it is above \code{tol}.
#' @family item bank
#' @export
#'
#' @examples
#' \dontrun{
#' bank <- read_item_bank("items.csv")
#' validate_item_bank_against_mirt(bank[bank$scale == "Openness", ], model_openness)
#' }
validate_item_bank_against_mirt <- function(bank_scale, mirt_model, thetas = seq(-4, 4, 0.5), tol = 1e-6) {
  if (!requireNamespace("mirt", quietly = TRUE)) stop("mirt is required to validate", call. = FALSE)
  mat <- as.matrix(bank_scale[, c("lambdaj", "delta1", "delta2", "delta3", "delta4")])
  item_names <- make.names(bank_scale$question)
  if (!setequal(item_names, mirt::extract.mirt(mirt_model, "itemnames"))) {
    stop("bank_scale and mirt_model do not have the same items", call. = FALSE)
  }
  max_diff <- 0
  for (j in seq_len(nrow(mat))) {
    mirt_p <- mirt::probtrace(mirt::extract.item(mirt_model, item_names[j]), thetas)
    engine_p <- t(sapply(thetas, function(th) Pi_rsm(th, mat[j, , drop = FALSE])$Pi))
    max_diff <- max(max_diff, abs(engine_p - mirt_p))
  }
  if (max_diff > tol) {
    warning("engine and mirt disagree by ", signif(max_diff, 3), " (tol=", tol, ") - check the lambdaj/delta mapping in read_item_bank()", call. = FALSE)
  } else {
    message("OK: engine matches mirt within ", tol, " (max diff ", signif(max_diff, 3), ")")
  }
  invisible(max_diff)
}
