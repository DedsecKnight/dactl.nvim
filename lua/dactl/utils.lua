---Extract file path from include statement
---@param include_statement string
local function trim_include_statement(include_statement)
  return string.sub(include_statement, 2, -2)
end

---Split string into array of substrings at delimiter
---@param s string
---@param delimiter string
---@return string[]
local function split_string(s, delimiter)
  local t = {}
  for str in string.gmatch(s, '([^' .. delimiter .. ']+)') do
    table.insert(t, str)
  end
  return t
end

---Merge t2 into t1
---@param t1 any[]
---@param t2 any[]
local function array_merge(t1, t2)
  for i = 1, #t2 do
    t1[#t1 + 1] = t2[i]
  end
  return t1
end

---Make a copy of a table
---@param t table
---@return table
local function table_copy(t)
  local t2 = {}
  for k, v in pairs(t) do
    t2[k] = v
  end
  return t2
end

---Join string together with delimiter
---@param l string[]
---@param delimiter string
---@return string
local function join_string(l, delimiter)
  local ret = ''
  for _, elem in ipairs(l) do
    ret = ret .. elem .. delimiter
  end
  return string.sub(ret, 0, -2)
end

---Remove ".." from path
---@param raw_path string[]
---@return string[]
local function clean_path(raw_path)
  local actual_path = {}
  for _, segment in ipairs(raw_path) do
    if segment == '..' then
      table.remove(actual_path, nil)
    else
      actual_path[#actual_path + 1] = segment
    end
  end
  return actual_path
end

---Convert path string to list of directories/files
---@param path_string string
---@return string[]
local function path_string_to_list(path_string)
  local path = split_string(path_string, '/')
  table.remove(path, nil)
  return path
end

---Read file content and return as list of lines
---@param filename string
---@return string[]
local function read_file(filename)
  local lines = {}
  local file = io.open(filename, 'rb')
  if not file then
    return lines
  end
  for line in io.lines(filename) do
    lines[#lines + 1] = line
  end
  file:close()
  return lines
end

return {
  trim_include_statement = trim_include_statement,
  split_string = split_string,
  array_merge = array_merge,
  table_copy = table_copy,
  join_string = join_string,
  clean_path = clean_path,
  path_string_to_list = path_string_to_list,
  read_file = read_file,
}
