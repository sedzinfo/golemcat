# The PDF report of a test

Writes the profile of a finished CAT session as a PDF: the five traits
at a glance, a page on each trait, and how the scores are calculated,
with the numbers of the session. It needs the 'typst' command line (see
[`typst_command`](https://sedzinfo.github.io/golemcat/reference/typst_command.md)).

## Usage

``` r
report_pdf(res, file, bank = ipip50()$bank, date = Sys.Date())
```

## Arguments

- res:

  The results, from
  [`cat_results`](https://sedzinfo.github.io/golemcat/reference/cat_results.md).

- file:

  Path of the PDF to write.

- bank:

  The item bank, from
  [`read_item_bank`](https://sedzinfo.github.io/golemcat/reference/read_item_bank.md);
  it gives the spread (prior standard deviation) of each trait.

- date:

  The date printed on the report.

## Value

`file`, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
q <- ipip50()
s <- cat_start(q$bank, unique(q$bank$scale))
while (s$stage == "testing") s <- cat_answer(s, sample(1:5, 1))
report_pdf(cat_results(s), "profile.pdf", q$bank)
} # }
```
