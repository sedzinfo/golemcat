##########################################################################################
#
##########################################################################################
#' The application User-Interface
#'
#' A navbar page with two tabs, each a Shiny module: Take the test
#' (\code{mod_test_ui()}) and About (\code{mod_about_ui()}), and a light/dark mode
#' switch on the right.
#'
#' @param request Internal parameter for \code{shiny}. DO NOT REMOVE.
#' @param analytics \code{TRUE} to add Google Analytics, with its cookie banner (see
#'   \code{analytics_resources()}) and a footer with the links of the banner (see
#'   \code{analytics_footer()}).
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
app_ui <- function(request, analytics = FALSE, keep_alive = TRUE) {
  bslib::page_navbar(
    title = "golemcat",
    window_title = "golemcat: adaptive Big Five test",
    theme = bslib::bs_theme(version = 5),
    # the tabs scroll as normal pages rather than squeezing their cards to the window height
    fillable = FALSE,
    header = tagList(
      add_external_resources(analytics, keep_alive),
      # phones: the collapsed menu of the navbar closes once a tab is chosen, so the tab is
      # not hidden under the open menu (CSS cannot close it; desktop has no collapsed menu)
      tags$script(HTML(
        "document.addEventListener('click', function (e) {
          var link = e.target.closest('.navbar-collapse.show .nav-link');
          if (link) bootstrap.Collapse.getOrCreateInstance(link.closest('.navbar-collapse')).hide();
        });"
      )),
      if (keep_alive) div(style = "display:none", textOutput("keep_alive"))
    ),
    bslib::nav_panel("Take the test", mod_test_ui("test")),
    bslib::nav_panel("About", mod_about_ui("about")),
    bslib::nav_spacer(),
    bslib::nav_item(bslib::input_dark_mode(id = "dark_mode")),
    footer = if (analytics) analytics_footer()
  )
}
##########################################################################################
#
##########################################################################################
#' Add external resources to the application
#'
#' Serves \code{inst/app/www} at \code{www/} and adds to the head of the page the
#' favicon, the stylesheet of the app and, when asked, the script that pings the server
#' (\code{keep_alive.js}, shared by the apps on sedzinfo.github.io) and the analytics
#' scripts. Each file is added by name, so a new file in \code{inst/app/www} must be added
#' here too.
#'
#' @param analytics \code{TRUE} to add the scripts of \code{analytics_resources()}.
#' @param keep_alive \code{TRUE} to add \code{keep_alive.js}.
#'
#' @return A \code{head} tag.
#' @import shiny
#' @noRd
add_external_resources <- function(analytics = FALSE, keep_alive = TRUE) {
  addResourcePath("www", app_sys("app/www"))
  tags$head(
    tags$link(rel = "icon", type = "image/svg+xml", href = "www/favicon.svg"),
    tags$link(rel = "stylesheet", href = "www/styles.css"),
    if (keep_alive) tags$script(src = paste0(shared_url, "keep_alive.js")),
    if (analytics) analytics_resources()
  )
}
