##########################################################################################
#
##########################################################################################
#' Path to a file installed with the app
#'
#' \code{system.file()} for this package: finds the files of \code{inst/} (the
#' \code{app/www} folder, \code{golem-config.yml}) whether the package is
#' installed or loaded with \code{pkgload::load_all()}. The package name is
#' written here, in DESCRIPTION and in \code{inst/golem-config.yml}; when
#' renaming the package, change all three, or use
#' \code{golem::set_golem_name()}.
#'
#' @param ... Character vectors, giving the subdirectory and file(s) inside
#'   \code{inst/}. Without any, the root of the installed package.
#'
#' @return The full path, or \code{""} if the file does not exist.
#'
#' @noRd
#'
#' @examples
#' \dontrun{
#' app_sys("app/www")
#' app_sys("golem-config.yml")
#' }
app_sys <- function(...) {
  system.file(..., package = "golemcat")
}
##########################################################################################
#
##########################################################################################
#' Read a value of the app configuration
#'
#' Reads \code{inst/golem-config.yml}, the golem settings of the app (its name,
#' version, whether it runs in production), for the active configuration.
#'
#' @param value Name of the value to read.
#' @param config Configuration to read: the environment variable
#'   \code{GOLEM_CONFIG_ACTIVE}, or else \code{R_CONFIG_ACTIVE}, or else
#'   \code{"default"}.
#' @param use_parent Logical. Look for the file in the parent directories too.
#' @param file Path of the configuration file: the environment variable
#'   \code{GOLEM_CONFIG_PATH}, or else the file installed with the package.
#'
#' @return The value, as \code{config::get()} returns it.
#'
#' @noRd
#'
#' @examples
#' \dontrun{
#' get_golem_config("golem_name")
#' get_golem_config("app_prod")
#' }
get_golem_config <- function(
  value,
  config = Sys.getenv(
    "GOLEM_CONFIG_ACTIVE",
    Sys.getenv(
      "R_CONFIG_ACTIVE",
      "default"
    )
  ),
  use_parent = TRUE,
  # If you don't want to use the default config file,
  # set a `GOLEM_CONFIG_PATH` environment variable that points
  # to your custom config file.
  file = Sys.getenv(
    "GOLEM_CONFIG_PATH",
    app_sys(
      "golem-config.yml"
    )
  )
) {
  config::get(
    value = value,
    config = config,
    file = file,
    use_parent = use_parent
  )
}
