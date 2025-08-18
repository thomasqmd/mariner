#' Create R Markdown Source Files from a Package Template
#'
#' @description
#' Creates multiple R Markdown (.Rmd) source files from a parameterized
#' template located within a package. These Rmd files can then be edited
#' before being rendered or bundled.
#'
#' @param params_df A data frame where each row represents a report to be
#'   created. Column names must match the parameter names in the Rmd template's
#'   YAML header (e.g., "a", "b", "author").
#' @param template_name The name of the template directory inside
#'   `inst/rmarkdown/templates`.
#' @param template_package The name of the installed package where the template
#'   is located. **Defaults to "mariner"**.
#' @param output_dir The directory where the final .Rmd files will be saved.
#'
#' @return Invisibly returns a character vector of the output file paths for
#'   the newly created .Rmd files.
#' @export
#' @importFrom purrr pwalk
#' @importFrom fs dir_create
#'
#' @examples
#' \dontrun{
#' # --- Setup: Create a temporary directory for the Rmd files ---
#' temp_dir <- tempfile("rmd-sources-")
#' dir.create(temp_dir)
#'
#' # --- 1. Define the parameters for the reports ---
#' report_params <- tidyr::expand_grid(a = 1, b = 1:2, author = "Dr. Lastname")
#'
#' # --- 2. Generate the .Rmd source files ---
#' # This creates 'Report-1_1.Rmd' and 'Report-1_2.Rmd' in temp_dir.
#' rmd_files <- generate_reports(
#'   params_df = report_params,
#'   template_name = "simple_report",
#'   output_dir = temp_dir
#' )
#'
#' # --- You can now inspect or edit the generated Rmd files ---
#' list.files(temp_dir)
#'
#' # --- 3. Process the generated Rmd files into zip bundles ---
#' # This is where the workflow connects to process_files().
#' process_files(rmd_files)
#'
#' # --- View the final output ---
#' # The directory now contains the Rmd files and their corresponding zip files.
#' list.files(temp_dir)
#'
#' # --- Cleanup ---
#' unlink(temp_dir, recursive = TRUE)
#' }
generate_reports <- function(params_df,
                             template_name,
                             template_package = "mariner",
                             output_dir = ".") {
  # --- 1. Find the template file path ---
  template_path <- system.file(
    "rmarkdown", "templates", template_name, "skeleton", "skeleton.Rmd",
    package = template_package,
    mustWork = TRUE
  )
  fs::dir_create(output_dir)
  template_content <- readLines(template_path)

  # --- 2. Define a helper function to create one Rmd file ---
  create_one_rmd <- function(...) {
    current_params <- list(...)
    output_filename <- file.path(output_dir, paste0("Report-", current_params$a, "_", current_params$b, ".Rmd"))

    # Substitute parameter values in the template content
    modified_content <- gsub("a: 1", paste("a:", current_params$a), template_content)
    modified_content <- gsub("b: 1", paste("b:", current_params$b), modified_content)
    modified_content <- gsub(
      'author: "Default Author Name"',
      paste0('author: "', current_params$author, '"'),
      modified_content
    )

    # Write the new Rmd file
    writeLines(modified_content, output_filename)
  }

  # --- 3. Iterate over the parameter data frame and create each Rmd file ---
  message("Generating ", nrow(params_df), " Rmd files...")
  purrr::pwalk(params_df, create_one_rmd)

  # --- 4. Return the expected output paths for confirmation ---
  output_paths <- file.path(
    output_dir,
    paste0("Report-", params_df$a, "_", params_df$b, ".Rmd")
  )

  message("Rmd file generation complete.")
  invisible(output_paths)
}
