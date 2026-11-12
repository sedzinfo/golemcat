# Start an adaptive test

Starts a computerized adaptive test (CAT) over the chosen scales of an
item bank, one scale at a time, in the order given. Within a scale, each
next item is the most informative one left
([`next_item_rsm`](https://sedzinfo.github.io/golemcat/reference/next_item_rsm.md));
after each answer the ability is estimated again by EAP
([`eap_est_rsm`](https://sedzinfo.github.io/golemcat/reference/eap_est_rsm.md)),
with the normal prior of the scale, over a grid of \\\pm 6\\ prior
standard deviations. A scale stops when the standard error, divided by
the prior standard deviation, is at most `se_threshold`, or when its
items run out; the test then moves to the next scale.

## Usage

``` r
cat_start(bank, scales = unique(bank$scale), se_threshold = 0.45)
```

## Arguments

- bank:

  An item bank read with
  [`read_item_bank`](https://sedzinfo.github.io/golemcat/reference/read_item_bank.md).

- scales:

  The scales to test, in order.

- se_threshold:

  Standardized standard error at which a scale stops.

## Value

A CAT session: a list to pass to
[`cat_answer`](https://sedzinfo.github.io/golemcat/reference/cat_answer.md),
[`cat_item`](https://sedzinfo.github.io/golemcat/reference/cat_item.md)
and
[`cat_results`](https://sedzinfo.github.io/golemcat/reference/cat_results.md).
Its `stage` is `"testing"` until the last scale stops, then `"done"`;
`progress` has one row per scale and `log` one row per answer.

## Details

Abilities and standard errors are reported standardized per scale
(divided by the prior standard deviation), so the same threshold is the
same target in every scale: a threshold `se` aims at a reliability of
about \\1 - se^2\\.

## See also

Other CAT session:
[`cat_answer()`](https://sedzinfo.github.io/golemcat/reference/cat_answer.md),
[`cat_item()`](https://sedzinfo.github.io/golemcat/reference/cat_item.md),
[`cat_results()`](https://sedzinfo.github.io/golemcat/reference/cat_results.md)

## Examples

``` r
q <- ipip50()
s <- cat_start(q$bank, scales = "Extraversion", se_threshold = 0.45)
while (s$stage == "testing") s <- cat_answer(s, 4) # always "Moderately accurate"
cat_results(s)
#>          scale     theta        se percentile answered total    status
#> 1 Extraversion 0.3236773 0.4318709   62.69088        4    10 completed
s$log
#>   step        scale                                        question answer     theta        se
#> 1    1 Extraversion I talk to a lot of different people at parties.      4 0.5714096 0.7170862
#> 2    2 Extraversion                    I am quiet around strangers.      4 0.2657205 0.5712175
#> 3    3 Extraversion                     I am the life of the party.      4 0.5382870 0.4896811
#> 4    4 Extraversion       I don't like to draw attention to myself.      4 0.3236773 0.4318709
```
