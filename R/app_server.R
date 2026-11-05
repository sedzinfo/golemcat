##########################################################################################
#
##########################################################################################
#' The application server-side logic
#'
#' Starts the module server of each tab with the IPIP-50 questionnaire
#' (\code{\link{ipip50}}), and answers the pings of \code{keep_alive.js}.
#'
#' @param input,output,session Internal parameters for \code{shiny}. DO NOT REMOVE.
#'
#' @import shiny
#' @noRd
#' @examples
#' \dontrun{
#' shiny::shinyApp(ui = app_ui, server = app_server)
#' }
app_server <- function(input, output, session) {
  questionnaire <- ipip50()
  se_threshold <- golem::get_golem_options("se_threshold")
  if (is.null(se_threshold)) se_threshold <- 0.40
  mod_test_server("test", questionnaire, se_threshold = se_threshold)
  mod_lab_server("lab", questionnaire)

  # answers the pings of keep_alive.js, so that proxies do not close an idle connection
  output$keep_alive <- renderText({
    req(input$count)
    paste("keep alive", input$count)
  })
}
