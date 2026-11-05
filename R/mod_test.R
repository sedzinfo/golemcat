##########################################################################################
#
##########################################################################################
#' Take the test tab - UI
#'
#' The questionnaire as the person taking it sees it: an introduction, one statement
#' at a time with a progress bar, and at the end a profile of the five traits.
#'
#' @param id Character. Module namespace id.
#'
#' @return A \code{tagList} of Shiny UI elements.
#' @keywords internal
#' @examples
#' \dontrun{
#' shiny::fluidPage(mod_test_ui("test"))
#' }
mod_test_ui <- function(id) {
  ns <- NS(id)
  div(
    class = "container py-4",
    style = "max-width: 760px;",
    uiOutput(ns("page"))
  )
}
##########################################################################################
#
##########################################################################################
#' Take the test tab - server
#'
#' Runs a CAT session (\code{\link{cat_start}}) over every trait of the questionnaire,
#' in order, and shows the results (\code{\link{cat_results}}) when it ends.
#'
#' @param id Character. Module namespace id, the same as in \code{\link{mod_test_ui}}.
#' @param questionnaire The questionnaire, as returned by \code{\link{ipip50}}.
#' @param se_threshold Standardized standard error at which a trait stops.
#'
#' @return None. Called for its side effect of registering the module server.
#' @keywords internal
#' @examples
#' \dontrun{
#' # inside app_server():
#' mod_test_server("test", ipip50(), se_threshold = 0.40)
#' }
mod_test_server <- function(id, questionnaire, se_threshold = 0.40) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    bank <- questionnaire$bank
    likert <- questionnaire$likert
    scales <- unique(bank$scale)
    rv <- reactiveValues(s = NULL, stage = "intro")

    observeEvent(input$start, {
      rv$s <- cat_start(bank, scales, se_threshold)
      rv$stage <- "testing"
    })

    observeEvent(input$restart, {
      rv$s <- NULL
      rv$stage <- "intro"
    })

    observeEvent(input$submit, {
      req(rv$stage == "testing")
      if (is.null(input$response) || !nzchar(input$response)) {
        showNotification("Please choose an answer first.", type = "warning", duration = 3)
        return()
      }
      rv$s <- cat_answer(rv$s, as.integer(input$response))
      if (rv$s$stage == "done") rv$stage <- "done"
    })

    output$page <- renderUI({
      switch(rv$stage,
        intro = test_intro(ns, nrow(bank), length(scales)),
        testing = test_question(ns, rv$s, likert),
        done = test_results(ns, cat_results(rv$s), nrow(bank))
      )
    })
  })
}
##########################################################################################
# PAGES
##########################################################################################
#' The introduction of the test
#'
#' @param ns The namespace function of the module.
#' @param n_items Number of items in the bank.
#' @param n_scales Number of traits.
#'
#' @return A UI tag.
#' @noRd
test_intro <- function(ns, n_items, n_scales) {
  div(
    class = "card shadow-sm",
    div(
      class = "card-body p-4",
      h2("Big Five personality test", class = "card-title"),
      p(
        "This questionnaire describes your personality on the five broad traits of the Big Five:",
        " openness, conscientiousness, extraversion, agreeableness and neuroticism."
      ),
      p(
        "You will see statements describing people's behaviours. Say how accurately each one",
        " describes you as you generally are now, not as you wish to be. There are no right or",
        " wrong answers."
      ),
      p(sprintf(
        paste0(
          "The test is adaptive: after each answer it picks the most informative next statement,",
          " and it moves on from a trait as soon as it can describe it reliably. So you will",
          " usually answer fewer than all %d statements; it takes about 5 to 10 minutes."
        ),
        n_items
      )),
      p(
        class = "text-body-secondary small",
        "Your answers stay in this browser session only: nothing is stored."
      ),
      actionButton(ns("start"), "Start the test", class = "btn-primary btn-lg mt-2")
    )
  )
}
##########################################################################################
#
##########################################################################################
#' One statement of the test
#'
#' @param ns The namespace function of the module.
#' @param s The CAT session.
#' @param likert The answer options.
#'
#' @return A UI tag.
#' @noRd
test_question <- function(ns, s, likert) {
  item <- cat_item(s)
  n_scales <- length(s$scales)
  # progress: the traits already done, plus the share of the current trait's items given
  current <- s$progress[s$idx, ]
  done <- (s$idx - 1 + current$answered / current$total) / n_scales
  tagList(
    div(
      class = "d-flex justify-content-between small text-body-secondary mb-1",
      span(sprintf("Part %d of %d", s$idx, n_scales)),
      span(sprintf("Statement %d", nrow(s$log) + 1))
    ),
    div(
      class = "progress mb-4", style = "height: 8px;",
      role = "progressbar", `aria-valuenow` = round(100 * done), `aria-valuemin` = 0, `aria-valuemax` = 100,
      div(class = "progress-bar", style = sprintf("width: %.0f%%;", 100 * done))
    ),
    div(
      class = "card shadow-sm",
      div(
        class = "card-body p-4",
        if (!is.na(item$stem) && nzchar(item$stem)) p(class = "text-body-secondary", item$stem),
        p(class = "fs-3 fw-semibold mb-4", item$question),
        radioButtons(ns("response"),
          label = NULL,
          choiceNames = as.list(likert$label),
          choiceValues = as.list(as.character(likert$value)),
          selected = character(0),
          width = "100%"
        ),
        actionButton(ns("submit"), "Next", class = "btn-primary mt-2")
      )
    )
  )
}
##########################################################################################
#
##########################################################################################
#' The results of the test
#'
#' @param ns The namespace function of the module.
#' @param res The results, from \code{\link{cat_results}}.
#' @param n_items Number of items in the bank.
#'
#' @return A UI tag.
#' @noRd
test_results <- function(ns, res, n_items) {
  info <- trait_info()
  rows <- lapply(seq_len(nrow(res)), function(i) {
    r <- res[i, ]
    t <- info[info$scale == r$scale, ]
    pct <- min(max(r$percentile, 1), 99)
    div(
      class = "mb-4",
      div(
        class = "d-flex justify-content-between align-items-baseline",
        h4(r$scale, class = "mb-1"),
        span(class = "fw-semibold", sprintf("%d%%", round(pct)))
      ),
      if (nrow(t)) p(class = "text-body-secondary small mb-2", t$about),
      # the percentile on a 0-100 track, with the middle (50) marked
      div(
        class = "position-relative rounded",
        style = "height: 12px; background: var(--bs-secondary-bg);",
        div(class = "position-absolute h-100 rounded bg-primary", style = sprintf("width: %.0f%%;", pct)),
        div(class = "position-absolute h-100", style = "left: 50%; width: 2px; background: var(--bs-body-color); opacity: .35;")
      ),
      if (nrow(t)) {
        div(
          class = "d-flex justify-content-between small text-body-secondary mt-1",
          span(t$low), span(class = "text-end", t$high)
        )
      },
      p(class = "small mt-1 mb-0", sprintf("Your score is %s.", percentile_text(r$percentile)))
    )
  })
  div(
    class = "card shadow-sm",
    div(
      class = "card-body p-4",
      h2("Your profile", class = "card-title"),
      p(sprintf(
        "You answered %d of the %d statements. Each bar shows where your score falls among the people the test was calibrated on; the line marks the middle.",
        sum(res$answered), n_items
      )),
      tags$hr(),
      rows,
      tags$hr(),
      p(
        class = "small text-body-secondary",
        "The comparison group is about 20,000 people who took the same questionnaire online,",
        " so it is not a representative sample of any country. Personality traits are neither",
        " good nor bad, and this is not a clinical or diagnostic test."
      ),
      actionButton(ns("restart"), "Take the test again", class = "btn-outline-primary")
    )
  )
}
