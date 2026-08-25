#' Bundle a Quarto File and its Outputs
#'
#' @description
#' Renders a Quarto (.qmd) file and bundles the source file, the purled R
#' script, and all rendering outputs into a single zip archive.
#'
#' @param input_file Path to the input `.qmd` file.
#' @param output_zip Path for the output `.zip` file.
#'
#' @return Invisibly returns the path to the created zip file.
#' @export
#' @importFrom knitr purl
#' @importFrom quarto quarto_render
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
#' # `generate_reports` returns the path to the created .qmd file
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

  if (!identical(input_ext, "qmd")) {
    stop(
      "Input file must be a .qmd file. Got: .",
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
        knitr::purl(doc_file_name)
        quarto::quarto_render(doc_file_name, quiet = TRUE)
      },
      error = \(e) {
        stop("Failed during file processing: ", e$message, call. = FALSE)
      }
    )

    # Bundle everything the render left behind.
    #
    # zip::zip(), not utils::zip(): the latter shells out to an external `zip`
    # binary that a stock Windows install does not have, so a student without
    # Rtools on PATH got a nonzero status this code never checked and an empty
    # or missing archive. It also ADDS to an existing archive rather than
    # replacing it, so re-running a batch left yesterday's stale entries inside
    # today's bundle. zip::zip is pure C, needs no system tool, and replaces.
    #
    # `recurse = TRUE` reaches into the `_files/` directory Quarto writes beside
    # the output; `root` makes every archive path relative to the scratch
    # directory, so the zip has no absolute paths in it.
    files_to_zip <- fs::path_file(fs::dir_ls())
    zip::zip(
      zipfile = output_path,
      files = files_to_zip,
      root = ".",
      recurse = TRUE
    )
  })

  if (!file.exists(output_path)) {
    stop("Bundling failed: no archive at ", output_path, call. = FALSE)
  }

  message("Successfully created bundle: ", fs::path_file(output_path))
  invisible(output_path)
}
