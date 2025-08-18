#' Bundle an R Markdown File and its Outputs
#'
#' @description
#' Renders an R Markdown file and bundles the source `.Rmd`, the purled R
#' script, and all rendering outputs into a single zip archive.
#'
#' @param input_file Path to the input `.Rmd` file.
#' @param output_zip Path for the output `.zip` file.
#'
#' @return Invisibly returns the path to the created zip file.
#' @export
#' @importFrom knitr purl
#' @importFrom rmarkdown render
#' @importFrom utils zip
#' @importFrom fs path_abs path_ext_set file_copy dir_create dir_ls dir_delete path_file
#' @importFrom withr with_dir
#' @examples
#' \dontrun{
#' # --- Setup: Create a temporary directory and generate one Rmd file ---
#' temp_dir <- tempfile("example-")
#' dir.create(temp_dir)
#'
#' report_params <- data.frame(a = 1, b = 1, author = "Dr. Lastname")
#'
#' # `generate_reports` returns the path to the created Rmd file.
#' rmd_file_path <- generate_reports(
#'   params_df = report_params,
#'   template_name = "simple_report",
#'   template_package = "mariner",
#'   output_dir = temp_dir
#' )
#'
#' # --- Example: Bundle the newly created Rmd file ---
#' # This will create 'Report-1_1.zip' in the temp directory.
#' process_file(rmd_file_path)
#'
#' # --- View the created files ---
#' # The directory contains the source .Rmd and the bundled .zip.
#' list.files(temp_dir)
#'
#' # --- Cleanup ---
#' unlink(temp_dir, recursive = TRUE)
#' }
process_file <- \(input_file, output_zip = NULL) {
  # Function body remains the same
  if (!file.exists(input_file)) {
    stop("Input file does not exist: ", input_file, call. = FALSE)
  }
  input_path <- fs::path_abs(input_file)
  output_path <- if (is.null(output_zip)) {
    fs::path_ext_set(input_path, ".zip")
  } else {
    fs::path_abs(output_zip)
  }
  temp_dir <- tempfile(pattern = "rmd-bundle-")
  fs::dir_create(temp_dir)
  on.exit(fs::dir_delete(temp_dir), add = TRUE)
  fs::file_copy(input_path, temp_dir)
  withr::with_dir(temp_dir, {
    rmd_file_name <- fs::path_file(input_path)
    tryCatch(
      {
        knitr::purl(rmd_file_name)
        rmarkdown::render(rmd_file_name, quiet = TRUE, clean = FALSE)
      },
      error = \(e) {
        stop("Failed during Rmd processing: ", e$message, call. = FALSE)
      }
    )
    files_to_zip <- fs::dir_ls()
    utils::zip(zipfile = output_path, files = files_to_zip)
  })
  message("Successfully created bundle: ", fs::path_file(output_path))
  invisible(output_path)
}
