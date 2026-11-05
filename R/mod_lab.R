##########################################################################################
#
##########################################################################################
#' How CAT works tab - UI
#'
#' The adaptive test with its workings in view: choose the traits and the standard
#' error at which each one stops, then answer, and follow after every answer the
#' estimate and standard error of each trait, how many items it used, every answer
#' given, and a plot of the estimate and standard error step by step.
#'
#' @param id Character. Module namespace id.
#' @param scales The traits to offer.
#'
#' @return A \code{tagList} of Shiny UI elements.
#' @keywords internal
#' @examples
#' \dontrun{
#' shiny::fluidPage(mod_lab_ui("lab", unique(ipip50()$bank$scale)))
#' }
mod_lab_ui <- function(id, scales) {
  ns <- NS(id)
  sidebarLayout(
    sidebarPanel(
      width = 3,
      checkboxGroupInput(ns("scales_include"), "Traits (scales):", choices = scales, selected = scales),
      sliderInput(ns("se_threshold"), "Stopping rule (standard error):",
        min = 0.10, max = 0.70, value = 0.45, step = 0.01
      ),
      helpText(
        "\u03b8 and SE are shown on a standardized scale per trait (divided by the sd of the \u03b8",
        " distribution estimated by mirt), so the same threshold is the same target in every trait.",
        " The reliability target of a threshold is 1 - SE\u00b2, e.g. SE 0.35 is about .88."
      ),
      actionButton(ns("start"), "Start / restart the full test", class = "btn-primary")
    ),
    mainPanel(
      width = 9,
      textOutput(ns("status_text")),
      tags$br(),
      uiOutput(ns("question_ui")),
      uiOutput(ns("submit_ui")),
      tags$hr(),
      uiOutput(ns("summary_ui")),
      plotOutput(ns("traj_plot"), height = 300),
      # one table under the other: side by side they are too wide for the main panel
      h4("Progress by trait", class = "mt-3"),
      div(style = "overflow-x:auto;", tableOutput(ns("progress_table"))),
      textOutput(ns("overall_text")),
      h4("Response history", class = "mt-4"),
      div(style = "max-height:450px;overflow:auto;", tableOutput(ns("log_table")))
    )
  )
}
##########################################################################################
#
##########################################################################################
#' How CAT works tab - server
#'
#' @param id Character. Module namespace id, the same as in \code{\link{mod_lab_ui}}.
#' @param questionnaire The questionnaire, as returned by \code{\link{ipip50}}.
#'
#' @return None. Called for its side effect of registering the module server.
#' @keywords internal
#' @examples
#' \dontrun{
#' # inside app_server():
#' mod_lab_server("lab", ipip50())
#' }
mod_lab_server <- function(id, questionnaire) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    bank <- questionnaire$bank
    likert <- questionnaire$likert
    rv <- reactiveValues(s = NULL)

    observeEvent(input$start, {
      req(length(input$scales_include) >= 1)
      # the traits in the order of the bank, whatever the order they were ticked in
      scales <- intersect(unique(bank$scale), input$scales_include)
      rv$s <- cat_start(bank, scales, input$se_threshold)
    })

    observeEvent(input$submit, {
      req(rv$s, rv$s$stage == "testing", input$response)
      rv$s <- cat_answer(rv$s, as.integer(input$response))
    })

    output$status_text <- renderText({
      s <- rv$s
      if (is.null(s)) {
        "Select the traits and an SE threshold, then press Start to begin."
      } else if (s$stage == "testing") {
        sprintf(
          "Trait %d/%d: %s - question %d (%d of %d possible items used) - \u03b8 = %.2f, SE = %s",
          s$idx, length(s$scales), s$scales[s$idx],
          length(s$administered) + 1, length(s$administered), nrow(s$scale_matrix),
          (s$theta - s$prior[1]) / s$prior[2],
          ifelse(is.na(s$se), "-", sprintf("%.3f", s$se / s$prior[2]))
        )
      } else {
        "The CAT is complete."
      }
    })

    output$question_ui <- renderUI({
      req(rv$s, rv$s$stage == "testing")
      item <- cat_item(rv$s)
      tagList(
        if (!is.na(item$stem) && nzchar(item$stem)) tags$p(tags$b(item$stem)),
        tags$p(style = "font-size:1.2em;", item$question),
        radioButtons(ns("response"),
          label = NULL,
          choiceNames = as.list(likert$label),
          choiceValues = as.list(as.character(likert$value)),
          selected = character(0)
        )
      )
    })

    output$submit_ui <- renderUI({
      req(rv$s, rv$s$stage == "testing")
      actionButton(ns("submit"), "Submit answer \u2192")
    })

    output$summary_ui <- renderUI({
      req(rv$s, rv$s$stage == "done")
      p <- rv$s$progress
      tagList(
        tags$p(sprintf(
          "Completed %d traits with %d of %d total questions (%d%% fewer).",
          nrow(p), sum(p$answered), sum(p$total), round(100 * (1 - sum(p$answered) / sum(p$total)))
        )),
        tags$p("See the progress table below for \u03b8/SE by trait, and the response history for every individual answer.")
      )
    })

    output$progress_table <- renderTable({
      req(rv$s)
      df <- rv$s$progress
      out <- data.frame(
        dimension = df$scale,
        answered_total = sprintf("%d/%d", df$answered, df$total),
        theta = ifelse(is.na(df$theta), "-", sprintf("%.2f", df$theta)),
        se = ifelse(is.na(df$se), "-", sprintf("%.3f", df$se)),
        status = df$status,
        stringsAsFactors = FALSE
      )
      colnames(out) <- c("Trait", "Answered", "\u03b8", "SE", "Status")
      out
    })

    output$overall_text <- renderText({
      req(rv$s)
      p <- rv$s$progress
      sprintf(
        "Total: %d of %d possible questions across the selected traits (%d%% fewer questions so far).",
        sum(p$answered), sum(p$total), round(100 * (1 - sum(p$answered) / sum(p$total)))
      )
    })

    output$traj_plot <- renderPlot({
      req(rv$s, nrow(rv$s$log) > 0)
      plot_trajectory(rv$s)
    })

    output$log_table <- renderTable({
      req(rv$s, nrow(rv$s$log) > 0)
      tbl <- rv$s$log[order(-rv$s$log$step), ]
      tbl$theta <- round(tbl$theta, 2)
      tbl$se <- round(tbl$se, 3)
      colnames(tbl) <- c("Step", "Trait", "Question", "Answer", "\u03b8", "SE")
      tbl
    })
  })
}
##########################################################################################
# PLOT
##########################################################################################
#' Plot the course of a CAT session
#'
#' Two panels: the standardized ability estimate and its standard error after each
#' answer, across the whole test. A red vertical line marks the last answer of each
#' finished scale, and a dashed red line the standard error at which a scale stops.
#'
#' @param s A CAT session with at least one answer (see \code{\link{cat_start}}).
#'
#' @return \code{NULL}, invisibly; called for the plot.
#' @family CAT session
#' @export
#'
#' @examples
#' s <- cat_start(ipip50()$bank, scales = c("Openness", "Extraversion"), se_threshold = 0.5)
#' while (s$stage == "testing") s <- cat_answer(s, sample(1:5, 1))
#' plot_trajectory(s)
plot_trajectory <- function(s) {
  log <- s$log
  if (!nrow(log)) stop("no answers yet", call. = FALSE)
  done <- s$progress$scale[s$progress$status == "completed"]
  ends <- tapply(log$step, log$scale, max)[done] + 0.01
  old <- graphics::par(mfrow = c(1, 2))
  on.exit(graphics::par(old))
  graphics::plot(log$step, log$theta,
    type = "b", pch = 19, xlab = "Step (across the whole test)", ylab = expression(theta),
    main = expression(theta ~ "estimate after each answer")
  )
  graphics::abline(v = ends, col = "red")
  graphics::plot(log$step, log$se,
    type = "b", pch = 19, xlab = "Step (across the whole test)", ylab = "SE",
    main = expression("SE after each answer"), ylim = c(0, max(log$se, s$se_threshold, na.rm = TRUE) * 1.1)
  )
  graphics::abline(h = s$se_threshold, col = "red", lty = 2)
  graphics::abline(v = ends, col = "red")
  invisible(NULL)
}
