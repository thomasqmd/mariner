#' Zip Rmarkdown file
#'
#' @param file filepath
#' @param type string for filetype
#'
#' @returns Nothing
#' @export
#'
#' @examples
#' process_file(file = "Report-1_1", type = ".Rmd")
process_file <- \(file, type = ".Rmd") {
  # library(knitr)
  # library(rmarkdown)

  # file_name <- rstudioapi::getSourceEditorContext()$path |>
  #   basename()

  # .Rmd -> .R
  knitr::purl(paste0(file, type))
  # .Rmd -> .pdf & .tex
  rmarkdown::render(paste0(file, type))

  zip(
    zipfile = file,
    files = c(
      paste0(file, "_files"),
      paste0(file, ".R"),
      paste0(file, ".tex"),
      paste0(file, ".pdf")
    )
  )
}
