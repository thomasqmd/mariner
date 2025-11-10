#' Bundle an R Markdown or Quarto File and its Outputs
#'
#' @description
#' Renders an R Markdown (.Rmd) or Quarto (.qmd) file and bundles the source
#' file, the purled R script, and all rendering outputs into a single zip archive.
#'
#' @param input_file Path to the input `.Rmd` or `.qmd` file.
#' @param output_zip Path for the output `.zip` file.
#'
#' @return Invisibly returns the path to the created zip file.
#' @export
#' @importFrom knitr purl
#' @importFrom rmarkdown render
#' @importFrom quarto quarto_render
#' @importFrom utils zip
#' @importFrom fs path_abs path_ext_set file_copy dir_create dir_ls dir_delete path_file
#' @importFrom withr with_dir
#' @importFrom tools file_ext
#'
#' @examples
#' \dontrun{
#' # --- Setup: Create a temporary directory and generate one file ---
#' temp_dir <- tempfile("example-")
#' dir.create(temp_dir)
#'
#' report_params <- data.frame(chapter = 1, problem_numbers = 1, author = "Firstname Lastname")
#'
#' # `generate_reports` returns the path to the created file (e.g., .qmd)
#' doc_file_path <- generate_reports(
#'   params_df = report_params,
#'   template_name = "simple_report",
#'   template_package = "mariner",
#'   output_dir = temp_dir
#' )
#'
#' # --- Example: Bundle the newly created file ---
#' # This will create 'Report-1_1.zip' in the temp directory.
#' process_file(doc_file_path)
#'
#' # --- View the created files ---
#' # The directory contains the source file and the bundled .zip.
#' list.files(temp_dir)
#'
#' # --- Cleanup ---
#' unlink(temp_dir, recursive = TRUE)
#' }
process_file <- \(input_file, output_zip = NULL) {
  if (!file.exists(input_file)) {
    stop("Input file does not exist: ", input_file, call. = FALSE)
  }

  input_path <- fs::path_abs(input_file)
  input_ext <- tolower(tools::file_ext(input_path))

  if (!input_ext %in% c("rmd", "qmd")) {
    stop(
      "Input file must be a .Rmd or .qmd file. Got: .",
      input_ext,
      call. = FALSE
    )
  }

  output_path <- if (is.null(output_zip)) {
    fs::path_ext_set(input_path, ".zip")
  } else {
    fs::path_abs(output_zip)
  }

  temp_dir <- tempfile(pattern = "doc-bundle-")
  fs::dir_create(temp_dir)
  on.exit(fs::dir_delete(temp_dir), add = TRUE)

  fs::file_copy(input_path, temp_dir)

  withr::with_dir(temp_dir, {
    doc_file_name <- fs::path_file(input_path)

    tryCatch(
      {
        # Purl the R code. This works for both .Rmd and .qmd.
        knitr::purl(doc_file_name)

        # Conditionally render based on file type
        if (input_ext == "rmd") {
          rmarkdown::render(doc_file_name, quiet = TRUE, clean = FALSE)
        } else if (input_ext == "qmd") {
          quarto::quarto_render(doc_file_name, quiet = TRUE)
        }
      },
      error = \(e) {
        stop("Failed during file processing: ", e$message, call. = FALSE)
      }
    )

    # Bundle all files created in the temp directory
    files_to_zip <- fs::dir_ls()
    utils::zip(zipfile = output_path, files = files_to_zip)
  })

  message("Successfully created bundle: ", fs::path_file(output_path))
  invisible(output_path)
}
