---@class Graph
---@field adj {[string]: string[]}
---@field content {[string]: string[]}
local graph = {}
local buffer_utils = require('dactl.buffer')
local parser_utils = require('dactl.parser')
local utils = require('dactl.utils')

--- DFS Helper function for recursively building dependency graph
--- and extract file content of each file in dependency graph
---@param g Graph
---@param filename string
---@private
local function dfs_helper(g, filename)
  g.adj[filename] = {}
  local path = utils.path_string_to_list(filename)

  local file_content = utils.read_file(filename)
  local file_bufnr = buffer_utils.create_new_buffer(file_content)
  local snippet_parser = parser_utils:new(file_bufnr)

  local include_statements = snippet_parser:extract_include_statements()
  for _, statement in ipairs(include_statements) do
    local temp_path = utils.array_merge(
      utils.table_copy(path),
      utils.split_string(utils.trim_include_statement(statement), '/')
    )
    local actual_path = utils.clean_path(temp_path)
    local next_filename = '/' .. utils.join_string(actual_path, '/')
    g.adj[filename][#g.adj[filename] + 1] = next_filename
    if g.adj[next_filename] == nil then
      dfs_helper(g, next_filename)
    end
  end

  g.content[filename] = snippet_parser:extract_snippet_content()

  buffer_utils.close_buffer(file_bufnr)
end

---Construct a new dependency graph starting from provided file
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

---Construct a new adjacency list from input graph but with all edges reversed in terms of direction.
---@param self Graph
---@return {[string]: string[]}
---@private
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

---Construct topological order of each dependency using topological sort.
---@param self Graph
---@return string[]
---@private
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

---Aggregate content of all files in dependency graph to construct 1 single "buffer".
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
