##########################################################################################
#
##########################################################################################
#' Run the app
#'
#' Starts the app, an adaptive (CAT) test of the Big Five personality traits with the
#' 50 statements of the IPIP Big-Five Factor Markers. It has three tabs:
#' \describe{
#'   \item{Take the test}{The questionnaire as a respondent sees it: one statement at a
#'     time, and at the end a profile of the five traits, each as a percentile of the
#'     calibration sample.}
#'   \item{CAT}{An adaptive test with its workings in view, for any questionnaire
#'     and six IRT models: choose one of the examples (one per model, see
#'     \code{\link{example_questionnaires}}) or upload a csv of your own (see
#'     \code{\link{read_questionnaire}}), the scales and the standard error at which
#'     each stops, and follow after every answer the estimate and standard error of
#'     each scale, the items used, every answer, and a plot of the estimate and
#'     standard error step by step.}
#'   \item{About}{How the test works, the acknowledgments and the references.}
#' }
#'
#' @param se_threshold Standardized standard error at which a trait stops in the Take
#'   the test tab. The default 0.40 aims at a reliability of about .84 per trait and
#'   uses about 43 of the 50 statements; 0.45 uses about 36.
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
run_app <- function(se_threshold = 0.40, keep_alive = TRUE, onStart = NULL, options = list(),
                    enableBookmarking = NULL, uiPattern = "/", ...) {
  with_golem_options(
    # shiny calls the ui function with the request only, so the setting is passed in here
    app = shinyApp(
      ui = function(request) app_ui(request, keep_alive), server = app_server, onStart = onStart,
      options = options, enableBookmarking = enableBookmarking, uiPattern = uiPattern
    ),
    golem_opts = list(se_threshold = se_threshold, ...)
  )
}
