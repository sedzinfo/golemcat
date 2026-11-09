##########################################################################################
# QUESTIONNAIRE CSV: one file, one row per item, for any of the six IRT models
##########################################################################################
# Columns (names as mirt gives them, so that coef(fit, simplify = TRUE)$items can be
# pasted in as it is):
#   scale, question          required
#   itemtype                 required, the mirt itemtype of the item: rsm, Rasch, graded,
#                            grsm, 2PL, 3PL, 4PL or nominal (one model per scale)
#   item, stem               optional: an id, and an instruction shown above the item
#   option1, option2, ...    the answer options in the order they were scored (1 = the
#                            lowest category); without them the options are numbered
#   key                      dichotomous items given as several options: the number of
#                            the correct option (scored 1, every other option 0)
#   reverse                  optional TRUE/FALSE: the answer is reversed before scoring
#                            (ordered polytomous models only)
#   public                   optional TRUE/FALSE: FALSE when the text of the item is not
#                            public and only a placeholder is shown; the CAT tab then
#                            highlights the correct option (key) in yellow
#   a1, d, g, u              2PL/3PL/4PL (and Rasch with two categories)
#   a1, b1..bK, c            rsm and grsm
#   a1, d1..dK               graded
#   a1, ak0..akK, d0..dK     Rasch with more than two categories (partial credit) and nominal
#   prior_mean, prior_sd     mean and sd of the latent trait of the scale (default 0 and 1;
#                            mirt estimates the sd for rsm and Rasch)
# The engines take the catR parameterisation, so every row is converted, model by model
# (all checked against mirt::probtrace to 1e-15):
#   graded   a = a1, b_k = -d_k / a1                       -> GRM
#   Rasch    delta_t = d_(t-1) - d_t                       -> PCM
#   grsm     alpha = a1, b = -c, c_k = b_k                 -> MGRM
#   2-4PL    a = a1, b = -d / a1, c = g, d = u             -> 4PL
#   nominal  alpha_k = a1 (ak_k - ak_0), c_k = d_k - d_0   -> NRM
#   rsm      lambda = -c, delta_t = b_t                    -> RSM
##########################################################################################
#' The IRT models
#'
#' The six models a questionnaire can use, with the \code{mirt} itemtypes that map to
#' each one.
#'
#' @return A data frame: \code{model} (the engine), \code{label} and \code{itemtypes}.
#' @family questionnaire
#' @export
#'
#' @examples
#' irt_models()
irt_models <- function() {
  data.frame(
    model = c("rsm", "pcm", "grm", "mgrm", "dichotomous", "nrm"),
    label = c(
      "Rating scale model (RSM)", "Partial credit model (PCM)", "Graded response model (GRM)",
      "Modified graded response model (MGRM)", "Dichotomous (1PL to 4PL)", "Nominal response model (NRM)"
    ),
    itemtypes = c("rsm", "Rasch (3+ categories)", "graded", "grsm", "Rasch (2 categories), 2PL, 3PL, 4PL", "nominal"),
    stringsAsFactors = FALSE
  )
}
##########################################################################################
#
##########################################################################################
#' The engine of a model
#'
#' @param model One of \code{irt_models()$model}.
#'
#' @return A list of functions: \code{pi} (category probabilities), \code{next_item},
#'   \code{eap} and \code{se}.
#' @noRd
engine_of <- function(model) {
  switch(model,
    rsm = list(pi = Pi_rsm, next_item = next_item_rsm, eap = eap_est_rsm, se = eap_se_rsm),
    pcm = list(pi = compute_pi_pcm, next_item = compute_next_item_pcm, eap = compute_eap_pcm, se = compute_eap_se_pcm),
    grm = list(pi = compute_pi_grm, next_item = compute_next_item_grm, eap = compute_eap_grm, se = compute_eap_se_grm),
    mgrm = list(pi = compute_pi_ggrm, next_item = compute_next_item_ggrm, eap = compute_eap_ggrm, se = compute_eap_se_ggrm),
    dichotomous = list(
      # the 4PL engine gives P(correct) only: the two categories are wrong, right
      pi = function(theta, bank, D = 1) {
        p <- compute_pi_dichotomous(theta, bank, D = D)$Pi
        list(Pi = cbind(cat0 = 1 - p, cat1 = p))
      },
      next_item = compute_next_item_dichotomous, eap = compute_eap_dichotomous, se = compute_eap_se_dichotomous
    ),
    nrm = list(pi = compute_pi_nrm, next_item = compute_next_item_nrm, eap = compute_eap_nrm, se = compute_eap_se_nrm),
    stop("unknown model: ", model, call. = FALSE)
  )
}
##########################################################################################
#
##########################################################################################
#' Columns of a family, in numeric order (b1, b2, ..., b10)
#' @noRd
numbered_cols <- function(d, prefix) {
  cols <- grep(paste0("^", prefix, "[0-9]+$"), names(d), value = TRUE)
  cols[order(as.integer(sub(prefix, "", cols, fixed = TRUE)))]
}
#' One row's values of some columns, without the missing ones
#' @noRd
row_values <- function(d, i, cols) {
  if (!length(cols)) return(numeric(0))
  v <- suppressWarnings(as.numeric(unlist(d[i, cols])))
  v[!is.na(v)]
}
#' One numeric value of a row, or a default when the column is missing or empty
#' @noRd
row_value <- function(d, i, col, default = NA_real_) {
  if (is.null(d[[col]])) return(default)
  v <- suppressWarnings(as.numeric(d[[col]][i]))
  if (is.na(v)) default else v
}
##########################################################################################
#
##########################################################################################
#' Convert one item from mirt to the engine
#'
#' @param d The questionnaire, as read from the csv.
#' @param i Row.
#'
#' @return A list: \code{model}, \code{par} (the engine parameters) and \code{n_cat}.
#' @noRd
item_to_engine <- function(d, i) {
  # mirt calls grsm items after the first one "grsmIRT"
  type <- sub("irt$", "", tolower(trimws(d$itemtype[i])))
  a1 <- row_value(d, i, "a1")
  need <- function(x, what) {
    if (!length(x) || anyNA(x)) stop(sprintf("row %d (%s): missing %s", i + 1, d$itemtype[i], what), call. = FALSE)
    x
  }
  if (type == "rasch" && !length(row_values(d, i, numbered_cols(d, "d")))) type <- "rasch2"
  switch(type,
    rsm = {
      b <- need(row_values(d, i, numbered_cols(d, "b")), "b1, b2, ...")
      list(model = "rsm", par = c(-row_value(d, i, "c", 0), b), n_cat = length(b) + 1L)
    },
    grsm = {
      b <- need(row_values(d, i, numbered_cols(d, "b")), "b1, b2, ...")
      list(model = "mgrm", par = c(need(a1, "a1"), -row_value(d, i, "c", 0), b), n_cat = length(b) + 1L)
    },
    graded = {
      dk <- need(row_values(d, i, numbered_cols(d, "d")), "d1, d2, ...")
      if (!is.finite(a1) || a1 <= 0) stop(sprintf("row %d: a1 must be a positive number for graded items", i + 1), call. = FALSE)
      list(model = "grm", par = c(a1, -dk / a1), n_cat = length(dk) + 1L)
    },
    rasch = {
      dd <- need(row_values(d, i, numbered_cols(d, "d")), "d0, d1, ...")
      list(model = "pcm", par = dd[-length(dd)] - dd[-1], n_cat = length(dd))
    },
    nominal = {
      ak <- need(row_values(d, i, numbered_cols(d, "ak")), "ak0, ak1, ...")
      dd <- need(row_values(d, i, numbered_cols(d, "d")), "d0, d1, ...")
      if (length(ak) != length(dd)) stop(sprintf("row %d: as many ak as d columns are needed", i + 1), call. = FALSE)
      alpha <- need(a1, "a1") * (ak - ak[1])
      cc <- dd - dd[1]
      list(model = "nrm", par = as.vector(rbind(alpha[-1], cc[-1])), n_cat = length(ak))
    },
    rasch2 = , `2pl` = , `3pl` = , `4pl` = {
      dd <- need(row_value(d, i, "d"), "d")
      a <- if (type == "rasch2") 1 else need(a1, "a1")
      if (a <= 0) stop(sprintf("row %d: a1 must be positive", i + 1), call. = FALSE)
      list(model = "dichotomous", par = c(a, -dd / a, row_value(d, i, "g", 0), row_value(d, i, "u", 1)), n_cat = 2L)
    },
    stop(sprintf(
      "row %d: itemtype '%s' is not supported; use rsm, Rasch, graded, grsm, 2PL, 3PL, 4PL or nominal",
      i + 1, d$itemtype[i]
    ), call. = FALSE)
  )
}
##########################################################################################
#
##########################################################################################
#' Read a questionnaire
#'
#' Reads a questionnaire from a csv file, one row per item, for any of the six IRT
#' models of \code{\link{irt_models}}: the items, their answer options and the
#' coefficients of the item response model fitted with \code{mirt}, in \code{mirt}'s
#' own column names (see \code{\link{questionnaire_from_mirt}}, which writes such a
#' table from a fitted model). The coefficients are converted to the parameters of the
#' engine of the model. It stops with a message naming the row and the problem, so that
#' a test does not start on a broken file.
#'
#' The columns are \code{scale}, \code{question} and \code{itemtype} (required);
#' \code{item} and \code{stem} (optional); \code{option1}, \code{option2}, ... (the
#' answer options in scoring order, numbered when absent); \code{key} (the correct
#' option of a dichotomous item given as several options); \code{reverse} (ordered
#' polytomous items scored in reverse); \code{public} (\code{FALSE} when the text of
#' the item is not public and only a placeholder is shown, so that the CAT tab
#' highlights the correct option); the coefficients (\code{a1}, \code{b1}...,
#' \code{c}, \code{d}, \code{d0}..., \code{ak0}..., \code{g}, \code{u}, as \code{mirt}
#' names them); and \code{prior_mean} and \code{prior_sd}, the mean and standard
#' deviation of the latent trait of each scale (0 and 1 when absent).
#'
#' @param file Path to the csv file, saved as UTF-8; or a data frame with the same
#'   columns.
#'
#' @return The item bank: a data frame with one row per item and the columns
#'   \code{scale}, \code{item}, \code{question}, \code{stem}, \code{model},
#'   \code{n_cat}, \code{n_options}, \code{options} (a list), \code{key},
#'   \code{reverse}, \code{public}, \code{prior_mean}, \code{prior_sd} and \code{par1},
#'   \code{par2}, ... (the engine parameters). It can be given to
#'   \code{\link{cat_start}}.
#' @family questionnaire
#' @export
#'
#' @examples
#' q <- read_questionnaire(example_questionnaires()[5]) # SAT12, 3PL
#' table(q$scale, q$model)
#' q$options[[1]]
read_questionnaire <- function(file) {
  d <- if (is.data.frame(file)) file else utils::read.csv(file, fileEncoding = "UTF-8", stringsAsFactors = FALSE, check.names = FALSE)
  src <- if (is.data.frame(file)) "the questionnaire" else basename(file)
  fail <- function(...) stop(src, ": ", ..., call. = FALSE)
  if (!nrow(d)) fail("no items (is it saved as UTF-8?)")
  miss <- setdiff(c("scale", "question", "itemtype"), names(d))
  if (length(miss)) fail("missing columns: ", paste(miss, collapse = ", "))
  d$scale <- trimws(as.character(d$scale))
  if (any(is.na(d$scale) | d$scale == "")) fail("every item needs a scale")

  conv <- tryCatch(lapply(seq_len(nrow(d)), function(i) item_to_engine(d, i)), error = function(e) fail(conditionMessage(e)))
  model <- vapply(conv, `[[`, "", "model")
  n_cat <- vapply(conv, `[[`, 0L, "n_cat")
  not_finite <- which(!vapply(conv, function(x) all(is.finite(x$par)), TRUE))
  if (length(not_finite)) fail("coefficients that are not finite numbers in rows ", paste(not_finite + 1, collapse = ", "))
  mixed <- tapply(model, d$scale, function(x) length(unique(x)) > 1)
  if (any(mixed)) fail("one model per scale, but these scales mix models: ", paste(names(mixed)[mixed], collapse = ", "))

  # answer options: option1, option2, ... in scoring order; numbered when absent
  opt_cols <- numbered_cols(d, "option")
  options <- lapply(seq_len(nrow(d)), function(i) {
    o <- if (length(opt_cols)) trimws(as.character(unlist(d[i, opt_cols]))) else character(0)
    o <- o[!is.na(o) & o != ""]
    if (!length(o)) o <- as.character(seq_len(n_cat[i]))
    o
  })
  n_options <- lengths(options)
  key <- if (is.null(d$key)) rep(NA_integer_, nrow(d)) else suppressWarnings(as.integer(d$key))
  reverse <- if (is.null(d$reverse)) rep(FALSE, nrow(d)) else as.logical(d$reverse)
  reverse[is.na(reverse)] <- FALSE
  public <- if (is.null(d$public)) rep(TRUE, nrow(d)) else as.logical(d$public)
  public[is.na(public)] <- TRUE
  for (i in seq_len(nrow(d))) {
    if (model[i] == "dichotomous" && !is.na(key[i])) {
      if (key[i] < 1 || key[i] > n_options[i]) fail(sprintf("row %d: key %d is not one of its %d options", i + 1, key[i], n_options[i]))
    } else if (n_options[i] != n_cat[i]) {
      fail(sprintf(
        "row %d: %d answer options but the model has %d categories%s", i + 1, n_options[i], n_cat[i],
        if (model[i] == "dichotomous") " (give the correct option in a key column)" else ""
      ))
    }
    if (reverse[i] && model[i] %in% c("dichotomous", "nrm")) {
      fail(sprintf("row %d: reverse is only for ordered polytomous items (rsm, Rasch, graded, grsm)", i + 1))
    }
  }

  prior_mean <- vapply(seq_len(nrow(d)), function(i) row_value(d, i, "prior_mean", 0), 0)
  prior_sd <- vapply(seq_len(nrow(d)), function(i) row_value(d, i, "prior_sd", 1), 0)
  if (!all(is.finite(prior_mean)) || !all(is.finite(prior_sd)) || any(prior_sd <= 0 | prior_sd > 100)) {
    fail("prior_mean must be a number, and prior_sd a number above 0 and at most 100")
  }
  uneven <- tapply(seq_len(nrow(d)), d$scale, function(i) length(unique(prior_mean[i])) > 1 || length(unique(prior_sd[i])) > 1)
  if (any(uneven)) fail("prior_mean and prior_sd must be the same for every item of a scale, not in: ", paste(names(uneven)[uneven], collapse = ", "))

  n_par <- max(lengths(lapply(conv, `[[`, "par")))
  par <- do.call(rbind, lapply(conv, function(x) c(x$par, rep(NA_real_, n_par - length(x$par)))))
  colnames(par) <- paste0("par", seq_len(n_par))
  stem <- if (is.null(d$stem)) rep(NA_character_, nrow(d)) else as.character(d$stem)
  stem[!is.na(stem) & trimws(stem) == ""] <- NA_character_
  bank <- data.frame(
    scale = d$scale,
    item = if (is.null(d$item)) as.character(d$question) else as.character(d$item),
    question = as.character(d$question),
    stem = stem,
    model = model,
    n_cat = n_cat,
    n_options = n_options,
    key = key,
    reverse = reverse,
    public = public,
    prior_mean = prior_mean,
    prior_sd = prior_sd,
    par,
    stringsAsFactors = FALSE
  )
  bank$options <- options
  bank
}
##########################################################################################
#
##########################################################################################
#' A questionnaire table from a mirt model
#'
#' Turns a unidimensional model fitted with \code{mirt} into the rows of a
#' questionnaire csv (see \code{\link{read_questionnaire}}): the coefficients of each
#' item (\code{coef(fit, simplify = TRUE)}), the mean and standard deviation of the
#' latent trait, and the text and answer options of the items. Fit one model per
#' scale, bind the tables of the scales with \code{rbind()} and save them with
#' \code{\link{write_questionnaire}}.
#'
#' @param fit A unidimensional model fitted with \code{mirt::mirt()}, with itemtype
#'   \code{rsm}, \code{Rasch}, \code{graded}, \code{grsm}, \code{2PL}, \code{3PL},
#'   \code{4PL} or \code{nominal}.
#' @param scale The name of the scale.
#' @param question The text of the items, in the order of the model; the item names
#'   when \code{NULL}.
#' @param options The answer options: one character vector for all the items, or a list
#'   with one vector per item, in scoring order (the lowest category first). Numbered
#'   when \code{NULL}.
#' @param key For dichotomous items given as several options: the number of the
#'   correct option of each item.
#' @param reverse \code{TRUE} for items whose answers were reversed before the fit.
#' @param stem An instruction shown above the items.
#' @param public \code{FALSE} when the texts of the items are not public and
#'   \code{question} is only a placeholder: the CAT tab then highlights the correct
#'   option of keyed items.
#'
#' @return A data frame, one row per item.
#' @family questionnaire
#' @export
#'
#' @examples
#' \dontrun{
#' fit <- mirt::mirt(responses, 1, itemtype = "graded")
#' q <- questionnaire_from_mirt(fit, "Anxiety",
#'   question = c("I worry a lot", "I feel tense"),
#'   options = c("Never", "Sometimes", "Often", "Always")
#' )
#' write_questionnaire(q, "anxiety.csv")
#' }
questionnaire_from_mirt <- function(fit, scale, question = NULL, options = NULL, key = NULL, reverse = FALSE, stem = NA, public = TRUE) {
  if (!requireNamespace("mirt", quietly = TRUE)) stop("mirt is required", call. = FALSE)
  if (mirt::extract.mirt(fit, "nfact") != 1) stop("the model must be unidimensional (one factor)", call. = FALSE)
  co <- mirt::coef(fit, simplify = TRUE)
  items <- as.data.frame(co$items)
  n <- nrow(items)
  types <- sub("IRT$", "", mirt::extract.mirt(fit, "itemtype")) # grsmIRT -> grsm
  out <- data.frame(
    scale = scale,
    item = rownames(items),
    question = if (is.null(question)) rownames(items) else question,
    stem = stem,
    itemtype = types,
    stringsAsFactors = FALSE
  )
  if (!is.null(key)) out$key <- key
  if (!isFALSE(reverse)) out$reverse <- rep_len(as.logical(reverse), n)
  if (!isTRUE(public)) out$public <- rep_len(as.logical(public), n)
  if (!is.null(options)) {
    opts <- if (is.list(options)) options else rep(list(options), n)
    k <- max(lengths(opts))
    for (j in seq_len(k)) out[[paste0("option", j)]] <- vapply(opts, function(o) if (j <= length(o)) o[j] else NA_character_, "")
  }
  # mirt fills parameters an item does not have with NA; drop columns that are all NA
  items <- items[, colSums(!is.na(items)) > 0, drop = FALSE]
  out <- cbind(out, items)
  out$prior_mean <- unname(co$means[1])
  out$prior_sd <- sqrt(unname(co$cov[1, 1]))
  rownames(out) <- NULL
  out
}
##########################################################################################
#
##########################################################################################
#' Save a questionnaire table
#'
#' Writes a questionnaire table (\code{\link{questionnaire_from_mirt}}) as a UTF-8 csv
#' that \code{\link{read_questionnaire}} and the app read. When the scales have
#' different models, the columns are the union of theirs and empty where a model has
#' none.
#'
#' @param x A data frame, or a list of data frames (one per scale).
#' @param file Path of the csv file.
#'
#' @return \code{file}, invisibly. It stops if the file would not read back.
#' @family questionnaire
#' @export
write_questionnaire <- function(x, file) {
  if (!is.data.frame(x)) {
    cols <- unique(unlist(lapply(x, names)))
    x <- do.call(rbind, lapply(x, function(d) {
      d[setdiff(cols, names(d))] <- NA
      d[cols]
    }))
  }
  read_questionnaire(x) # stops here if it would not read back
  utils::write.csv(x, file, row.names = FALSE, na = "", fileEncoding = "UTF-8")
  invisible(file)
}
##########################################################################################
#
##########################################################################################
#' Check a questionnaire against its mirt model
#'
#' Compares the category probabilities of the engine with those of the fitted
#' \code{mirt} model, item by item, for any of the six models, so that a mapping
#' mistake does not go unnoticed. Items are matched by the \code{item} column.
#'
#' @param bank_scale The rows of one scale of a questionnaire read with
#'   \code{\link{read_questionnaire}}.
#' @param fit The \code{mirt} model fitted to that scale.
#' @param thetas Ability values at which the probabilities are compared.
#' @param tol Largest difference accepted.
#'
#' @return The largest difference, invisibly; a warning when it is above \code{tol}.
#' @family questionnaire
#' @export
validate_questionnaire_against_mirt <- function(bank_scale, fit, thetas = seq(-4, 4, 0.5), tol = 1e-6) {
  if (!requireNamespace("mirt", quietly = TRUE)) stop("mirt is required to validate", call. = FALSE)
  names_fit <- mirt::extract.mirt(fit, "itemnames")
  if (!all(bank_scale$item %in% names_fit)) stop("items not in the model: ", paste(setdiff(bank_scale$item, names_fit), collapse = ", "), call. = FALSE)
  e <- engine_of(bank_scale$model[1])
  mat <- bank_matrix(bank_scale)
  max_diff <- 0
  for (j in seq_len(nrow(mat))) {
    mirt_p <- mirt::probtrace(mirt::extract.item(fit, bank_scale$item[j]), thetas)
    engine_p <- t(vapply(thetas, function(th) {
      p <- e$pi(th, mat[j, , drop = FALSE])$Pi[1, ]
      p[seq_len(ncol(mirt_p))]
    }, numeric(ncol(mirt_p))))
    max_diff <- max(max_diff, abs(engine_p - mirt_p))
  }
  if (max_diff > tol) {
    warning("engine and mirt disagree by ", signif(max_diff, 3), " (tol = ", tol, ")", call. = FALSE)
  }
  invisible(max_diff)
}
##########################################################################################
# EXAMPLES
##########################################################################################
#' The example questionnaires
#'
#' The questionnaires that come with the app, one for each IRT model, made with
#' \code{\link{questionnaire_from_mirt}} (see \code{data-raw/examples.R}). The four
#' ordered polytomous models use the 50 IPIP Big-Five statements fitted to the
#' responses of 19,718 people (Open-Source Psychometrics Project); the dichotomous and
#' nominal models use the 32 multiple-choice items of the SAT12 science test of
#' \code{mirt}, scored right/wrong with its key and as given, option by option.
#'
#' @return A named character vector: the label of each questionnaire and the path of
#'   its csv.
#' @family questionnaire
#' @export
#'
#' @examples
#' example_questionnaires()
example_questionnaires <- function() {
  files <- c(
    "IPIP-50 Big Five \u00b7 Rating scale model (RSM)" = "ipip50_rsm.csv",
    "IPIP-50 Big Five \u00b7 Partial credit model (PCM)" = "ipip50_pcm.csv",
    "IPIP-50 Big Five \u00b7 Graded response model (GRM)" = "ipip50_grm.csv",
    "IPIP-50 Big Five \u00b7 Modified graded response model (MGRM)" = "ipip50_mgrm.csv",
    "SAT12 science test \u00b7 3PL" = "sat12_3pl.csv",
    "SAT12 science test \u00b7 Nominal response model (NRM)" = "sat12_nrm.csv"
  )
  stats::setNames(vapply(files, function(f) app_sys("extdata", "examples", f), ""), names(files))
}
##########################################################################################
#
##########################################################################################
#' The parameter matrix of the rows of a bank
#'
#' @param d Rows of an item bank: from \code{\link{read_questionnaire}} (\code{par1},
#'   \code{par2}, ...) or \code{\link{read_item_bank}} (rating scale model).
#'
#' @return A numeric matrix, without the columns that are empty in every row.
#' @noRd
bank_matrix <- function(d) {
  if (is.null(d$model)) return(as.matrix(d[, c("lambdaj", "delta1", "delta2", "delta3", "delta4")]))
  m <- as.matrix(d[, numbered_cols(d, "par"), drop = FALSE])
  m[, colSums(!is.na(m)) > 0, drop = FALSE]
}
##########################################################################################
#
##########################################################################################
#' Score an answer
#'
#' @param row One row of an item bank.
#' @param answer The option chosen, 1 to the number of options.
#'
#' @return The category of the model: 0 or 1 for a keyed dichotomous item, otherwise
#'   \code{answer - 1}, reversed on a reversed item.
#' @noRd
score_answer <- function(row, answer) {
  model <- if (is.null(row$model)) "rsm" else row$model
  n_cat <- if (is.null(row$n_cat)) 5L else row$n_cat
  key <- if (is.null(row$key)) NA_integer_ else row$key
  if (model == "dichotomous" && !is.na(key)) return(as.integer(answer == key))
  x <- answer - 1L
  if (isTRUE(row$reverse)) x <- n_cat - 1L - x
  as.integer(x)
}
