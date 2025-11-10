#' Bundle Multiple R Markdown Files Sequentially or in Parallel
#'
#' @description
#' A wrapper around `process_file()` to process a list of R Markdown
#' files. Execution is sequential by default but can be run in parallel by
#' setting a `future` plan (e.g., `future::plan(future::multisession)`).
#'
#' @param input_files A character vector of paths to the `.Rmd` files.
#' @param output_dir An optional path to a directory where the output zip
#'   archives will be saved. If `NULL` (the default), each zip is created in
#'   the same directory as its corresponding input `.Rmd` file.
#'
#' @return Invisibly returns a character vector of paths to the successfully
#'   created zip archives. Any file that fails to process will be represented
#'   by an `NA` in the output vector.
#' @export
#' @importFrom purrr possibly map2_chr
#' @importFrom furrr future_map_chr
#' @importFrom future plan multisession
#' @importFrom fs path_ext_set file_exists dir_create path_file
#'
#' @examples
#' \dontrun{
#' # --- Setup: Create a temporary directory and generate Rmd files ---
#' temp_dir <- tempfile("example-")
#' dir.create(temp_dir)
#'
#' report_params <- tidyr::expand_grid(
#'   chapter = 1,
#'   problem_numbers = 1:2,
#'   author = "Firstname Lastname"
#' )
#'
#' rmd_files <- generate_reports(
#'   params_df = report_params,
#'   template_name = "simple_report",
#'   output_dir = temp_dir
#' )
#'
#' # --- Example 1: Default behavior (zips next to Rmds) ---
#' process_files(rmd_files)
#' list.files(temp_dir)
#'
#' # --- Example 2: Specifying an output directory ---
#' zip_output_dir <- file.path(temp_dir, "zips")
#' process_files(rmd_files, output_dir = zip_output_dir)
#' list.files(zip_output_dir)
#'
#' # --- Cleanup ---
#' unlink(temp_dir, recursive = TRUE)
#' }
process_files <- function(input_files, output_dir = NULL) {
  safe_bundle <- purrr::possibly(process_file, otherwise = NA_character_)

  # Determine the output paths for each file
  if (is.null(output_dir)) {
    # If no output dir, zips are created next to the input files
    output_zip_paths <- purrr::map_chr(input_files, ~ fs::path_ext_set(.x, ".zip"))
  } else {
    # If output dir is specified, create it and define paths there
    if (!fs::file_exists(output_dir)) fs::dir_create(output_dir)
    output_zip_paths <- purrr::map_chr(input_files, ~ {
      file.path(output_dir, fs::path_file(fs::path_ext_set(.x, ".zip")))
    })
  }

  message("Starting bundling process...")
  # Use purrr::map2_chr to iterate over both inputs and outputs
  output_paths <- furrr::future_map2_chr(
    .x = input_files,
    .y = output_zip_paths,
    .f = ~ safe_bundle(input_file = .x, output_zip = .y),
    .progress = TRUE
  )

  success_count <- sum(!is.na(output_paths))
  failure_count <- sum(is.na(output_paths))

  message(
    "Bundling complete. Success: ", success_count, ", Failures: ", failure_count, "."
  )

  invisible(output_paths)
}
