##########################################################################################
# PDF REPORT
##########################################################################################
# The report is a static typst template (inst/report/profile.typ) that reads the results
# from a csv and a few --input values, compiled with the typst command line. Fonts come
# from inst/report/fonts (Manrope, SIL Open Font License) with --ignore-system-fonts, so
# the pdf looks the same on every machine.
##########################################################################################
#' The typst compiler
#'
#' Finds the \code{typst} command line: the \code{GOLEMCAT_TYPST} environment variable,
#' then \code{typst} on the path, then the copy that comes with 'quarto'
#' (\code{quarto typst}).
#'
#' @return A list with \code{cmd}, the program, and \code{args}, the arguments that go
#'   before \code{compile}; \code{NULL} when none is found.
#' @keywords internal
#' @examples
#' golemcat:::typst_command()
typst_command <- function() {
  env <- Sys.getenv("GOLEMCAT_TYPST")
  if (nzchar(env) && file.exists(env)) return(list(cmd = env, args = character(0)))
  typst <- Sys.which("typst")
  if (nzchar(typst)) return(list(cmd = unname(typst), args = character(0)))
  quarto <- Sys.which("quarto")
  if (nzchar(quarto)) return(list(cmd = unname(quarto), args = "typst"))
  NULL
}
##########################################################################################
#
##########################################################################################
#' A sentence about where a score lies
#'
#' @param pct Percentile, 0 to 100.
#' @param low,high The descriptions of the two ends of the trait.
#'
#' @return A character vector.
#' @noRd
reading_text <- function(pct, low, high) {
  ifelse(pct < 30,
    sprintf("People who score like you usually describe themselves as %s.", low),
    ifelse(pct > 70,
      sprintf("People who score like you usually describe themselves as %s.", high),
      "Your score is in the broad middle, where most people are: neither end describes you strongly."
    )
  )
}
##########################################################################################
#
##########################################################################################
#' The data of the report
#'
#' One row per trait, with the numbers and the words the template prints.
#'
#' @param res The results, from \code{\link{cat_results}}.
#' @param bank The item bank, from \code{\link{read_item_bank}}.
#'
#' @return A data frame.
#' @noRd
report_data <- function(res, bank) {
  info <- trait_info()
  t <- info[match(res$scale, info$scale), ]
  clip <- function(x) pmin(pmax(x, 1), 99)
  pct <- clip(res$percentile)
  low <- ifelse(is.na(t$low), "lower", t$low)
  high <- ifelse(is.na(t$high), "higher", t$high)
  data.frame(
    scale = res$scale,
    about = ifelse(is.na(t$about), "", t$about),
    low = low,
    high = high,
    answered = res$answered,
    total = res$total,
    sd = sprintf("%.2f", bank$prior_sd[match(res$scale, bank$scale)]),
    z = sub("-", "\u2212", sprintf("%+.2f", res$theta), fixed = TRUE),
    pct = round(pct, 2),
    lo = round(clip(100 * stats::pnorm(res$theta - res$se)), 2),
    hi = round(clip(100 * stats::pnorm(res$theta + res$se)), 2),
    sentence = percentile_text(res$percentile),
    reading = reading_text(pct, low, high),
    stringsAsFactors = FALSE
  )
}
##########################################################################################
#
##########################################################################################
#' The PDF report of a test
#'
#' Writes the profile of a finished CAT session as a PDF: the five traits at a glance,
#' a page on each trait, and how the scores are calculated, with the numbers of the
#' session. It needs the 'typst' command line (see \code{\link{typst_command}}).
#'
#' @param res The results, from \code{\link{cat_results}}.
#' @param file Path of the PDF to write.
#' @param bank The item bank, from \code{\link{read_item_bank}}; it gives the spread
#'   (prior standard deviation) of each trait.
#' @param date The date printed on the report.
#'
#' @return \code{file}, invisibly.
#' @export
#'
#' @examples
#' \dontrun{
#' q <- ipip50()
#' s <- cat_start(q$bank, unique(q$bank$scale))
#' while (s$stage == "testing") s <- cat_answer(s, sample(1:5, 1))
#' report_pdf(cat_results(s), "profile.pdf", q$bank)
#' }
report_pdf <- function(res, file, bank = ipip50()$bank, date = Sys.Date()) {
  typst <- typst_command()
  if (is.null(typst)) {
    stop("The PDF report needs typst (https://typst.app) or quarto installed.", call. = FALSE)
  }
  dir <- tempfile("golemcat_report_")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  file.copy(app_sys("report", "profile.typ"), dir)
  file.copy(app_sys("report", "fonts"), dir, recursive = TRUE)
  utils::write.csv(report_data(res, bank), file.path(dir, "results.csv"), row.names = FALSE, fileEncoding = "UTF-8")
  out <- file.path(dir, "profile.pdf")
  date <- if (inherits(date, "Date")) format(date, "%d %B %Y") else as.character(date)
  args <- c(
    typst$args, "compile",
    "--root", dir,
    "--font-path", file.path(dir, "fonts"),
    "--ignore-system-fonts",
    "--input", "data=results.csv",
    "--input", paste0("date=", date),
    "--input", paste0("answered=", sum(res$answered)),
    "--input", paste0("total=", sum(res$total)),
    file.path(dir, "profile.typ"), out
  )
  log <- suppressWarnings(system2(typst$cmd, shQuote(args), stdout = TRUE, stderr = TRUE))
  if (!file.exists(out)) {
    stop("typst could not make the report:\n", paste(log, collapse = "\n"), call. = FALSE)
  }
  file.copy(out, file, overwrite = TRUE)
  invisible(file)
}
