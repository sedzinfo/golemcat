##########################################################################################
#
##########################################################################################
#' About tab - UI
#'
#' A static page: what the app does, how the questionnaire was calibrated, the
#' acknowledgments and references, and the license of the package. It has no inputs,
#' so it has no module server.
#'
#' @param id Character. Module namespace id.
#'
#' @return A \code{tagList} of Shiny UI elements.
#' @keywords internal
#' @examples
#' \dontrun{
#' shiny::fluidPage(mod_about_ui("about"))
#' }
mod_about_ui <- function(id) {
  ns <- NS(id)
  # .noWS: no space between a link and the punctuation after it
  link <- function(href, text) tags$a(href = href, target = "_blank", rel = "noopener", text, .noWS = "outside")
  references <- c(
    "Andrich, D. (1978). A rating formulation for ordered response categories. Psychometrika, 43(4), 561-573.",
    "Chalmers, R. P. (2012). mirt: A multidimensional item response theory package for the R environment. Journal of Statistical Software, 48(6), 1-29.",
    "Goldberg, L. R. (1992). The development of markers for the Big-Five factor structure. Psychological Assessment, 4(1), 26-42.",
    "Magis, D., & Barrada, J. R. (2017). Computerized adaptive testing with R: Recent updates of the package catR. Journal of Statistical Software, 76(1), 1-19.",
    "van der Linden, W. J., & Glas, C. A. W. (Eds.) (2010). Elements of Adaptive Testing. Springer."
  )
  div(
    id = ns("page"),
    class = "container py-4",
    style = "max-width: 860px;",
    h2("About"),
    p(
      strong("golemcat"), " is a computerized adaptive test (CAT) of the Big Five personality",
      " traits. Instead of giving everyone the same 50 statements, it picks after each answer the",
      " statement that tells the most about the person, and moves on from a trait as soon as its",
      " score is precise enough. The ", strong("Take the test"), " tab is the questionnaire as a",
      " respondent sees it; the ", strong("CAT"), " tab shows what happens behind it:",
      " the estimate and its standard error after every answer, and how many questions each trait",
      " needed."
    ),
    h3("How it works", class = "mt-4"),
    p(
      "Each trait is scored with the rating scale model (Andrich, 1978). After every answer the",
      " score is estimated by expected a posteriori (EAP) estimation, the next statement is the one",
      " with the most Fisher information at that estimate, and a trait stops when its standard",
      " error falls below the chosen threshold or its statements run out. The engine gives the",
      " same results as the catR package, and the scores the same as mirt's EAP scores."
    ),
    h3("Acknowledgments", class = "mt-4"),
    p(
      "The 50 statements are the Big-Five Factor Markers of the ",
      link("https://ipip.ori.org/", "International Personality Item Pool"),
      " (IPIP; Goldberg, 1992), which are in the public domain. Thanks to Lewis R. Goldberg and",
      " the IPIP for making them free for everyone to use."
    ),
    p(
      "The statements were calibrated on the answers of about 20,000 people to the Big Five test",
      " of the ", link("https://openpsychometrics.org/", "Open-Source Psychometrics Project"),
      ", which publishes its anonymous data for research and teaching. The comparison group of",
      " the results is that sample: people who took the test online, not a representative sample",
      " of any population."
    ),
    p(
      "The models were fitted with ", link("https://cran.r-project.org/package=mirt", "mirt"),
      " (Chalmers, 2012), and the adaptive engine follows ",
      link("https://cran.r-project.org/package=catR", "catR"), " (Magis & Barrada, 2017). The app",
      " is built with ", link("https://shiny.posit.co/", "Shiny"), ", ",
      link("https://thinkr-open.github.io/golem/", "golem"), " and ",
      link("https://rstudio.github.io/bslib/", "bslib"), ". Thanks to their authors and to the R community."
    ),
    h3("References", class = "mt-4"),
    tags$ul(lapply(references, tags$li)),
    h3("License", class = "mt-4"),
    p(
      "golemcat is free software under the ",
      link("https://www.gnu.org/licenses/gpl-3.0.html", "GNU General Public License v3"), ".",
      " It is a teaching and research tool, not a clinical or diagnostic instrument."
    ),
    p("Author and maintainer: Dimitrios Zacharatos.", class = "text-body-secondary")
  )
}
