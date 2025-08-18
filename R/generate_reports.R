#' Generate Reports from a Package Template
#'
#' @description
#' Renders multiple PDF reports from a parameterized R Markdown template
#' located within a package.
#'
#' @param params_df A data frame where each row represents a report. Column
#'   names must match the parameter names in the Rmd template's YAML header
#'   (e.g., "a", "b", "author").
#' @param template_name The name of the template directory inside
#'   `inst/rmarkdown/templates`.
#' @param template_package The name of the installed package where the template
#'   is located. **Defaults to "mariner"**, assuming the template is in the
#'   current package.
#' @param output_dir The directory where the final rendered reports will be saved.
#'
#' @return Invisibly returns a character vector of the output file paths.
#' @export
#' @importFrom rmarkdown render
#' @importFrom purrr pwalk
#' @importFrom utils installed.packages
#' @examples
#' \dontrun{
#' # --- Using a Template to Generate Reports ---
#'
#' # Define the parameters for the reports.
#' report_params <- tidyr::expand_grid(a = 1, b = 1:2, author = "Dr. Lastname")
#'
#' # Generate reports using the template from the current "mariner" package.
#' # Note: We don't have to specify `template_package` because it defaults to "mariner".
#' generate_reports(
#'   params_df = report_params,
#'   template_name = "simple_report",
#'   output_dir = "temp_reports"
#' )
#'
#' # Clean up the created directory.
#' unlink("temp_reports", recursive = TRUE)
#' }
generate_reports <- function(params_df,
                             template_name,
                             template_package = "mariner",
                             output_dir = ".") {
  # --- 1. Check if the source package is available ---
  if (!template_package %in% c(.packages(), rownames(installed.packages()))) {
    stop("Package '", template_package, "' is not loaded or installed.", call. = FALSE)
  }

  # --- 2. Find the template file path ---
  template_path <- system.file(
    "rmarkdown", "templates", template_name, "skeleton", "skeleton.Rmd",
    package = template_package,
    mustWork = TRUE
  )

  # --- 3. Define a helper function to render one report ---
  render_one_report <- function(...) {
    current_params <- list(...)
    output_filename <- paste0("Report-", current_params$a, "_", current_params$b, ".pdf")
    rmarkdown::render(
      input = template_path,
      output_file = output_filename,
      output_dir = output_dir,
      params = current_params,
      quiet = TRUE
    )
  }

  # --- 4. Iterate over the parameter data frame and render each report ---
  message("Generating ", nrow(params_df), " reports from the '", template_package, "' package...")
  purrr::pwalk(params_df, render_one_report)

  # --- 5. Return the expected output paths for confirmation ---
  output_paths <- file.path(
    output_dir,
    paste0("Report-", params_df$a, "_", params_df$b, ".pdf")
  )

  message("Report generation complete.")
  invisible(output_paths)
}
