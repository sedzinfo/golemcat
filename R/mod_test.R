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

    observeEvent(input$explain, {
      req(rv$stage == "done")
      showModal(test_explain(cat_results(rv$s), bank))
    })

    output$pdf <- downloadHandler(
      filename = function() sprintf("big-five-profile-%s.pdf", format(Sys.Date())),
      content = function(file) {
        tryCatch(
          report_pdf(cat_results(rv$s), file, bank),
          error = function(e) {
            showNotification(conditionMessage(e), type = "error", duration = 8)
            stop(e)
          }
        )
      },
      contentType = "application/pdf"
    )

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
      div(
        class = "d-flex flex-wrap gap-2",
        actionButton(ns("restart"), "Take the test again", class = "btn-outline-primary"),
        actionButton(ns("explain"), "How is my score calculated?", class = "btn-outline-secondary"),
        downloadButton(ns("pdf"), "Download PDF report", class = "btn-primary")
      )
    )
  )
}
##########################################################################################
#
##########################################################################################
#' How the scores are calculated
#'
#' A dialog that explains, in plain words, how the answers become the percentages of
#' the profile, with the numbers of this session.
#'
#' @param res The results, from \code{\link{cat_results}}.
#' @param bank The item bank, from \code{\link{read_item_bank}}.
#'
#' @return A modal dialog.
#' @noRd
test_explain <- function(res, bank) {
  sds <- bank$prior_sd[match(res$scale, bank$scale)]
  # likely range: the percentile one standard error either side of the score
  lo <- 100 * stats::pnorm(res$theta - res$se)
  hi <- 100 * stats::pnorm(res$theta + res$se)
  pc <- function(x) sprintf("%d%%", round(pmin(pmax(x, 1), 99)))
  rows <- lapply(seq_len(nrow(res)), function(i) {
    tags$tr(
      tags$td(res$scale[i]),
      tags$td(class = "text-end", sprintf("%d of %d", res$answered[i], res$total[i])),
      tags$td(class = "text-end", sprintf("%.2f", sds[i])),
      tags$td(class = "text-end", sprintf("%+.2f", res$theta[i])),
      tags$td(class = "text-end fw-semibold", pc(res$percentile[i])),
      tags$td(class = "text-end", sprintf("%s to %s", pc(lo[i]), pc(hi[i])))
    )
  })
  modalDialog(
    title = "How your scores are calculated",
    size = "l",
    easyClose = TRUE,
    footer = modalButton("Close"),
    h5("1. From your answers to a trait level"),
    p(
      "Every statement was calibrated on about 20,000 people with a statistical model",
      " (the rating scale model). For each statement the model tells how likely people at",
      " each level of a trait are to choose each answer. The test starts by assuming you are",
      " at the average level. After every answer it works out which levels best fit all",
      " your answers so far, and takes the average of those levels as your score.",
      " It then shows you the statement that can tell it the most about you, and it stops",
      " a trait as soon as the score is precise enough."
    ),
    h5("2. From a trait level to a standard score"),
    p(
      "In the comparison group the average level of each trait is set to 0. Your level",
      " is divided by how widely the comparison group is spread on that trait (its standard",
      " deviation). The result is a standard score: 0 is exactly average, +1 is one standard",
      " deviation above average, and -1 is one below."
    ),
    h5("3. From a standard score to a percentage"),
    p(
      "Traits like these are assumed to follow a bell curve (the normal distribution).",
      " The percentage on each bar is the share of the bell curve below your standard score:",
      " a score of 0 gives 50%, +1 gives about 84% and -1 about 16%."
    ),
    h5("Your numbers"),
    div(
      class = "table-responsive",
      tags$table(
        class = "table table-sm align-middle",
        tags$thead(tags$tr(
          tags$th("Trait"),
          tags$th(class = "text-end", "Statements"),
          tags$th(class = "text-end", "Spread (SD)"),
          tags$th(class = "text-end", "Standard score"),
          tags$th(class = "text-end", "Percentage"),
          tags$th(class = "text-end", "Likely range")
        )),
        tags$tbody(rows)
      )
    ),
    h5("Good to know"),
    tags$ul(
      tags$li(
        "Every score has some uncertainty. The likely range is the percentage one standard",
        " error either side of your score: it is about two times out of three that your",
        " true percentage lies in it."
      ),
      tags$li(
        "With only a few answers, scores are drawn a little towards the middle, because the",
        " test starts from the average and needs evidence to move away from it."
      ),
      tags$li(
        "The percentages come from the bell curve, not from counting people one by one, and",
        " the comparison group took the questionnaire online, so it does not represent any",
        " particular country."
      )
    )
  )
}
