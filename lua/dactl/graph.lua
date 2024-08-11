---@class Graph
---@field adj {[string]: string[]}
---@field content {[string]: string[]}
local graph = {}
local buffer_utils = require('dactl.buffer')
local parser_utils = require('dactl.parser')
local utils = require('dactl.utils')

---@param g Graph
---@param filename string
local function dfs_helper(g, filename)
  g.adj[filename] = {}
  local path = utils.path_string_to_list(filename)

  local file_content = utils.read_file(filename)
  local file_bufnr = buffer_utils.create_new_buffer(file_content)

  local tree = parser_utils.get_parser_tree(file_bufnr)
  local include_query = parser_utils.get_include_matches()

  for _, n in include_query:iter_captures(tree:root(), file_bufnr) do
    local text = vim.treesitter.get_node_text(n, file_bufnr)
    local temp_path = utils.array_merge(
      utils.table_copy(path),
      utils.split_string(utils.trim_include_statement(text), '/')
    )
    local actual_path = utils.clean_path(temp_path)
    local next_filename = '/' .. utils.join_string(actual_path, '/')
    g.adj[filename][#g.adj[filename] + 1] = next_filename
    if g.adj[next_filename] == nil then
      dfs_helper(g, next_filename)
    end
  end

  local delta = 0
  local cleanup_query = parser_utils.get_non_snippet_matches()
  for _, n in cleanup_query:iter_captures(tree:root(), file_bufnr) do
    local r = vim.treesitter.get_range(n, file_bufnr)
    for _ = r[1] + 1 - delta, r[4] + 1 - delta, 1 do
      table.remove(file_content, r[1] + 1 - delta)
    end
    delta = delta + r[4] - r[1] + 1
  end

  g.content[filename] = file_content

  buffer_utils.close_buffer(file_bufnr)
end

---@param filename string
---@return Graph
graph.build = function(filename)
  local g = {
    adj = {},
    content = {},
  }
  dfs_helper(g, filename)
  return g
end

---@param self Graph
---@return {[string]: string[]}
graph.reverse_edges = function(self)
  local rg = {}
  for node, neighbor_set in pairs(self.adj) do
    for _, neighbor in ipairs(neighbor_set) do
      if rg[neighbor] == nil then
        rg[neighbor] = {}
      end
      rg[neighbor][#rg[neighbor] + 1] = node
    end
  end
  for node, _ in pairs(self.adj) do
    if rg[node] == nil then
      rg[node] = {}
    end
  end
  return rg
end

---@param self Graph
---@return string[]
graph.get_topological_order = function(self)
  local rg = graph.reverse_edges(self)
  local indegree = {}
  for node, neighbor_set in pairs(rg) do
    if indegree[node] == nil then
      indegree[node] = 0
    end
    for _, neighbor in ipairs(neighbor_set) do
      if indegree[neighbor] == nil then
        indegree[neighbor] = 0
      end
      indegree[neighbor] = indegree[neighbor] + 1
    end
  end
  local queue = {}
  for k, v in pairs(indegree) do
    if v == 0 then
      queue[#queue + 1] = k
    end
  end
  local topological_order = {}
  while #queue > 0 do
    local curr_node = queue[1]
    table.remove(queue, 1)
    topological_order[#topological_order + 1] = curr_node
    for _, neighbor in pairs(rg[curr_node]) do
      indegree[neighbor] = indegree[neighbor] - 1
      if indegree[neighbor] == 0 then
        queue[#queue + 1] = neighbor
      end
    end
  end
  return topological_order
end

---@param self Graph
---@return string[]
graph.generate_aggregated_buffer = function(self)
  local aggregated_buffer = {}
  local topological_order = graph.get_topological_order(self)
  for _, filename in ipairs(topological_order) do
    aggregated_buffer = utils.array_merge(aggregated_buffer, self.content[filename])
  end
  return aggregated_buffer
end

return graph
