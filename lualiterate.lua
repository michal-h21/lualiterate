local m = {}

local DocClass = {}
local current_chunk = {}
DocClass.__index = DocClass
local init = function() 
  local self =  setmetatable({},DocClass) 
  self.current_chunk = {}
  return self
end

DocClass.chunks = {}

DocClass.iter = function(self)
  local i = 0
  return function()
    i = i + 1
    return self.chunks[i]
  end
end

---
-- I need to figure out what this does
DocClass.testStatus = function(self,status)
  current_chunk.status = status
  table.insert(self.chunks, current_chunk)
  current_chunk = {}
end


---
--  Print chunks in the document
--  it is quite primitive at the moment
--  chunks should be passed to a formatting function, there is no need to be
--  hardwired here
DocClass.listSources = function(self)
  local print_chunk = function(ch)
    tex.print(table.concat(ch),"\n")
    print(table.concat(ch),"\n")
  end
  local print_code = function(ch)
    tex.print("\n\n\\noindent")
    for _, line in ipairs(ch) do
      tex.print("\\verb|" .. line .."|\\\\")
      print("\\noindent\\verb|" .. line .."|\\\\")
    end
  end
  for ch in self:iter() do
    if ch.status == "code" then
      print_code(ch)
    else
      print_chunk(ch)
    end
  end
end

DocClass.addLine = function(self, line)
  local line_status = line:match("^%s*%%") and "doc" or "code"
  if line_status == "doc" then line = line:gsub("^%s*%%","") end
  -- print(line_status, line)
  if status ~= "init" and status ~= line_status then
    self:testStatus(status)
  end
  status = line_status
  table.insert(current_chunk, line)
end

function m.load_file(filename)
  local status = "init"
  local x = init()
  for line in io.lines(filename) do
    x:addLine(line)
  end
  x:testStatus(status)
  return x
end

return m
