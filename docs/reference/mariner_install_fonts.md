# Install the bundled fonts for this user

Copies the theme's font files into your user font directory. Atkinson
Hyperlegible, Lora and JetBrains Mono then reach every program on the
machine, the graphics devices that draw PDF figures included.

## Usage

``` r
mariner_install_fonts(overwrite = FALSE, quiet = FALSE)
```

## Arguments

- overwrite:

  Replace font files that are already installed.

- quiet:

  Suppress the summary.

## Value

Invisibly, the files copied. A file already in place is listed only
under `overwrite = TRUE`.

## Why you may want this

mariner bundles its fonts and registers them with R at load time. That
covers PDF *body text*, which xelatex reads from the bundled files by
path. It does not cover PDF *figures*:
[`cairo_pdf()`](https://rdrr.io/r/grDevices/cairo.html) draws those, and
it reads the system font configuration, where a bundled font does not
appear. Until you install the faces, the figures in a report fall back
to the device's default typeface and the text around them does not.

[`mariner_check_setup()`](https://thomasqmd.github.io/mariner/reference/mariner_check_setup.md)
says whether this applies to your machine.

## Platform notes

None of this needs administrator rights. The fonts go into your own font
directory, not the system one.

- **macOS** copies to `~/Library/Fonts`. Available at once.

- **Linux** copies to `~/.local/share/fonts` and runs `fc-cache` if it
  exists.

- **Windows** copies to `%LOCALAPPDATA%\\Microsoft\\Windows\\Fonts` and
  registers each face under `HKEY_CURRENT_USER`. Windows ignores a font
  file the registry does not name, so a failed registry write is
  reported as a failure.

**Restart R afterwards.** A graphics device reads the font configuration
once per session.

## Examples

``` r
if (FALSE) { # \dontrun{
mariner_install_fonts()
# then restart R
} # }
```
