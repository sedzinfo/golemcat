##########################################################################################
#
##########################################################################################
#' Run the app
#'
#' Starts the app, an adaptive (CAT) test of the Big Five personality traits with the
#' 50 statements of the IPIP Big-Five Factor Markers. It has two tabs:
#' \describe{
#'   \item{Take the test}{The questionnaire as a respondent sees it: one statement at a
#'     time, and at the end a profile of the five traits, each as a percentile of the
#'     calibration sample, and a PDF report of the profile.}
#'   \item{About}{How the test works, the acknowledgments and the references.}
#' }
#' The workings of an adaptive test, step by step and under six IRT models, are in the CAT
#' tab of golemirt (\url{https://sedzinfo-golemirt.share.connect.posit.cloud/}).
#'
#' @param se_threshold Standardized standard error at which a trait stops in the Take
#'   the test tab. The default 0.40 aims at a reliability of about .84 per trait and
#'   uses about 43 of the 50 statements; 0.45 uses about 36.
#' @param analytics \code{TRUE} to add Google Analytics, through the cookie banner shared with
#'   the sites of sedzinfo.github.io, which loads it only after the visitor accepts. Meant for the
#'   public deployment (see \code{app.R}); off by default, so that running the app yourself sends
#'   nothing.
#' @param keep_alive \code{TRUE} to ping the server every 15 seconds while the page is
#'   open, so that proxies do not close idle connections.
#' @inheritParams shiny::shinyApp
#' @param ... Arguments passed on to \code{golem_opts}; see \code{?golem::get_golem_options}.
#'
#' @return A \code{shiny.appobj}: printed, it starts the app.
#' @export
#' @importFrom shiny shinyApp
#' @importFrom golem with_golem_options
#'
#' @examples
#' \dontrun{
#' run_app()
#' run_app(se_threshold = 0.45, options = list(port = 8080))
#' }
run_app <- function(se_threshold = 0.40, analytics = FALSE, keep_alive = TRUE, onStart = NULL, options = list(),
                    enableBookmarking = NULL, uiPattern = "/", ...) {
  with_golem_options(
    # shiny calls the ui function with the request only, so the setting is passed in here
    app = shinyApp(
      ui = function(request) app_ui(request, analytics, keep_alive), server = app_server, onStart = onStart,
      options = options, enableBookmarking = enableBookmarking, uiPattern = uiPattern
    ),
    golem_opts = list(se_threshold = se_threshold, ...)
  )
}
