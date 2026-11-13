##########################################################################################
#
##########################################################################################
#' Address of the cookie banner shared by the sites of sedzinfo.github.io
#'
#' @noRd
consent_script <- "https://sedzinfo.github.io/consent.js"
##########################################################################################
#
##########################################################################################
#' Address of the files shared by the Shiny apps, on sedzinfo.github.io
#'
#' The scripts and stylesheets that several apps use (the Google Analytics events, the
#' keep-alive pings) are kept once,
#' in the shiny folder of the sedzinfo.github.io repository, and each app loads
#' them from there: a fix reaches every app without deploying it again.
#'
#' @noRd
shared_url <- "https://sedzinfo.github.io/shiny/"
##########################################################################################
#
##########################################################################################
#' Google Analytics for the public deployment
#'
#' Loads the cookie banner shared with the sites of sedzinfo.github.io, which
#' loads Google Analytics only after the visitor accepts (and has the navy of
#' those sites), and the script shared by the apps that reports each tab the
#' visitor opens as a page view, and the PDF report as a download
#' (\code{https://sedzinfo.github.io/shiny/analytics.js}).
#'
#' @return A \code{tagList} for the head of the page.
#'
#' @keywords internal
#'
#' @examples
#' golemcat:::analytics_resources()
analytics_resources <- function() {
  tagList(
    tags$script(src = consent_script, defer = NA),
    tags$script(src = paste0(shared_url, "analytics.js"))
  )
}
##########################################################################################
#
##########################################################################################
#' Footer with the links of the cookie banner
#'
#' "Cookie settings" opens the banner again, so that visitors can change
#' their choice at any time, as the privacy note promises.
#'
#' @return A \code{div} for the bottom of the page.
#'
#' @keywords internal
#'
#' @examples
#' golemcat:::analytics_footer()
analytics_footer <- function() {
  div(
    class = "text-center small py-3",
    tags$a(href = "#cookie-settings", "Cookie settings"),
    HTML(" &middot; "),
    tags$a(href = "https://sedzinfo.github.io/privacy.html", "Privacy")
  )
}
