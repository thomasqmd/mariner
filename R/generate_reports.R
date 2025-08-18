# Load necessary libraries
library(knitr)
library(rmarkdown)

# Define report_numbers of a and b
# report_numbers <- expand.grid(a = 6, b = c(2, 3))

# Function to replace a and b in the template
replace_values <- function(template, a, b) {
  content <- readLines(template)

  # Replace the title in the YAML header
  for (i in seq_along(content)) {
    if (grepl("title: \"Report-a.b\"", content[i])) {
      content[i] <- gsub("a.b", paste0(a, ".", b), content[i])
      break
    }
  }

  # Replace the first header in the document body
  for (i in seq_along(content)) {
    if (grepl("^# a.b$", content[i])) {
      content[i] <- gsub("a.b", paste0(a, ".", b), content[i])
      break
    }
  }

  return(paste(content, collapse = "\n"))
}

# Loop through report_numbers and generate/render reports
# for (i in seq_along(report_numbers$a)) {
#   a <- report_numbers$a[i]
#   b <- report_numbers$b[i]
#
#   # Create new Rmd file name
#   rmd_file <- paste0("Report-", a, "_", b, ".Rmd")
#
#   # Replace values in template and write to new Rmd file
#   new_content <- replace_values("template.Rmd", a, b)
#   writeLines(new_content, con = rmd_file)
# }
