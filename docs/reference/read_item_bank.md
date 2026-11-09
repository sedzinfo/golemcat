# Read an item bank

Reads the item bank of a questionnaire, fitted with the rating scale
model of `mirt` (`itemtype = "rsm"`), and converts the coefficients to
the form of the engine
([`Pi_rsm`](https://sedzinfo.github.io/golemcat/reference/Pi_rsm.md)):
\\\lambda_j = -c\\ and \\\delta_t = b_t\\. It stops with a message
naming the problem when the file is not a complete rating scale bank, so
that an app does not start and then fail on the first answer.

## Usage

``` r
read_item_bank(items_csv)
```

## Arguments

- items_csv:

  Path to the csv file, saved as UTF-8.

## Value

A data frame, one row per item: `scale`, `question`, `stem`, `reverse`,
`lambdaj`, `delta1` to `delta4`, `prior_mean` (always 0) and `prior_sd`.

## Details

The csv has one row per item, with the columns `scale` and `question`
(the text of the item); `a1`, `b1` to `b4` and `c`, the coefficients of
`mirt`; and `prior_sd`, the standard deviation of the latent
distribution of the scale, which `mirt` estimates. Optional columns:
`stem`, the instruction shown above the item, and `reverse`
(`TRUE`/`FALSE`), for items whose answers were reversed (6 - answer)
before the fit. Other columns are ignored.

## See also

Other item bank:
[`ipip50()`](https://sedzinfo.github.io/golemcat/reference/ipip50.md),
[`read_likert()`](https://sedzinfo.github.io/golemcat/reference/read_likert.md),
[`validate_item_bank_against_mirt()`](https://sedzinfo.github.io/golemcat/reference/validate_item_bank_against_mirt.md)

## Examples

``` r
bank <- read_item_bank(system.file("extdata", "ipip50_items.csv", package = "golemcat"))
head(bank[, c("scale", "question", "reverse", "lambdaj")])
#>           scale                                        question reverse      lambdaj
#> 1 Agreeableness                     I Make people feel at ease.   FALSE  0.005745269
#> 2 Agreeableness               I Feel little concern for others.    TRUE  0.000000000
#> 3 Agreeableness                      I Am interested in people.   FALSE -0.276373167
#> 4 Agreeableness                                I Insult people.    TRUE -0.168629507
#> 5 Agreeableness             I Sympathize with others' feelings.   FALSE -0.408719449
#> 6 Agreeableness I Am not interested in other people's problems.    TRUE -0.164829510
```
