local scan = require('plenary.scandir')
local trd_path = os.getenv('HOME') .. '/competitive_programming/dactl/content'
local notify = require('notify')

---@param filename string
---@return string[]
function SplitPath(filename)
  local t = {}
  for str in string.gmatch(filename, '([^' .. '/' .. ']+)') do
    table.insert(t, str)
  end
  return t
end

---@param t1 any[]
---@param t2 any[]
---@return any[]
function TableConcat(t1, t2)
  for i = 1, #t2 do
    t1[#t1 + 1] = t2[i]
  end
  return t1
end

---@param t table
---@return table
function TableCopy(t)
  local t2 = {}
  for k, v in pairs(t) do
    t2[k] = v
  end
  return t2
end

---@param l string[]
---@return string
function ConcatPath(l)
  local ret = '/'
  for _, elem in ipairs(l) do
    ret = ret .. elem .. '/'
  end
  return string.sub(ret, 0, -2)
end

---@param l string[]
---@return string
function ConcatBuffer(l)
  local ret = ''
  for _, elem in ipairs(l) do
    ret = ret .. elem .. '\n'
  end
  return string.sub(ret, 0, -2)
end

---@param dependency_graph {[string]: string[]}
---@return string[]
function TopologicalSort(dependency_graph)
  local reverse_graph = {}
  for node, neighbor_set in pairs(dependency_graph) do
    for _, neighbor in ipairs(neighbor_set) do
      if reverse_graph[neighbor] == nil then
        reverse_graph[neighbor] = {}
      end
      reverse_graph[neighbor][#reverse_graph[neighbor] + 1] = node
    end
  end
  for node, _ in pairs(dependency_graph) do
    if reverse_graph[node] == nil then
      reverse_graph[node] = {}
    end
  end
  local indegree = {}
  for node, neighbor_list in pairs(reverse_graph) do
    if indegree[node] == nil then
      indegree[node] = 0
    end
    for _, neighbor in ipairs(neighbor_list) do
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
    for _, neighbor in pairs(reverse_graph[curr_node]) do
      indegree[neighbor] = indegree[neighbor] - 1
      if indegree[neighbor] == 0 then
        queue[#queue + 1] = neighbor
      end
    end
  end
  return topological_order
end

---@param filename string
---@param dependency_graph {[string]: string[]}
---@param file_buffer {[string]: string[]}
function OpenFile(filename, dependency_graph, file_buffer)
  dependency_graph[filename] = {}
  local path = SplitPath(filename)
  table.remove(path, nil)
  local bufnr = vim.fn.bufnr(filename)
  if bufnr == -1 then
    bufnr = vim.fn.bufadd(filename)
  end
  if not vim.api.nvim_buf_is_loaded(bufnr) then
    vim.fn.bufload(bufnr)
    vim.api.nvim_set_option_value('buflisted', true, { buf = bufnr })
  end
  local parser = vim.treesitter.get_parser(bufnr, 'cpp')
  local find_dep_query = vim.treesitter.query.parse('cpp', '((preproc_include)) @dependency')
  local tree = parser:parse()[1]
  for _, n in find_dep_query:iter_captures(tree:root(), bufnr) do
    local text = vim.treesitter.get_node_text(n, bufnr)
    local temp_path = TableConcat(TableCopy(path), SplitPath(string.sub(text, 11, -2)))
    local actual_path = {}
    for _, segment in ipairs(temp_path) do
      if segment == '..' then
        table.remove(actual_path, nil)
      else
        actual_path[#actual_path + 1] = segment
      end
    end
    local next_filename = ConcatPath(actual_path)
    dependency_graph[filename][#dependency_graph[filename] + 1] = next_filename
    if dependency_graph[next_filename] == nil then
      OpenFile(next_filename, dependency_graph, file_buffer)
    end
  end

  local cleanup_query = vim.treesitter.query.parse(
    'cpp',
    '(preproc_call directive: (preproc_directive) @cc (#contains? @cc "pragma")) ((comment) @cc (#match? @cc "^/(*).*$") ) ((preproc_include) @cc)'
  )
  local file = io.open(filename, 'rb')
  if not file then
    error('something is wrong')
  end
  local lines = {}
  for line in io.lines(filename) do
    lines[#lines + 1] = line
  end
  local delta = 0
  for _, n in cleanup_query:iter_captures(tree:root(), bufnr) do
    local r = vim.treesitter.get_range(n, bufnr)
    for i = r[1] + 1 - delta, r[4] + 1 - delta, 1 do
      table.remove(lines, r[1] + 1 - delta)
    end
    delta = delta + r[4] - r[1] + 1
  end
  file_buffer[filename] = lines
  file:close()
  vim.api.nvim_buf_delete(bufnr, {
    force = true,
  })
end

function Test()
  local files = scan.scan_dir(trd_path)
  vim.ui.select(files, {
    format_item = function(item)
      return string.sub(item, 58)
    end,
  }, function(choice)
    if choice ~= nil then
      local dependency_graph = {}
      local file_buffer = {}
      OpenFile(choice, dependency_graph, file_buffer)
      local topological_order = TopologicalSort(dependency_graph)
      local aggregated_buffer = {}
      for _, filename in ipairs(topological_order) do
        aggregated_buffer = TableConcat(aggregated_buffer, file_buffer[filename])
      end
      local pos_param = vim.fn.getcurpos(0)
      vim.api.nvim_buf_set_lines(0, pos_param[2] - 1, pos_param[2], false, aggregated_buffer)
      notify('Snippet injection completed')
    end
  end)
end

vim.api.nvim_create_user_command('ChooseOption', Test, {})
