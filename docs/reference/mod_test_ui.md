# Take the test tab - UI

The questionnaire as the person taking it sees it: an introduction, one
statement at a time with a progress bar, and at the end a profile of the
five traits.

## Usage

``` r
mod_test_ui(id)
```

## Arguments

- id:

  Character. Module namespace id.

## Value

A `tagList` of Shiny UI elements.

## Examples

``` r
if (FALSE) { # \dontrun{
shiny::fluidPage(mod_test_ui("test"))
} # }
```
