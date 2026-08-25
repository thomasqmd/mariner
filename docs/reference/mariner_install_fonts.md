# Install the bundled fonts for this user

Copies the theme's font files into the current user's font directory, so
that Atkinson Hyperlegible, Lora and JetBrains Mono are available to
every program on the machine – including the graphics devices that draw
figures for PDF output.

## Usage

``` r
mariner_install_fonts(overwrite = FALSE, quiet = FALSE)
```

## Arguments

- overwrite:

  Replace font files that are already installed. Defaults to `FALSE`, so
  re-running is cheap and safe.

- quiet:

  Suppress the summary.

## Value

Invisibly, a character vector of the files installed (those actually
copied; already-present files are not listed unless `overwrite = TRUE`).

## Why you may want this

mariner bundles its fonts and registers them with R at load time, which
is enough for all PDF *body text*, which xelatex reads from the bundled
files by path. It is not enough for PDF *figures*: those are drawn by
[`cairo_pdf()`](https://rdrr.io/r/grDevices/cairo.html), which reads the
system font configuration and cannot see a font that is merely bundled.
Until the faces are installed, figures in a PDF report fall back to the
device's default typeface while the surrounding text does not.

Check with
[`mariner_check_setup()`](https://thomasqmd.github.io/mariner/reference/mariner_check_setup.md)
(or `mariner_fonts_available("pdf")`) whether this applies to your
machine.

## Platform notes

Nothing here needs administrator rights – the fonts go into your own
user font directory, not the system one.

- **macOS** copies to `~/Library/Fonts`; available immediately.

- **Linux** copies to `~/.local/share/fonts` and runs `fc-cache` if
  present.

- **Windows** copies to `%LOCALAPPDATA%\\Microsoft\\Windows\\Fonts` and
  registers each face under `HKEY_CURRENT_USER`. Copying alone is not
  enough on Windows – an unregistered file in that directory is ignored
  – so if the registry step fails, the function says so rather than
  reporting success.

**Restart R afterwards.** Graphics devices read the font configuration
once per session, so a face installed mid-session is not picked up until
R is restarted.

## Examples

``` r
if (FALSE) { # \dontrun{
mariner_install_fonts()
# then restart R
} # }
```
