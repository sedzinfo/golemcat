# Package index

## App

- [`run_app()`](https://sedzinfo.github.io/golemcat/reference/run_app.md)
  : Run the app

## Questionnaire

The IPIP-50 item bank and answer options, and reading and checking item
banks fitted with mirt

- [`ipip50()`](https://sedzinfo.github.io/golemcat/reference/ipip50.md)
  : The IPIP-50 Big Five questionnaire
- [`read_item_bank()`](https://sedzinfo.github.io/golemcat/reference/read_item_bank.md)
  : Read an item bank
- [`read_likert()`](https://sedzinfo.github.io/golemcat/reference/read_likert.md)
  : Read the answer options
- [`validate_item_bank_against_mirt()`](https://sedzinfo.github.io/golemcat/reference/validate_item_bank_against_mirt.md)
  : Check an item bank against its mirt model

## Adaptive test

The CAT session: start, next item, answer, results

- [`cat_start()`](https://sedzinfo.github.io/golemcat/reference/cat_start.md)
  : Start an adaptive test
- [`cat_item()`](https://sedzinfo.github.io/golemcat/reference/cat_item.md)
  : The item to show now
- [`cat_answer()`](https://sedzinfo.github.io/golemcat/reference/cat_answer.md)
  : Answer the current item
- [`cat_results()`](https://sedzinfo.github.io/golemcat/reference/cat_results.md)
  : Results of a CAT session

## Report

The PDF report of the profile, made with typst

- [`report_pdf()`](https://sedzinfo.github.io/golemcat/reference/report_pdf.md)
  : The PDF report of a test

## Rating scale model engine

Response probabilities, information, item selection, likelihood and EAP,
the same as catR

- [`Pi_rsm()`](https://sedzinfo.github.io/golemcat/reference/Pi_rsm.md)
  : Category response probabilities of the rating scale model
- [`Ii_rsm()`](https://sedzinfo.github.io/golemcat/reference/Ii_rsm.md)
  : Item information of the rating scale model
- [`next_item_rsm()`](https://sedzinfo.github.io/golemcat/reference/next_item_rsm.md)
  : Next item by maximum Fisher information
- [`likelihood_rsm()`](https://sedzinfo.github.io/golemcat/reference/likelihood_rsm.md)
  : Likelihood of a response pattern under the rating scale model
- [`eap_est_rsm()`](https://sedzinfo.github.io/golemcat/reference/eap_est_rsm.md)
  : EAP ability estimate under the rating scale model
- [`eap_se_rsm()`](https://sedzinfo.github.io/golemcat/reference/eap_se_rsm.md)
  : Standard error of the EAP estimate under the rating scale model
- [`density_function()`](https://sedzinfo.github.io/golemcat/reference/density_function.md)
  : Normal density
- [`integrate_cat()`](https://sedzinfo.github.io/golemcat/reference/integrate_cat.md)
  : Numerical integration by the trapezoidal rule

## UI

Internal functions not meant to run independently

## Server

Internal functions not meant to run independently
