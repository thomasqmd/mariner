process_files <- \(files, type = ".Rmd") {
  # files must all be of the same type

  for (f in files) {
    process_file(f, type)
  }
}
