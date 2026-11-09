# Results of a CAT session

The standardized ability of each scale, its standard error, and the
percentile: the share of the population of the calibration sample
expected below that ability, assuming a normal distribution (`pnorm` of
the standardized ability).

## Usage

``` r
cat_results(s)
```

## Arguments

- s:

  A CAT session.

## Value

A data frame, one row per scale: `scale`, `theta` and `se`
(standardized), `percentile` (0 to 100), `answered`, `total` and
`status`.

## See also

Other CAT session:
[`cat_answer()`](https://sedzinfo.github.io/golemcat/reference/cat_answer.md),
[`cat_item()`](https://sedzinfo.github.io/golemcat/reference/cat_item.md),
[`cat_start()`](https://sedzinfo.github.io/golemcat/reference/cat_start.md)

## Examples

``` r
s <- cat_start(ipip50()$bank, scales = c("Openness", "Neuroticism"))
while (s$stage == "testing") s <- cat_answer(s, 2)
cat_results(s)
#>         scale      theta        se percentile answered total    status
#> 1    Openness -1.3686299 0.4290122   8.555749        7    10 completed
#> 2 Neuroticism -0.8605767 0.4240015  19.473561        6    10 completed
```
