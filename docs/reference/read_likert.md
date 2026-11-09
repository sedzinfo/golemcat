# Read the answer options

Reads the answer options of a questionnaire: a csv with the columns
`value` (1 to 5) and `label`, from the lowest to the highest agreement.
The answer `v` is scored as category `v - 1` of the rating scale model
(`5 - v` on reversed items), so with the 4 thresholds `b1` to `b4` there
must be exactly the values 1 to 5.

## Usage

``` r
read_likert(likert_csv)
```

## Arguments

- likert_csv:

  Path to the csv file, saved as UTF-8.

## Value

A data frame with the columns `value` and `label`, ordered by value.

## See also

Other item bank:
[`ipip50()`](https://sedzinfo.github.io/golemcat/reference/ipip50.md),
[`read_item_bank()`](https://sedzinfo.github.io/golemcat/reference/read_item_bank.md),
[`validate_item_bank_against_mirt()`](https://sedzinfo.github.io/golemcat/reference/validate_item_bank_against_mirt.md)

## Examples

``` r
read_likert(system.file("extdata", "ipip50_likert.csv", package = "golemcat"))
#>   value                           label
#> 1     1                 Very inaccurate
#> 2     2           Moderately inaccurate
#> 3     3 Neither accurate nor inaccurate
#> 4     4             Moderately accurate
#> 5     5                   Very accurate
```
