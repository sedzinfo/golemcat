# Google Analytics for the public deployment

Loads the cookie banner shared with the sites of sedzinfo.github.io,
which loads Google Analytics only after the visitor accepts, and the
script that reports each tab the visitor opens as a page view
(`inst/app/www/analytics.js`). The stylesheet of the app gives the
banner the navy of those sites.

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
#> <script src="www/analytics.js"></script>
```
