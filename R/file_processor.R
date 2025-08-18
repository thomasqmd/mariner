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

# process("Reports")
#
# for(i in 1:4){
#   process(paste0("Report-1_", i))
# }

process_files <- \(files, type = ".Rmd") {
  # files must all be of the same type

  for (f in files) {
    process_file(f, type)
  }
}


# ch1_lis <- c("Report-1_3")
# process_files(ch1_lis)

# ch1_lis2 <- c(
#   "Report-1_6", "Report-1_7", "Report-1_8", "Report-1_9", "Report-1_10",
#   "Report-1_11", "Report-1_12"
# )
# process_files(ch1_lis2)
# process_file("Report-1_7")
#
# reports for ch 2: 4, 5, 7, 11, 13, 15
# ch2_lis <- c("Report-2_4", "Report-2_5", "Report-2_7", "Report-2_11", "Report-2_13", "Report-2_15")
# process_files(ch2_lis)
#
# reports for ch3: 1, 3, 4
# ch3_lis <- c("Report-3_1", "Report-3_3", "Report-3_4")
# process_files(ch3_lis)
#
# reports for ch3: 6, 7, 9, 11, 12
# reports for ch4: 3, 4, 5, 7
ch34_lis <- c(
  "Report-3_6", "Report-3_7", "Report-3_9", "Report-3_11", "Report-3_12",
  "Report-4_3", "Report-4_4", "Report-4_5", "Report-4_7"
)
# process_files(ch34_lis)
# reports for ch6: 2, 3
ch6_lis <- c("Report-6_2", "Report-6_3")
# process_files(ch6_lis)
