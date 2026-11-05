##########################################################################################
#
##########################################################################################
#' The application User-Interface
#'
#' A navbar page with three tabs, each a Shiny module: Take the test
#' (\code{mod_test_ui()}), CAT (\code{mod_lab_ui()}) and About
#' (\code{mod_about_ui()}), and a light/dark mode switch on the right.
#'
#' @param request Internal parameter for \code{shiny}. DO NOT REMOVE.
#' @param keep_alive \code{TRUE} to ping the server every 15 seconds while the page is
#'   open, so that proxies do not close idle connections; the hidden
#'   \code{keep_alive} output answers the pings.
#'
#' @return A \code{bslib} navbar page.
#' @import shiny
#' @noRd
#' @examples
#' \dontrun{
#' shiny::shinyApp(ui = app_ui, server = app_server)
#' }
app_ui <- function(request, keep_alive = TRUE) {
  scales <- unique(ipip50()$bank$scale)
  bslib::page_navbar(
    title = "golemcat",
    window_title = "golemcat: adaptive Big Five test",
    theme = bslib::bs_theme(version = 5),
    # the tabs scroll as normal pages rather than squeezing their cards to the window height
    fillable = FALSE,
    header = tagList(
      add_external_resources(keep_alive),
      if (keep_alive) div(style = "display:none", textOutput("keep_alive"))
    ),
    bslib::nav_panel("Take the test", mod_test_ui("test")),
    bslib::nav_panel("CAT", mod_lab_ui("lab", scales)),
    bslib::nav_panel("About", mod_about_ui("about")),
    bslib::nav_spacer(),
    bslib::nav_item(bslib::input_dark_mode(id = "dark_mode"))
  )
}
##########################################################################################
#
##########################################################################################
#' Add external resources to the application
#'
#' Serves \code{inst/app/www} at \code{www/} and adds to the head of the page the
#' favicon and, when asked, the script that pings the server (\code{keep_alive.js}).
#'
#' @param keep_alive \code{TRUE} to add \code{keep_alive.js}.
#'
#' @return A \code{head} tag.
#' @import shiny
#' @noRd
add_external_resources <- function(keep_alive = TRUE) {
  addResourcePath("www", app_sys("app/www"))
  tags$head(
    tags$link(rel = "icon", type = "image/svg+xml", href = "www/favicon.svg"),
    if (keep_alive) tags$script(src = "www/keep_alive.js")
  )
}
