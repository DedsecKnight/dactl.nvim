local function get_win_cursor_row_position()
  local res = vim.fn.getcurpos(0)
  return res[2]
end

---@param snippet string[]
---@param row_index integer
local function inject_snippet_at_row(snippet, row_index)
  vim.api.nvim_buf_set_lines(0, row_index - 1, row_index, false, snippet)
end

---@param filename string
---@return integer
local function create_new_buffer(filename)
  local bufnr = vim.fn.bufnr(filename)
  if bufnr == -1 then
    bufnr = vim.fn.bufadd(filename)
  end
  if not vim.api.nvim_buf_is_loaded(bufnr) then
    vim.fn.bufload(bufnr)
    vim.api.nvim_set_option_value('buflisted', true, { buf = bufnr })
  end
  return bufnr
end

---@param bufnr integer
local function close_buffer(bufnr)
  vim.api.nvim_buf_delete(bufnr, { force = true })
end

return {
  get_win_cursor_row_position = get_win_cursor_row_position,
  inject_snippet_at_row = inject_snippet_at_row,
  create_new_buffer = create_new_buffer,
  close_buffer = close_buffer,
}
