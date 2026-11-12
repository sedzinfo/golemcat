# Run the app

Starts the app, an adaptive (CAT) test of the Big Five personality
traits with the 50 statements of the IPIP Big-Five Factor Markers. It
has two tabs:

- Take the test:

  The questionnaire as a respondent sees it: one statement at a time,
  and at the end a profile of the five traits, each as a percentile of
  the calibration sample, and a PDF report of the profile.

- About:

  How the test works, the acknowledgments and the references.

The workings of an adaptive test, step by step and under six IRT models,
are in the CAT tab of golemirt
(<https://sedzinfo-golemirt.share.connect.posit.cloud/>).

## Usage

``` r
run_app(
  se_threshold = 0.4,
  analytics = FALSE,
  keep_alive = TRUE,
  onStart = NULL,
  options = list(),
  enableBookmarking = NULL,
  uiPattern = "/",
  ...
)
```

## Arguments

- se_threshold:

  Standardized standard error at which a trait stops in the Take the
  test tab. The default 0.40 aims at a reliability of about .84 per
  trait and uses about 43 of the 50 statements; 0.45 uses about 36.

- analytics:

  `TRUE` to add Google Analytics, through the cookie banner shared with
  the sites of sedzinfo.github.io, which loads it only after the visitor
  accepts. Meant for the public deployment (see `app.R`); off by
  default, so that running the app yourself sends nothing.

- keep_alive:

  `TRUE` to ping the server every 15 seconds while the page is open, so
  that proxies do not close idle connections.

- onStart:

  A function that will be called before the app is actually run. This is
  only needed for `shinyAppObj`, since in the `shinyAppDir` case, a
  `global.R` file can be used for this purpose.

- options:

  Named options that should be passed to the `runApp` call (these can be
  any of the following: "port", "launch.browser", "host", "quiet",
  "display.mode" and "test.mode"). You can also specify `width` and
  `height` parameters which provide a hint to the embedding environment
  about the ideal height/width for the app.

- enableBookmarking:

  Can be one of `"url"`, `"server"`, or `"disable"`. The default value,
  `NULL`, will respect the setting from any previous calls to
  [`enableBookmarking()`](https://rdrr.io/pkg/shiny/man/enableBookmarking.html).
  See
  [`enableBookmarking()`](https://rdrr.io/pkg/shiny/man/enableBookmarking.html)
  for more information on bookmarking your app.

- uiPattern:

  A regular expression that will be applied to each `GET` request to
  determine whether the `ui` should be used to handle the request. Note
  that the entire request path must match the regular expression in
  order for the match to be considered successful.

- ...:

  Arguments passed on to `golem_opts`; see
  [`?golem::get_golem_options`](https://thinkr-open.github.io/golem/reference/get_golem_options.html).

## Value

A `shiny.appobj`: printed, it starts the app.

## Examples

``` r
if (FALSE) { # \dontrun{
run_app()
run_app(se_threshold = 0.45, options = list(port = 8080))
} # }
```
