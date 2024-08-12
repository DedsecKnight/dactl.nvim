---@class DactlParser
---@field tree TSTree
---@field file_bufnr integer
local parser = {}

---@param bufnr integer
---@return DactlParser
function parser:new(bufnr)
  local new_parser = {
    file_bufnr = bufnr,
    tree = (vim.treesitter.get_parser(bufnr, 'cpp')):parse()[1],
  }
  setmetatable(new_parser, self)
  self.__index = self
  return new_parser
end

---@return vim.treesitter.Query
local function get_include_matches_query()
  return vim.treesitter.query.parse('cpp', '(preproc_include path: (string_literal) @dependency)')
end

---@return vim.treesitter.Query
local function get_non_snippet_matches_query()
  return vim.treesitter.query.parse(
    'cpp',
    '(preproc_call directive: (preproc_directive) @cc (#contains? @cc "pragma")) ((comment) @cc (#contains? @cc "Author"))  (preproc_include path: (string_literal) @cc)'
  )
end

---@return string[]
function parser:extract_include_statements()
  local include_query = get_include_matches_query()
  local include_statements = {}

  for _, n in include_query:iter_captures(self.tree:root(), self.file_bufnr) do
    local text = vim.treesitter.get_node_text(n, self.file_bufnr)
    include_statements[#include_statements + 1] = text
  end

  return include_statements
end

---@return string[]
function parser:extract_snippet_content()
  local file_content = vim.api.nvim_buf_get_lines(self.file_bufnr, 0, -1, false)
  local cleanup_query = get_non_snippet_matches_query()
  local delta = 0
  for _, n in cleanup_query:iter_captures(self.tree:root(), self.file_bufnr) do
    local r = vim.treesitter.get_range(n, self.file_bufnr)
    for _ = r[1] + 1 - delta, r[4] + 1 - delta, 1 do
      table.remove(file_content, r[1] + 1 - delta)
    end
    delta = delta + r[4] - r[1] + 1
  end
  return file_content
end

return parser
