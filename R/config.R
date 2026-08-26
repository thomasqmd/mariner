# Project-level settings: the values a student sets once per project rather
# than once per call.
#
# WHY A DEDICATED FILE, AND NOT A `mariner:` KEY IN `_quarto.yml`.
#
# A `_quarto.yml` written into a directory that had none turns that directory
# into a Quarto PROJECT, and Quarto then walks up to it from every document
# beneath it. That walk is the mechanism §0.4 of the refactor measured: it
# breaks a render. `brand-preamble.tex` reaches the fonts through
# `Path=_extensions/mariner/fonts/`, xelatex resolves that against the
# directory that holds the `.tex`, and a project root moves what Quarto takes
# that directory to be. The failure is `The font "Lora-Regular" cannot be
# found`, and it appears only once a project file exists.
#
# `_mariner.yml` cannot reach Quarto at all. It is also visible in the RStudio
# files pane, where a dotfile is not -- and this is a file a student is meant
# to open and edit.
#
# The keys are FLAT. A `mariner:` wrapper inside a file already named
# `_mariner.yml` is a level of nesting whose only content is the filename
# repeated.
MARINER_CONFIG_FILE <- "_mariner.yml"

# Where the settings file for `root` lives. `NULL` resolves the root.
mariner_config_path <- function(root = NULL) {
  if (is.null(root)) root <- mariner_project_root()
  file.path(root, MARINER_CONFIG_FILE)
}

# The project settings as a named list, or an empty list when there are none.
#
# Absent is not an error: a project from before this file existed, or one whose
# owner never set an author, is an ordinary project. Unparseable IS worth
# saying out loud -- the settings would otherwise go missing while the reports
# still render, which is the degradation-without-failure case the risk table
# names.
read_project_config <- function(root = NULL) {
  path <- mariner_config_path(root)
  if (!file.exists(path)) return(list())

  cfg <- tryCatch(
    yaml::yaml.load_file(path),
    error = function(e) {
      cli::cli_warn(c(
        "Could not read {.file {path}}: {conditionMessage(e)}",
        i = "Project settings were ignored. Template defaults apply."
      ))
      NULL
    }
  )

  # An empty file loads as NULL, and a file whose content is a bare scalar
  # loads as a length-one vector. Neither is a settings list.
  if (!is.list(cfg)) return(list())
  cfg
}

# Merge `values` into the project settings and write them back.
#
# Read-modify-write rather than append, so a second call replaces the entry
# instead of leaving a file with two `author:` keys. YAML takes the last of
# those, so an append-based writer looks correct to the reader and is wrong on
# disk.
#
# Comments in an existing file do not survive this. That is the cost of a round
# trip through the YAML parser, and it is accepted here: the file is one line
# of content, and the header below is regenerated each time.
write_project_config <- function(root, values) {
  path <- mariner_config_path(root)
  existing <- read_project_config(root)
  merged <- utils::modifyList(existing, values)

  writeLines(
    c(
      "# mariner project settings. Edit by hand or with mariner_setup_project().",
      "#",
      "# Values here fill any parameter of the same name that a template",
      "# declares. A column in generate_reports()'s params_df beats them.",
      sub("\n$", "", yaml::as.yaml(merged))
    ),
    path
  )

  invisible(path)
}
