-- Command aliases for common shift-key typos
local typos = {
  ['W'] = 'w',
  ['Wq'] = 'wq',
  ['WQ'] = 'wq',
  ['Wqa'] = 'wqa',
  ['WQa'] = 'wqa',
  ['WQA'] = 'wqa',
  ['Wa'] = 'wa',
  ['WA'] = 'wa',
  ['Q'] = 'q',
  ['Qa'] = 'qa',
  ['QA'] = 'qa',
}

for typo, cmd in pairs(typos) do
  vim.api.nvim_create_user_command(typo, cmd, { bang = true })
end

-- Activate Angular treesitter parser for component HTML templates
vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
  desc = 'Set htmlangular filetype for Angular component templates',
  pattern = { '*.component.html', '*.container.html' },
  callback = function()
    vim.bo.filetype = 'htmlangular'
    vim.treesitter.start(nil, 'angular')
  end,
})

-- Override Angular highlights query to fix static_member_expression error.
-- The bundled query references a node type that no longer exists in the
-- installed tree-sitter-angular parser. vim.treesitter.query.set() is used
-- instead of after/queries/ because nvim-treesitter appends rather than
-- replaces query files.
vim.treesitter.query.set(
  'angular',
  'highlights',
  [[
; inherits: html_tags

(identifier) @variable

(pipe_operator) @operator

(string) @string

(number) @number

(pipe_call
  name: (identifier) @function)

(pipe_call
  arguments: (pipe_arguments
    (identifier) @variable.parameter))

(structural_directive
  "*" @keyword
  (identifier) @keyword)

(attribute
  (attribute_name) @variable.member
  (#lua-match? @variable.member "#.*"))

(binding_name
  (identifier) @keyword)

(event_binding
  (binding_name
    (identifier) @keyword))

(event_binding
  "\"" @punctuation.delimiter)

(property_binding
  "\"" @punctuation.delimiter)

(structural_assignment
  operator: (identifier) @keyword)

(member_expression
  property: (identifier) @property)

(call_expression
  function: (identifier) @function)

(call_expression
  function: ((identifier) @function.builtin
    (#eq? @function.builtin "$any")))

(pair
  key: ((identifier) @variable.builtin
    (#eq? @variable.builtin "$implicit")))

[
  (control_keyword)
  (special_keyword)
] @keyword

((control_keyword) @keyword.repeat
  (#any-of? @keyword.repeat "for" "empty"))

((control_keyword) @keyword.conditional
  (#any-of? @keyword.conditional "if" "else" "switch" "case" "default"))

((control_keyword) @keyword.coroutine
  (#any-of? @keyword.coroutine "defer" "placeholder" "loading"))

((control_keyword) @keyword.exception
  (#eq? @keyword.exception "error"))

((identifier) @boolean
  (#any-of? @boolean "true" "false"))

((identifier) @variable.builtin
  (#any-of? @variable.builtin "this" "$event"))

((identifier) @constant.builtin
  (#eq? @constant.builtin "null"))

[
  (ternary_operator)
  (conditional_operator)
] @keyword.conditional.ternary

[
  "("
  ")"
  "["
  "]"
  "{"
  "}"
  "@"
] @punctuation.bracket

(two_way_binding
  [
    "[("
    ")]"
  ] @punctuation.bracket)

[
  "{{"
  "}}"
] @punctuation.special

(template_substitution
  [
    "${"
    "}"
  ] @punctuation.special)

(template_chars) @string

[
  ";"
  "."
  ","
  "?."
] @punctuation.delimiter

(nullish_coalescing_expression
  (coalescing_operator) @operator)

(concatenation_expression
  "+" @operator)

(icu_clause) @keyword.operator

(icu_category) @keyword.conditional

(binary_expression
  [
    "-"
    "&&"
    "+"
    "<"
    "<="
    "="
    "=="
    "==="
    "!="
    "!=="
    ">"
    ">="
    "*"
    "/"
    "||"
    "%"
  ] @operator)
]]
)

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup(
    'kickstart-highlight-yank',
    { clear = true }
  ),
  callback = function()
    vim.hl.on_yank()
  end,
})
