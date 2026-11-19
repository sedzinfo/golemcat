# Google Analytics for the public deployment

Loads the cookie banner shared with the sites of sedzinfo.github.io,
which loads Google Analytics only after the visitor accepts (and has the
navy of those sites), and the script shared by the apps that reports
each tab the visitor opens as a page view, and the PDF report as a
download (`https://sedzinfo.github.io/shiny/analytics.js`).

## Usage

``` r
analytics_resources()
```

## Value

A `tagList` for the head of the page.

## Examples

``` r
golemcat:::analytics_resources()
#> <script src="https://sedzinfo.github.io/consent.js" defer></script>
#> <script src="https://sedzinfo.github.io/shiny/analytics.js"></script>
```
