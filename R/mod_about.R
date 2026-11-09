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
    "Bock, R. D. (1972). Estimating item parameters and latent ability when responses are scored in two or more nominal categories. Psychometrika, 37(1), 29-51.",
    "Chalmers, R. P. (2012). mirt: A multidimensional item response theory package for the R environment. Journal of Statistical Software, 48(6), 1-29.",
    "Goldberg, L. R. (1992). The development of markers for the Big-Five factor structure. Psychological Assessment, 4(1), 26-42.",
    "Masters, G. N. (1982). A Rasch model for partial credit scoring. Psychometrika, 47(2), 149-174.",
    "Muraki, E. (1990). Fitting a polytomous item response model to Likert-type data. Applied Psychological Measurement, 14(1), 59-71.",
    "Samejima, F. (1969). Estimation of latent ability using a response pattern of graded scores. Psychometrika Monograph Supplement, 17.",
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
    p(
      "The ", strong("CAT"), " tab is not limited to the Big Five: it runs any questionnaire",
      " given as a csv file, under six item response models: the 4PL family for right/wrong",
      " items, and the rating scale, partial credit, graded response, modified graded response",
      " and nominal response models for items with several options. It comes with an example",
      " of each, which can be downloaded to see the format."
    ),
    h3("How it works", class = "mt-4"),
    p(
      "The test tab scores each trait with the rating scale model (Andrich, 1978); the CAT tab",
      " also offers the partial credit (Masters, 1982), graded response (Samejima, 1969), modified",
      " graded response (Muraki, 1990), nominal response (Bock, 1972) and 1PL to 4PL models. After every answer the",
      " score is estimated by expected a posteriori (EAP) estimation, the next statement is the one",
      " with the most Fisher information at that estimate, and a trait stops when its standard",
      " error falls below the chosen threshold or its statements run out. The engine gives the",
      " same results as the catR package for every model, and the scores the same as mirt's EAP scores."
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
      "The right/wrong and nominal examples use the SAT12 science test that comes with mirt:",
      " the answers of 600 students to 32 multiple-choice questions, whose texts are not public."
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
