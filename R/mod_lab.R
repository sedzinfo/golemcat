##########################################################################################
#
##########################################################################################
#' CAT tab - UI
#'
#' The adaptive test with its workings in view. A sidebar holds the settings: the
#' questionnaire (one of the examples, one for each IRT model, or a csv of your own,
#' see \code{\link{read_questionnaire}}), the scales and the standard error at which
#' each one stops. The main area has, side by side, the current item and a chart of the
#' estimate and standard error after every answer, then the progress of each scale and
#' the history of every answer given.
#'
#' @param id Character. Module namespace id.
#'
#' @return A \code{bslib} sidebar layout.
#' @keywords internal
#' @examples
#' \dontrun{
#' bslib::page_fluid(mod_lab_ui("lab"))
#' }
mod_lab_ui <- function(id) {
  ns <- NS(id)
  examples <- example_questionnaires()
  bslib::layout_sidebar(
    fillable = FALSE,
    sidebar = bslib::sidebar(
      title = "Settings",
      width = 320,
      selectInput(ns("source"), "Questionnaire",
        choices = c(names(examples), "Your own csv file\u2026" = "upload"),
        selected = names(examples)[1], width = "100%"
      ),
      conditionalPanel(
        sprintf("input['%s'] == 'upload'", ns("source")),
        fileInput(ns("upload"), NULL, accept = c(".csv", "text/csv"), placeholder = "No file chosen", width = "100%")
      ),
      uiOutput(ns("source_info")),
      checkboxGroupInput(ns("scales_include"), "Scales", choices = character(0)),
      sliderInput(ns("se_threshold"), "Stop a scale at standard error",
        min = 0.10, max = 0.70, value = 0.45, step = 0.01, width = "100%"
      ),
      uiOutput(ns("threshold_note")),
      actionButton(ns("start"), "Start / restart the test", class = "btn-primary w-100"),
      p(
        class = "small text-body-secondary mt-2 mb-0",
        "\u03b8 and SE are standardized per scale (divided by the sd of the \u03b8 distribution",
        " of the calibration), so a threshold is the same target in every scale."
      )
    ),
    # two rows, each side by side from 1200px wide and stacked below that, where the
    # tables would be too narrow: the item and the chart, then the progress and
    # the history
    bslib::layout_columns(
      col_widths = bslib::breakpoints(sm = 12, xl = c(5, 7)),
      bslib::card(
        bslib::card_header(uiOutput(ns("status"), inline = TRUE)),
        bslib::card_body(
          uiOutput(ns("question_ui")),
          uiOutput(ns("submit_ui")),
          uiOutput(ns("summary_ui"))
        )
      ),
      bslib::card(
        full_screen = TRUE,
        bslib::card_header("\u03b8 and SE after each answer"),
        bslib::card_body(plotly::plotlyOutput(ns("traj_plot"), height = "400px"))
      )
    ),
    bslib::layout_columns(
      col_widths = bslib::breakpoints(sm = 12, xl = c(5, 7)),
      bslib::card(
        bslib::card_header("Progress by scale"),
        bslib::card_body(
          div(style = "overflow-x: auto;", tableOutput(ns("progress_table"))),
          uiOutput(ns("overall_ui"))
        )
      ),
      bslib::card(
        bslib::card_header("Response history"),
        bslib::card_body(
          style = "max-height: 420px; overflow: auto;",
          tableOutput(ns("log_table"))
        )
      )
    )
  )
}
##########################################################################################
#
##########################################################################################
#' CAT tab - server
#'
#' @param id Character. Module namespace id, the same as in \code{\link{mod_lab_ui}}.
#' @param dark_mode A reactive returning \code{"dark"} or \code{"light"}, the mode of
#'   the page, which the chart follows.
#'
#' @return None. Called for its side effect of registering the module server.
#' @keywords internal
#' @examples
#' \dontrun{
#' # inside app_server():
#' mod_lab_server("lab", dark_mode = reactive(input$dark_mode))
#' }
mod_lab_server <- function(id, dark_mode = reactive("light")) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    examples <- example_questionnaires()
    models <- irt_models()
    rv <- reactiveValues(s = NULL)

    # the questionnaire chosen: an example or an uploaded csv
    loaded <- reactive({
      req(input$source)
      if (identical(input$source, "upload")) {
        if (is.null(input$upload)) return(list(bank = NULL, error = NULL, path = NULL, name = NULL))
        path <- input$upload$datapath
        name <- input$upload$name
      } else {
        path <- examples[[input$source]]
        name <- basename(path)
      }
      tryCatch(
        list(bank = read_questionnaire(path), error = NULL, path = path, name = name),
        error = function(e) list(bank = NULL, error = sub("^[^:]*: ", "", conditionMessage(e)), path = NULL, name = name)
      )
    })

    observeEvent(loaded(), {
      bank <- loaded()$bank
      scales <- if (is.null(bank)) character(0) else unique(bank$scale)
      updateCheckboxGroupInput(session, "scales_include", choices = scales, selected = scales)
      rv$s <- NULL
    })

    output$source_info <- renderUI({
      l <- loaded()
      if (!is.null(l$error)) {
        return(div(class = "alert alert-danger small py-2", strong(l$name), br(), l$error))
      }
      if (is.null(l$bank)) {
        return(p(
          class = "small text-body-secondary",
          "A csv with one row per item: the text, the answer options and the coefficients",
          " of a model fitted with mirt. Download an example to see the columns."
        ))
      }
      bank <- l$bank
      used <- unique(bank$model)
      tagList(
        p(
          class = "small mb-1",
          strong(paste(models$label[match(used, models$model)], collapse = " + ")), br(),
          span(class = "text-body-secondary", sprintf(
            "%d %s, %d items", length(unique(bank$scale)),
            if (length(unique(bank$scale)) == 1) "scale" else "scales", nrow(bank)
          ))
        ),
        p(class = "small", downloadLink(ns("download_csv"), "\u2193 Download this questionnaire as csv"))
      )
    })

    output$download_csv <- downloadHandler(
      filename = function() {
        n <- loaded()$name
        if (is.null(n)) "questionnaire.csv" else n
      },
      content = function(file) file.copy(loaded()$path, file, overwrite = TRUE),
      contentType = "text/csv"
    )

    observeEvent(input$start, {
      bank <- loaded()$bank
      req(bank, length(input$scales_include) >= 1)
      # the scales in the order of the bank, whatever the order they were ticked in
      scales <- intersect(unique(bank$scale), input$scales_include)
      req(length(scales) >= 1)
      rv$s <- cat_start(bank, scales, input$se_threshold)
    })

    observeEvent(input$submit, {
      req(rv$s, rv$s$stage == "testing", input$response)
      rv$s <- cat_answer(rv$s, as.integer(input$response))
    })

    output$threshold_note <- renderUI({
      req(input$se_threshold)
      p(
        class = "small text-body-secondary",
        sprintf("Reliability target about %.2f (1 - SE\u00b2).", 1 - input$se_threshold^2)
      )
    })

    output$status <- renderUI({
      s <- rv$s
      if (is.null(s)) {
        "Not started"
      } else if (s$stage == "testing") {
        tagList(
          strong(sprintf("Scale %d of %d: %s", s$idx, length(s$scales), s$scales[s$idx])),
          span(
            class = "text-body-secondary ms-2",
            sprintf(
              "%s \u00b7 item %d of %d \u00b7 \u03b8 = %.2f \u00b7 SE = %s",
              toupper(s$model), length(s$administered) + 1, nrow(s$scale_matrix),
              (s$theta - s$prior[1]) / s$prior[2],
              ifelse(is.na(s$se), "-", sprintf("%.3f", s$se / s$prior[2]))
            )
          )
        )
      } else {
        strong("The CAT is complete")
      }
    })

    output$question_ui <- renderUI({
      if (is.null(rv$s)) {
        return(p(
          class = "text-body-secondary",
          "Choose a questionnaire, the scales and the standard error in the settings, then press Start."
        ))
      }
      req(rv$s$stage == "testing")
      item <- cat_item(rv$s)
      options <- item$options
      if (is.null(options)) options <- as.character(seq_len(5))
      tagList(
        if (!is.na(item$stem) && nzchar(item$stem)) p(class = "text-body-secondary mb-1", item$stem),
        p(class = "fs-4 fw-semibold", item$question),
        radioButtons(ns("response"),
          label = NULL,
          choiceNames = as.list(options),
          choiceValues = as.list(as.character(seq_along(options))),
          selected = character(0)
        ),
        if (!is.na(item$key)) {
          p(
            class = "small text-body-secondary",
            "Correct answer: ", strong(options[item$key]),
            if (item$model == "nrm") " (the nominal model scores every option on its own, not right or wrong)"
          )
        }
      )
    })

    output$submit_ui <- renderUI({
      req(rv$s, rv$s$stage == "testing")
      actionButton(ns("submit"), "Submit answer \u2192", class = "btn-primary align-self-start")
    })

    output$summary_ui <- renderUI({
      req(rv$s, rv$s$stage == "done")
      p <- rv$s$progress
      tagList(
        p(sprintf(
          "Completed %d %s with %d of %d items (%d%% fewer).",
          nrow(p), if (nrow(p) == 1) "scale" else "scales", sum(p$answered), sum(p$total),
          round(100 * (1 - sum(p$answered) / sum(p$total)))
        )),
        p(class = "text-body-secondary", "The progress table has the final \u03b8 and SE of each scale.")
      )
    })

    output$progress_table <- renderTable(
      {
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
        colnames(out) <- c("Scale", "Answered", "\u03b8", "SE", "Status")
        out
      },
      width = "100%", spacing = "s", hover = TRUE
    )

    output$overall_ui <- renderUI({
      req(rv$s)
      p <- rv$s$progress
      p(
        class = "small text-body-secondary mb-0",
        sprintf(
          "%d of %d items so far (%d%% fewer than giving them all).",
          sum(p$answered), sum(p$total), round(100 * (1 - sum(p$answered) / sum(p$total)))
        )
      )
    })

    output$traj_plot <- plotly::renderPlotly({
      req(rv$s, nrow(rv$s$log) > 0)
      plot_trajectory(rv$s, dark = identical(dark_mode(), "dark"))
    })

    output$log_table <- renderTable(
      {
        req(rv$s, nrow(rv$s$log) > 0)
        tbl <- rv$s$log[order(-rv$s$log$step), ]
        tbl$theta <- sprintf("%.2f", tbl$theta)
        tbl$se <- sprintf("%.3f", tbl$se)
        colnames(tbl) <- c("Step", "Scale", "Item", "Answer", "Score", "\u03b8", "SE")
        tbl
      },
      width = "100%", spacing = "s", hover = TRUE
    )
  })
}
##########################################################################################
# PLOT
##########################################################################################
#' Plot the course of a CAT session
#'
#' An interactive \code{plotly} chart in two panels side by side: the
#' standardized ability estimate and its standard error after each answer, across the
#' whole test, one colour per scale. Hovering a point shows the statement and the
#' answer; a dashed line marks the standard error at which a scale stops.
#'
#' @param s A CAT session with at least one answer (see \code{\link{cat_start}}).
#' @param dark \code{TRUE} for light text and grid on a dark page.
#'
#' @return A \code{plotly} htmlwidget.
#' @family CAT session
#' @export
#'
#' @examples
#' s <- cat_start(ipip50()$bank, scales = c("Openness", "Extraversion"), se_threshold = 0.5)
#' while (s$stage == "testing") s <- cat_answer(s, sample(1:5, 1))
#' plot_trajectory(s)
plot_trajectory <- function(s, dark = FALSE) {
  log <- s$log
  if (!nrow(log)) stop("no answers yet", call. = FALSE)
  # Okabe-Ito colours, readable on light and dark and for colour-blind readers
  palette <- c("#0072B2", "#E69F00", "#009E73", "#CC79A7", "#D55E00", "#56B4E9", "#F0E442", "#999999")
  colours <- stats::setNames(rep_len(palette, length(s$scales)), s$scales)
  ink <- if (dark) "#dee2e6" else "#343a40"
  grid <- if (dark) "#495057" else "#e9ecef"
  log$hover <- sprintf(
    "<b>%s</b><br>%s<br>Answer %d (scored %d)<br>\u03b8 = %.2f, SE = %.3f",
    log$scale, log$question, log$answer, log$score, log$theta, log$se
  )

  panel <- function(y, legend) {
    p <- plotly::plot_ly()
    for (sc in unique(log$scale)) {
      d <- log[log$scale == sc, ]
      p <- plotly::add_trace(p,
        x = d$step, y = d[[y]], type = "scatter", mode = "lines+markers",
        name = sc, legendgroup = sc, showlegend = legend,
        line = list(color = colours[[sc]], width = 2),
        marker = list(color = colours[[sc]], size = 8),
        text = d$hover, hoverinfo = "text"
      )
    }
    p
  }
  # the stopping SE, as a dashed line in the SE panel (subplot() drops shapes added to the layout)
  se_panel <- plotly::add_trace(panel("se", FALSE),
    x = c(0.5, max(log$step) + 0.5), y = rep(s$se_threshold, 2), type = "scatter", mode = "lines",
    name = "stopping SE", showlegend = FALSE, hoverinfo = "skip",
    line = list(color = "#dc3545", dash = "dash", width = 1.5)
  )
  axis <- list(color = ink, gridcolor = grid, zerolinecolor = grid, linecolor = grid)
  # a label on every answer, or every 2nd, 3rd... so that there are at most about 12
  step <- max(1, ceiling(max(log$step) / 12))
  # theta on the left, SE on the right, each with its own answer axis
  fig <- plotly::subplot(panel("theta", TRUE), se_panel,
    nrows = 1, titleX = TRUE, titleY = TRUE, margin = 0.07
  )
  plotly::layout(fig,
    paper_bgcolor = "rgba(0,0,0,0)",
    plot_bgcolor = "rgba(0,0,0,0)",
    font = list(color = ink),
    legend = list(orientation = "h", x = 0, y = 1.12, font = list(color = ink)),
    hoverlabel = list(align = "left"),
    modebar = list(bgcolor = "rgba(0,0,0,0)", color = ink, activecolor = "#0d6efd"),
    margin = list(t = 40, r = 10, b = 50, l = 60),
    xaxis = c(axis, list(title = "Answer", dtick = step)),
    xaxis2 = c(axis, list(title = "Answer", dtick = step)),
    yaxis = c(axis, list(title = "\u03b8 (standardized)")),
    yaxis2 = c(axis, list(title = "SE", rangemode = "tozero")),
    annotations = list(list(
      xref = "x2 domain", x = 0.01, xanchor = "left", yref = "y2", y = s$se_threshold, yanchor = "bottom",
      text = sprintf("stop at SE \u2264 %.2f", s$se_threshold), showarrow = FALSE,
      font = list(color = "#dc3545", size = 11)
    ))
  ) |>
    plotly::config(displaylogo = FALSE, modeBarButtonsToRemove = c("lasso2d", "select2d", "autoScale2d"))
}
