local sample = [[

\section{hello world}

math $a sdks asd$ % comment

% full line comment \textit{and this?}

\begin{cosi}

ahooj
\end{cosi}
\prikaz\dalsi
]]

local print_r = require "print_r"

local getlines = function(str)
  local str = str
  return str:gmatch("([^\n]+)")
end

local match_pattern = function(str, name, pattern)
  local t = {}
  -- print(str, name, pattern)
  local s,e = str:find(pattern, e) 
  local x = 1
  while s do
    -- print(name,s,e)
    t[#t+1] = str:sub(x, s)
    t[#t+1] = {str = str:sub(s,e), type = name}
    s,e = str:find(pattern, e) 
    x = e
  end
  x = x or 1
  t[#t+1] = str:sub(x)
  return t
end

local function apply_pattern(t, name, pat)
  local t = t
  local new =  {}
  for i = 1, #t do
    local curr = t[i]
    if type(curr) == "string" then
      new[i] = match_pattern(curr, name, pat)
    else
      new[i] = apply_pattern(curr, name, pat)
    end
  end
  return new
end

local lexer = function(str, patterns)
  local s = {str}
  for name,pat in pairs(patterns) do
    s = apply_pattern(s, name, pat)
  end
  return s
end



local patterns = {
  comment = "%%.*$",
  command = "\\[a-zA-Z%@]+",
  math = "$.-$"
}

local lines = {}
for line in getlines(sample) do
  lines[#lines+1] = lexer(line, patterns)
end

-- for i, line in ipairs(lines) do
--   print(i, line)
-- end
print_r(lines)
