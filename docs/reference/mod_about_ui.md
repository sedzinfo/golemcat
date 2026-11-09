# About tab - UI

A static page: what the app does, how the questionnaire was calibrated,
the acknowledgments and references, and the license of the package. It
has no inputs, so it has no module server.

## Usage

``` r
mod_about_ui(id)
```

## Arguments

- id:

  Character. Module namespace id.

## Value

A `tagList` of Shiny UI elements.

## Examples

``` r
if (FALSE) { # \dontrun{
shiny::fluidPage(mod_about_ui("about"))
} # }
```
