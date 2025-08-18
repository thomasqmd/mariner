#' Bundle an R Markdown File and its Outputs
#'
#' @description
#' Renders an R Markdown file and bundles the source `.Rmd`, the purled R
#' script, and all rendering outputs (e.g., `.pdf`, `.tex`, `_files` directory)
#' into a single zip archive. This process occurs in an isolated, temporary
#' directory to avoid cluttering the user's workspace.
#'
#' @param input_file Path to the input `.Rmd` file.
#' @param output_zip Path for the output `.zip` file. If `NULL` (the default),
#'   the zip file is created in the same directory as the input file with the
#'   same base name.
#'
#' @return Invisibly returns the path to the created zip file.
#' @export
#' @importFrom knitr purl
#' @importFrom rmarkdown render
#' @importFrom utils zip
#' @importFrom fs path_abs path_ext_set file_copy dir_create dir_ls dir_delete path_file
#' @importFrom withr with_dir
process_file <- \(input_file, output_zip = NULL) {
  # --- 1. Validate input and set up paths ---
  if (!file.exists(input_file)) {
    stop("Input file does not exist: ", input_file, call. = FALSE)
  }

  input_path <- fs::path_abs(input_file)
  output_path <- if (is.null(output_zip)) {
    fs::path_ext_set(input_path, ".zip")
  } else {
    fs::path_abs(output_zip)
  }

  # --- 2. Create a self-cleaning temporary directory ---
  temp_dir <- tempfile(pattern = "rmd-bundle-")
  fs::dir_create(temp_dir)
  on.exit(fs::dir_delete(temp_dir), add = TRUE)

  # --- 3. Process inside the temp directory for isolation ---
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

  # --- 4. Return the path to the created zip file ---
  message("Successfully created bundle: ", fs::path_file(output_path))
  invisible(output_path)
}
