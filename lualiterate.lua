local m = {}


function m.load_file(filename)
  local status = "init"
  local current_chunk = {}
  local DocClass = {}
  DocClass.__index = DocClass
  local init = function() 
    local self =  setmetatable({},DocClass) 
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
  DocClass.testStatus = function(self,status)
    current_chunk.status = status
    table.insert(self.chunks, current_chunk)
    current_chunk = {}
  end
  DocClass.list_sources = function(self)
    local print_chunk = function(ch)
      tex.print(table.concat(ch),"\n")
    end
    for ch in self:iter() do
      if ch.status == "code" then
        tex.print("\\begin{lstlisting}\n")
        print_chunk(ch)
        tex.print("\\end{lstlisting}\n")
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
  local x = init()
  for line in io.lines(filename) do
    x:addLine(line)
  end
  x:testStatus(status)
  return x
end

return m
