#' Bundle Multiple R Markdown Files Sequentially
#'
#' @description
#' A wrapper around `bundle_rmd()` to process a list of R Markdown
#' files sequentially.
#'
#' @param input_files A character vector of paths to the `.Rmd` files.
#'
#' @return Invisibly returns a character vector of paths to the successfully
#'   created zip archives. Any file that fails to process will be represented
#'   by an `NA` in the output vector.
#' @export
#' @importFrom purrr possibly map_chr
#'
#' @examples
#' \dontrun{
#' # Assumes the 'process_file' function exists and works.
#'
#' # 1. Create dummy Rmd files for demonstration.
#' writeLines("---\ntitle: A\n---", "reportA.Rmd")
#' writeLines("---\ntitle: B\n---", "reportB.Rmd")
#'
#' # 2. Process the batch of files sequentially.
#' files_to_bundle <- c("reportA.Rmd", "reportB.Rmd")
#' process_files(files_to_bundle)
#' # This will create 'reportA.zip' and 'reportB.zip'.
#'
#' # 3. Clean up the created source and bundled files.
#' unlink(c("reportA.Rmd", "reportB.Rmd", "reportA.zip", "reportB.zip"))
#' }
process_files <- function(input_files) {
  # Create a "safe" version of the bundling function that returns NA on error
  safe_bundle <- purrr::possibly(process_file, otherwise = NA_character_)

  # Use purrr to apply the function sequentially to each file.
  message("Starting sequential bundling process...")
  output_paths <- purrr::map_chr(
    .x = input_files,
    .f = safe_bundle,
    .progress = TRUE # A progress bar is helpful for long jobs
  )

  success_count <- sum(!is.na(output_paths))
  failure_count <- sum(is.na(output_paths))

  message(
    "Bundling complete. Success: ", success_count, ", Failures: ", failure_count, "."
  )

  invisible(output_paths)
}
