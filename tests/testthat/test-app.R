test_that("the page has the two tabs, the dark mode switch and the link to the CAT of golemirt", {
  html <- htmltools::renderTags(app_ui(NULL))$html
  for (tab in c("Take the test", "About")) {
    expect_match(html, paste0("data-value=\"", tab, "\""), fixed = TRUE)
  }
  expect_match(html, "bslib-input-dark-mode", fixed = TRUE)
  expect_match(html, "Acknowledgments", fixed = TRUE)
  expect_match(html, "International Personality Item Pool", fixed = TRUE)
  expect_no_match(html, "data-value=\"CAT\"", fixed = TRUE)
  expect_match(html, "https://sedzinfo-golemirt.share.connect.posit.cloud/", fixed = TRUE)
})

test_that("run_app() returns a shiny app with the threshold in the golem options", {
  app <- run_app(se_threshold = 0.45)
  expect_s3_class(app, "shiny.appobj")
  expect_equal(app$appOptions$golem_options$se_threshold, 0.45)
})

test_that("every file of inst/app/www that the page names exists", {
  head <- htmltools::renderTags(app_ui(NULL, analytics = TRUE, keep_alive = TRUE))$head
  files <- unique(regmatches(head, gregexpr("www/[A-Za-z0-9_.-]+", head))[[1]])
  expect_true(length(files) >= 2)
  expect_equal(files[!file.exists(file.path(app_sys("app"), files))], character())
})

test_that("the server starts every module", {
  expect_no_error(testServer(app_server, {}))
})

test_that("Google Analytics and its cookie banner are in the page only when asked for", {
  page <- function(analytics) htmltools::renderTags(app_ui(NULL, analytics = analytics))
  with <- page(TRUE)
  expect_match(with$head, "https://sedzinfo.github.io/consent.js", fixed = TRUE)
  expect_match(with$head, "www/analytics.js", fixed = TRUE)
  expect_match(with$html, "#cookie-settings", fixed = TRUE)
  expect_match(with$html, "https://sedzinfo.github.io/privacy.html", fixed = TRUE)
  without <- page(FALSE)
  expect_no_match(without$head, "consent.js", fixed = TRUE)
  expect_no_match(without$html, "cookie-settings", fixed = TRUE)
  # run_app() leaves it off: only the deployed app.R turns it on
  expect_false(formals(run_app)$analytics)
})
