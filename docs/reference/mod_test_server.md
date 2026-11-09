# Take the test tab - server

Runs a CAT session
([`cat_start`](https://sedzinfo.github.io/golemcat/reference/cat_start.md))
over every trait of the questionnaire, in order, and shows the results
([`cat_results`](https://sedzinfo.github.io/golemcat/reference/cat_results.md))
when it ends.

## Usage

``` r
mod_test_server(id, questionnaire, se_threshold = 0.4)
```

## Arguments

- id:

  Character. Module namespace id, the same as in
  [`mod_test_ui`](https://sedzinfo.github.io/golemcat/reference/mod_test_ui.md).

- questionnaire:

  The questionnaire, as returned by
  [`ipip50`](https://sedzinfo.github.io/golemcat/reference/ipip50.md).

- se_threshold:

  Standardized standard error at which a trait stops.

## Value

None. Called for its side effect of registering the module server.

## Examples

``` r
if (FALSE) { # \dontrun{
# inside app_server():
mod_test_server("test", ipip50(), se_threshold = 0.40)
} # }
```
