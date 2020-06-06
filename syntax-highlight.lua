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
    local matched = str:sub(s,e)
    print(name,matched,s,e)
    if s > x then
      t[#t+1] = str:sub(x, s)
    end
    x = e + 1
    t[#t+1] = {str = matched, type = name}
    s,e = str:find(pattern, e) 
  end
  t[#t+1] = str:sub(x)
  return t
end

local function apply_pattern(t, name, pat)
  local t = t
  local new =  {}
  for i = 1, #t do
    local curr = t[i]
    local x = {}
    if type(curr) == "string" then
      print("match", curr)
      x =  match_pattern(curr, name, pat)
    elseif type(curr) == "table"  then
      -- print("apply")
      x = apply_pattern(curr, name, pat)
    end
    for _, n in ipairs(x) do
      new[#new+1] = n
    end
  end
  return new
end

local lexer = function(str, patterns)
  local s = {str}
  for _,x in ipairs(patterns) do
    local name, pat = x.name,x.pattern
    s = apply_pattern(s, name, pat)
  end
  return s
end



local patterns = {
  {name = "comment", pattern= "%%.*$"},
  {name = "begin", pattern = "\\begin{[^%}]+}"},
  {name="command", pattern = "\\[a-zA-Z%@]+"},
  {name="math", pattern = "%$[^%$]+%$"},
  -- {name="rest", pattern = ".*"}
}

local lines = {}
for line in getlines(sample) do
  lines[#lines+1] = lexer(line, patterns)
end

-- for i, line in ipairs(lines) do
--   print(i, line)
-- end
print_r(lines)
