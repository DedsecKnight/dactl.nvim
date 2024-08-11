---@param bufnr integer
---@return TSTree
local function get_parser_tree(bufnr)
  local parser = vim.treesitter.get_parser(bufnr, 'cpp')
  local tree = parser:parse()[1]
  return tree
end

---@return vim.treesitter.Query
local function get_include_matches()
  return vim.treesitter.query.parse('cpp', '(preproc_include path: (string_literal) @dependency)')
end

---@return vim.treesitter.Query
local function get_non_snippet_matches()
  return vim.treesitter.query.parse(
    'cpp',
    '(preproc_call directive: (preproc_directive) @cc (#contains? @cc "pragma")) ((comment) @cc (#contains? @cc "Author"))  (preproc_include path: (string_literal) @cc)'
  )
end

return {
  get_parser_tree = get_parser_tree,
  get_include_matches = get_include_matches,
  get_non_snippet_matches = get_non_snippet_matches,
}
