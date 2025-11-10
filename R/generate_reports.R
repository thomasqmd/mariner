#' Create R Markdown or Quarto Source Files from a Template
#'
#' @description
#' Creates multiple R Markdown (.Rmd) or Quarto (.qmd) source files from a
#' parameterized template. The template can be located within a package or
#' provided as a direct file path.
#'
#' @param params_df A data frame where each row represents a report to be
#'   created. Column names must match the parameter names in the template's
#'   YAML header (e.g., "chapter", "problem_numbers", "author").
#' @param template_name The name of the template directory inside
#'   `inst/rmarkdown/templates`. This is ignored if `template_path` is provided.
#' @param template_package The name of the installed package where the template
#'   is located. Defaults to "mariner".
#' @param output_dir The directory where the final .Rmd or .qmd files will be saved.
#' @param template_path An optional path to a single `.Rmd` or `.qmd` template
#'   file. If provided, this template will be used instead of one from a package.
#'
#' @return Invisibly returns a character vector of the output file paths for
#'   the newly created .Rmd or .qmd files.
#' @export
#' @importFrom purrr pwalk
#' @importFrom fs dir_create
#' @importFrom tools file_ext
#'
#' @examples
#' \dontrun{
#' # --- Example 1: Using the default package template (finds .qmd or .Rmd) ---
#' temp_dir_pkg <- tempfile("pkg-example-")
#' dir.create(temp_dir_pkg)
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
#'   output_dir = temp_dir_pkg
#' )
#'
#' list.files(temp_dir_pkg) # Will be .qmd if skeleton.qmd exists
#'
#' # --- Example 2: Using an external .Rmd template file ---
#' temp_dir_ext <- tempfile("ext-example-")
#' dir.create(temp_dir_ext)
#'
#' # Create a custom template on the fly
#' custom_template_path <- file.path(temp_dir_ext, "custom.Rmd")
#' writeLines(
#'   c(
#'     "---",
#'     "title: Custom Report",
#'     "params:",
#'     "  region: Midwest",
#'     "---",
#'     "This report is for the `r params$region` region."
#'   ),
#'   custom_template_path
#' )
#'
#' custom_params <- data.frame(
#'   chapter = 1,
#'   problem_numbers = 1,
#'   region = c("East", "West")
#' )
#'
#' generate_reports(
#'   params_df = custom_params,
#'   template_path = custom_template_path,
#'   output_dir = temp_dir_ext
#' )
#'
#' list.files(temp_dir_ext) # Will be .Rmd
#'
#' # --- Cleanup ---
#' unlink(temp_dir_pkg, recursive = TRUE)
#' unlink(temp_dir_ext, recursive = TRUE)
#' }
generate_reports <- function(
  params_df,
  template_name = "simple_report",
  template_package = "mariner",
  output_dir = ".",
  template_path = NULL
) {
  # --- 1. Find and read the template file ---
  local_template_path <- ""

  if (!is.null(template_path)) {
    if (!file.exists(template_path)) {
      stop("Template file not found at: ", template_path, call. = FALSE)
    }
    local_template_path <- template_path
  } else {
    qmd_path <- system.file(
      "rmarkdown",
      "templates",
      template_name,
      "skeleton",
      "skeleton.qmd",
      package = template_package
    )
    rmd_path <- system.file(
      "rmarkdown",
      "templates",
      template_name,
      "skeleton",
      "skeleton.Rmd",
      package = template_package
    )

    local_template_path <- if (qmd_path != "") {
      qmd_path
    } else if (rmd_path != "") {
      rmd_path
    } else {
      stop(
        "No 'skeleton.qmd' or 'skeleton.Rmd' found for template: ",
        template_name,
        call. = FALSE
      )
    }
  }

  template_content <- readLines(local_template_path)
  template_ext_with_dot <- paste0(".", tools::file_ext(local_template_path))

  fs::dir_create(output_dir)

  # --- 2. Define a helper function to create one file ---
  create_one_file <- function(...) {
    current_params <- list(...)
    output_filename <- file.path(
      output_dir,
      paste0(
        "Report-",
        current_params$chapter,
        "_",
        current_params$problem_numbers,
        template_ext_with_dot
      )
    )

    modified_content <- template_content

    # Identify the YAML front matter block
    yaml_delimiters <- which(grepl("^---$", modified_content))
    if (length(yaml_delimiters) < 2) {
      writeLines(modified_content, output_filename)
      return()
    }
    yaml_header_indices <- (yaml_delimiters[1] + 1):(yaml_delimiters[2] - 1)
    yaml_header <- modified_content[yaml_header_indices]

    params_start_in_yaml <- which(grepl("^params:", yaml_header))

    if (length(params_start_in_yaml) > 0) {
      following_lines <- yaml_header[
        (params_start_in_yaml + 1):length(yaml_header)
      ]
      next_unindented_line <- which(!grepl("^\\s+", following_lines))

      params_end_in_yaml <- if (length(next_unindented_line) > 0) {
        params_start_in_yaml + next_unindented_line[1] - 1
      } else {
        length(yaml_header)
      }

      param_lines_indices <- (params_start_in_yaml + 1):params_end_in_yaml

      for (param_name in names(current_params)) {
        param_value <- current_params[[param_name]]
        pattern <- paste0("(\\s*", param_name, ":\\s*).+")
        replacement_value <- ifelse(
          is.character(param_value),
          paste0('"', param_value, '"'),
          param_value
        )
        replacement <- paste0("\\1", replacement_value)
        yaml_header[param_lines_indices] <- gsub(
          pattern,
          replacement,
          yaml_header[param_lines_indices]
        )
      }
      modified_content[yaml_header_indices] <- yaml_header
    }

    writeLines(modified_content, output_filename)
  }

  # --- 3. Iterate over the parameter data frame ---
  file_type_msg <- ifelse(template_ext_with_dot == ".qmd", "Qmd", "Rmd")
  message("Generating ", nrow(params_df), " ", file_type_msg, " files...")
  purrr::pwalk(params_df, create_one_file)

  # --- 4. Return the expected output paths ---
  output_paths <- file.path(
    output_dir,
    paste0(
      "Report-",
      params_df$chapter,
      "_",
      params_df$problem_numbers,
      template_ext_with_dot
    )
  )

  message(file_type_msg, " file generation complete.")
  invisible(output_paths)
}
