#' Bundle Multiple R Markdown Files in Parallel or Sequentially
#'
#' @description
#' A wrapper around `process_file()` to process a list of R Markdown
#' files. Execution is sequential by default but can be run in parallel by
#' setting a `future` plan (e.g., `future::plan(future::multisession)`).
#'
#' @param input_files A character vector of paths to the `.Rmd` files.
#'
#' @return Invisibly returns a character vector of paths to the successfully
#'   created zip archives. Any file that fails to process will be represented
#'   by an `NA` in the output vector.
#' @export
#' @importFrom purrr possibly
#' @importFrom furrr future_map_chr
#' @importFrom future plan multisession
#'
#' @examples
#' \dontrun{
#' # 1. Create dummy Rmd files
#' writeLines("---\ntitle: A\n---", "reportA.Rmd")
#' writeLines("---\ntitle: B\n---", "reportB.Rmd")
#' files_to_bundle <- c("reportA.Rmd", "reportB.Rmd")
#'
#' # 2. Process sequentially (default)
#' process_files(files_to_bundle)
#'
#' # 3. Process in parallel
#' future::plan(future::multisession)
#' process_files(files_to_bundle)
#'
#' # 4. Clean up
#' unlink(c("reportA.Rmd", "reportB.Rmd", "reportA.zip", "reportB.zip"))
#' }
process_files <- function(input_files) {
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
