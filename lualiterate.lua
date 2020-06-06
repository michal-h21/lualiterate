local m = {}

local DocClass = {}
DocClass.__index = DocClass
local init = function() 
  local self =  setmetatable({},DocClass) 
  self.current_chunk = {}
  self.status = "init"
  self.chunks = {}
  return self
end


DocClass.iter = function(self)
  local i = 0
  return function()
    i = i + 1
    return self.chunks[i]
  end
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

---
-- I need to figure out what this does
DocClass.testStatus = function(self,status)
  local status = status or self.status
  local current_chunk = self.current_chunk 
  current_chunk.status = status
  table.insert(self.chunks, current_chunk)
  self.current_chunk = {}
end

DocClass.addLine = function(self, line)
  local current_chunk = self.current_chunk
  local status = self.status
  -- remove Unicode BOM
  if status == "init" then 
    print("init", line)
  end
  local line_status = line:match("^%s*%%") and "doc" or "code"
  if line_status == "doc" then line = line:gsub("^%s*%%","") end
  if status ~= "init" and status ~= line_status then
    self:testStatus(status)
  end
  self.status = line_status
  table.insert(current_chunk, line)
end

--- 
-- pass table with lines
DocClass.parseSource = function(self,lines) 
  for i=1,#lines do 
    local line = lines[i]
    self:addLine(line)
  end
  -- save the latest chunk
  self:testStatus()
end

function m.load_file(filename)
  local x = init()
  local lines = {}
  for line in io.lines(filename) do
    lines[#lines+1] = line
  end
  x:parseSource(lines)
  return x
end

return m
