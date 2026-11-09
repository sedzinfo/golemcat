# The IPIP-50 Big Five questionnaire

The questionnaire built into the app: the 50 items of the IPIP Big-Five
Factor Markers (Goldberg, 1992; public domain), 10 per trait, with the
coefficients of a rating scale model fitted with `mirt` to each trait
separately, on the responses of 19,718 people to the Big Five test of
the Open-Source Psychometrics Project. The 18 reverse-keyed items were
reversed (6 - answer) before the fit.

## Usage

``` r
ipip50()
```

## Value

A list: `bank`, the item bank (see
[`read_item_bank`](https://sedzinfo.github.io/golemcat/reference/read_item_bank.md)),
with the traits in the order Openness, Conscientiousness, Extraversion,
Agreeableness, Neuroticism, and `likert`, the five answer options (see
[`read_likert`](https://sedzinfo.github.io/golemcat/reference/read_likert.md)).

## See also

Other item bank:
[`read_item_bank()`](https://sedzinfo.github.io/golemcat/reference/read_item_bank.md),
[`read_likert()`](https://sedzinfo.github.io/golemcat/reference/read_likert.md),
[`validate_item_bank_against_mirt()`](https://sedzinfo.github.io/golemcat/reference/validate_item_bank_against_mirt.md)

## Examples

``` r
q <- ipip50()
table(q$bank$scale)
#> 
#>     Agreeableness Conscientiousness      Extraversion       Neuroticism          Openness 
#>                10                10                10                10                10 
q$likert
#>   value                           label
#> 1     1                 Very inaccurate
#> 2     2           Moderately inaccurate
#> 3     3 Neither accurate nor inaccurate
#> 4     4             Moderately accurate
#> 5     5                   Very accurate
```
