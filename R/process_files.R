#' Bundle many Quarto files, in sequence or in parallel
#'
#' @description
#' [process_file()] over a vector of Quarto (`.qmd`) files. The batch runs
#' sequentially by default, and in parallel under a **future** plan such as
#' `future::plan(future::multisession)`.
#'
#' @details
#' A file that fails to render does not stop the batch. It comes back as `NA`,
#' and its error message is named in the summary. Each render owns a scratch
#' directory, so parallel workers cannot collide.
#'
#' @param input_files A character vector of `.qmd` paths.
#' @param output_dir Where the archives go. Defaults to the project's
#'   `zip_files/` folder. See [mariner_dirs()].
#' @param theme One of [mariner_themes].
#' @param assets_dir Directory that holds a built extension. Resolved once here
#'   and handed to every worker, so a batch of fifty reports stages the theme
#'   from one place.
#' @param include Which categories to bundle. See [process_file()].
#'
#' @return Invisibly, a character vector of the archives created, with `NA` in
#'   the position of any file that failed.
#' @export
#' @importFrom purrr map_chr
#' @importFrom furrr future_map2
#' @importFrom future plan multisession
#' @importFrom fs path_ext_set file_exists dir_create path_file
#'
#' @examples
#' \dontrun{
#' temp_dir <- tempfile("example-")
#'
#' doc_files <- generate_reports(
#'   params_df = data.frame(chapter = 1, problem_numbers = 1:2),
#'   output_dir = temp_dir
#' )
#'
#' process_files(doc_files, output_dir = file.path(temp_dir, "zips"))
#'
#' # In parallel:
#' future::plan(future::multisession, workers = 2)
#' process_files(doc_files, output_dir = file.path(temp_dir, "zips"))
#' future::plan(future::sequential)
#'
#' unlink(temp_dir, recursive = TRUE)
#' }
process_files <- function(input_files,
                          output_dir = NULL,
                          theme = mariner_themes,
                          assets_dir = mariner_dirs()$assets,
                          include = INCLUDE_KINDS) {
  theme <- check_theme(theme)
  include <- rlang::arg_match(include, INCLUDE_KINDS, multiple = TRUE)

  # A NULL output_dir is passed THROUGH as a NULL output_zip rather than being
  # resolved here. process_file() resolves it from each input's own directory,
  # so a batch spanning two projects lands each bundle in its own zip_files/
  # instead of all of them in whichever project getwd() happened to name.
  output_zip_paths <- if (is.null(output_dir)) {
    vector("list", length(input_files))
  } else {
    fs::dir_create(output_dir)
    as.list(purrr::map_chr(
      input_files,
      function(f) file.path(output_dir, fs::path_file(fs::path_ext_set(f, ".zip")))
    ))
  }

  bundle_one <- function(input, output) {
    # Registered inside the WORKER, not once in the parent.
    #
    # mariner_register_fonts() populates a per-session systemfonts registry. A
    # multisession worker is a fresh R process, so it starts without one and its
    # figures fall back to the device default -- silently, and only in parallel,
    # because the parent that ran the sequential test looks perfect. .onLoad()
    # does call this when the worker attaches the package; asserting it here
    # costs nothing and does not depend on that staying true.
    mariner_register_fonts(quiet = TRUE)

    tryCatch(
      list(path = process_file(
        input_file = input,
        output_zip = output,
        theme = theme,
        assets_dir = assets_dir,
        include = include
      ), error = NULL),
      # purrr::possibly()'s NA-on-failure semantics, but the message is KEPT.
      # Discarding it left "Failures: 1" as the entire account of what went
      # wrong, and the only way to find out was to re-run the file by hand.
      error = function(e) list(path = NA_character_, error = conditionMessage(e))
    )
  }

  cli::cli_alert_info("Bundling {length(input_files)} file{?s}...")

  # .progress = TRUE is deprecated in furrr's docs in favour of progressr, but
  # no warning fires on furrr 0.4.0. Housekeeping for a quiet moment, not a fire.
  results <- furrr::future_map2(
    .x = input_files,
    .y = output_zip_paths,
    .f = bundle_one,
    .progress = TRUE
  )

  output_paths <- purrr::map_chr(results, function(r) r$path)
  failed <- is.na(output_paths)

  # Where they LANDED, not where they were told to go: with output_dir = NULL
  # that was decided per file, and reporting the request rather than the result
  # would name a directory that may not be the one holding the archives.
  landed <- unique(dirname(output_paths[!failed]))
  if (length(landed) == 1L) {
    cli::cli_alert_success("Bundled {sum(!failed)} file{?s} to {.file {landed}}")
  } else {
    cli::cli_alert_success("Bundled {sum(!failed)} file{?s}.")
  }

  if (any(failed)) {
    reasons <- purrr::map_chr(results[failed], function(r) r$error)
    names <- fs::path_file(input_files[failed])
    cli::cli_alert_danger("Failed on {sum(failed)} file{?s}:")
    # One bullet per failure, interpolating the message as a VALUE rather than
    # pasting it into the format string. A quarto error containing a brace --
    # any R error mentioning a `{` block does -- would otherwise be re-parsed as
    # glue syntax and throw while reporting the original throw.
    for (i in seq_along(reasons)) {
      cli::cli_bullets(c(x = "{.file {names[i]}}: {reasons[i]}"))
    }
  }

  invisible(output_paths)
}
