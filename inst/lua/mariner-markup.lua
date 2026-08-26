-- Span and div classes -> the LaTeX commands and environments that
-- brand-preamble.tex defines.
--
-- This filter is not a convenience layer. Pandoc's LaTeX writer silently drops
-- classes it does not recognise, so without the mapping below every markup
-- class mariner documents is inert. Measured against the pandoc 3.10 that
-- Quarto ships:
--
--   [formal sum]{.defn}   ->  {formal sum}     braces, no command
--   ::: {.def} ... :::    ->  ...              no environment at all
--
-- Neither case is an error, which is what makes it worth a comment: a document
-- using the classes renders clean and comes out looking like it forgot them.
--
-- The commands live in brand-preamble.tex rather than here because they are
-- coloured from _brand.yml, and a hex is typed in exactly one place.

if not (FORMAT:match("latex") or FORMAT:match("beamer")) then
  return {}
end

-- span class -> one-argument command
local span_command = {
  defn    = "defn",
  term    = "term",
  termref = "termref",
  emph    = "marineremph",
  -- Font switches, for a typography specimen: setting a sample of the heading
  -- face inside a document whose body is the other one.
  ["font-headings"] = "fontheadings",
  ["font-body"]     = "fontbody",
}

-- div class -> environment
local block_environment = {
  thm = "marinerthm",
  def = "marinerdef",
}

local function raw_inline(s)
  return pandoc.RawInline("latex", s)
end

local function wrap_inlines(open, content, close)
  local out = pandoc.List({ raw_inline(open) })
  out:extend(content)
  out:insert(raw_inline(close))
  return out
end

function Span(el)
  for _, class in ipairs(el.classes) do
    local cmd = span_command[class]
    if cmd then
      -- A .defn carrying an identifier drives the cross-reference pair instead:
      -- \linkeddefn plants the back-reference target and links forward to the
      -- \defanchor of the same name. Without an identifier there is nothing to
      -- link to, so the plain command is the right one.
      if cmd == "defn" and el.identifier ~= "" then
        return wrap_inlines(
          "\\linkeddefn{" .. el.identifier .. "}{", el.content, "}"
        )
      end
      return wrap_inlines("\\" .. cmd .. "{", el.content, "}")
    end
  end
end

function Div(el)
  for _, class in ipairs(el.classes) do
    local env = block_environment[class]
    if env then
      local out = pandoc.List({
        pandoc.RawBlock("latex", "\\begin{" .. env .. "}")
      })
      out:extend(el.content)
      out:insert(pandoc.RawBlock("latex", "\\end{" .. env .. "}"))
      return out
    end
  end
end
