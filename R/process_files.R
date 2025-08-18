#' Bundle Multiple R Markdown Files Sequentially or in Parallel
#'
#' @description
#' A wrapper around `process_file()` to process a list of R Markdown files,
#' with support for parallel execution via the `future` package.
#'
#' @param input_files A character vector of paths to the `.Rmd` files.
#'
#' @return Invisibly returns a character vector of paths to the successfully
#'   created zip archives.
#' @export
#' @importFrom purrr possibly
#' @importFrom furrr future_map_chr
#' @importFrom future plan multisession
#'
#' @examples
#' \dontrun{
#' # --- Setup: Create a temporary directory and generate multiple Rmd files ---
#' temp_dir <- tempfile("example-")
#' dir.create(temp_dir)
#'
#' report_params <- tidyr::expand_grid(a = 1, b = 1:3, author = "Dr. Lastname")
#'
#' # `generate_reports` returns a vector of paths to the created Rmd files.
#' rmd_files_to_bundle <- generate_reports(
#'   params_df = report_params,
#'   template_name = "simple_report",
#'   template_package = "mariner",
#'   output_dir = temp_dir
#' )
#'
#' # --- Example: Process the generated Rmd files into zip bundles ---
#' process_files(rmd_files_to_bundle)
#'
#' # --- View the created files ---
#' # The directory contains the source Rmd files and their corresponding zips.
#' list.files(temp_dir)
#'
#' # --- Cleanup ---
#' unlink(temp_dir, recursive = TRUE)
#' }
process_files <- function(input_files) {
  # Function body remains the same
  safe_bundle <- purrr::possibly(process_file, otherwise = NA_character_)
  message("Starting bundling process...")
  output_paths <- furrr::future_map_chr(
    .x = input_files,
    .f = safe_bundle,
    .progress = TRUE
  )
  success_count <- sum(!is.na(output_paths))
  failure_count <- sum(is.na(output_paths))
  message(
    "Bundling complete. Success: ", success_count, ", Failures: ", failure_count, "."
  )
  invisible(output_paths)
}
