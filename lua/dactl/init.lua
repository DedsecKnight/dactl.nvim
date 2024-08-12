local buffer_utils = require('dactl.buffer')
local graph_utils = require('dactl.graph')
local default_config = {
  snippet_file_extensions = { 'cpp', 'h' },
}

---@class DactlImporterConfigType
---@field trd_path string
---@field snippet_file_extensions? string[]

---@class DactlImporter
---@field config DactlImporterConfigType
---@field setup (fun(opts: DactlImporterConfigType))
---@field build_snippet (fun(filename: string): string[])
local M = {}

M.plenary_scan = require('plenary.scandir')
M.notify = require('notify')

M.setup = function(opts)
  opts = opts or {}
  if opts.trd_path == nil then
    error('<trd_path> parameter is required for this plugin to run properly')
  end
  M.config = vim.tbl_deep_extend('force', default_config, opts)
  M.files = M.plenary_scan.scan_dir(M.config.trd_path, {
    ---@param e string
    ---@return boolean
    search_pattern = function(e)
      for _, extension in ipairs(M.config.snippet_file_extensions) do
        if string.sub(e, -1 - #extension, -1) == ('.' .. extension) then
          return true
        end
      end
      return false
    end,
  })
end

---@param filename string
---@return string[]
M.build_snippet = function(filename)
  local dep_graph = graph_utils:new(filename)

  local aggregated_buffer = dep_graph:generate_aggregated_buffer()
  return aggregated_buffer
end

M.inject_snippet = function()
  vim.ui.select(M.files, {
    format_item = function(item)
      return string.sub(item, 58)
    end,
  }, function(filename)
    if filename ~= nil then
      local snippet = M.build_snippet(filename)
      local cursor_row_index = buffer_utils.get_win_cursor_row_position()
      buffer_utils.inject_snippet_at_row(snippet, cursor_row_index)
      M.notify('DACTL: Snippet injection completed')
    else
      M.notify('DACTL: No file chosen')
    end
  end)
end

return M
