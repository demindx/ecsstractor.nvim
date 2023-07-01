local M = {}

local function get_selection()
  local s_start = vim.fn.getpos("'<")
  local s_end = vim.fn.getpos("'>")
  local n_lines = math.abs(s_end[2] - s_start[2]) + 1
  local lines = vim.api.nvim_buf_get_lines(0, s_start[2] - 1, s_end[2], false)
  lines[1] = string.sub(lines[1], s_start[3], -1)
  if n_lines == 1 then
    lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3] - s_start[3] + 1)
  else
    lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3])
  end
  return table.concat(lines, '\n')
end

local function clean_class(str)
  str = string.gsub(str, 'class="', '', 1)
  str = string.gsub(str, '"', '', 1)
  if string.find(str,' ') ~= nil then
    local t = {}
    for i in string.gmatch(str, "%S+") do
      table.insert(t, i)
    end
    return t
  end
  return str
end

local function parse()
  local selection = get_selection()

  local classes = {}

  local i = 0
  local j = 0

  while true do
    i, j = string.find(selection, 'class="[^"]*"', i+1)

    if i == nil then break end

    local cleaned_class = clean_class(string.sub(selection,i,j))

    if type(cleaned_class) == "string" then
      table.insert(classes, clean_class(string.sub(selection, i, j)))
    else
      for k, a in ipairs(cleaned_class) do
        table.insert(classes,a)
      end
    end
  end

  return classes
end

local function generate_subclass_table(data)
    local result = {}

    for _, value in ipairs(data) do
        if string.find(value, "__") then
            local classes = {}
            for str in string.gmatch(value, "([^__]+)") do
                table.insert(classes, str)
            end

            local block = classes[1]
            local element = classes[2]

            if not result[block] then
                result[block] = {}
            end

            table.insert(result[block], element)
        else
            result[value] = {}
        end
    end

    return result
end

local function generate_bem(result)
    local code = ""

    for block, elements in pairs(result) do
        code = code .. "." .. block .. " {\n"
        for _, element in ipairs(elements) do
            code = code .. "    &" .. "__" .. element .. " {\n"
            code = code .. "        /* Styles for " .. block .. "__" .. element .. " */\n"
            code = code .. "    }\n"
        end
        code = code .. "}\n\n"
    end

    return code
end

local function copyClasses()
  local parsed_data = parse()
  local subclass_table = generate_subclass_table(parsed_data)
  local code = generate_bem(subclass_table)
  vim.fn.setreg('+', code)

  print('The class has been extracted and added to clipboard.')
end

M.ecsstractor = copyClasses

return M