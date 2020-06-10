local m = {}

local object_cache = {}

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
    tex.print(table.concat(ch),"")
    -- print(table.concat(ch),"\n")
  end
  local print_code = function(ch)
    --tex.print("\n\n\\noindent")
    for _, line in ipairs(ch) do
      tex.print("\\noindent\\verb|" .. line .."|\\\\")
    end
  end
  for ch in self:iter() do
    if ch.status == "code" or ch.status == "doc" then
      print_code(ch)
    elseif ch.status == "api_doc" then
      for _, line in ipairs(ch) do
        tex.print(line)
      end
      tex.print("")
    else
      print_chunk(ch)
    end
  end
end



--- 
-- Get type of content of the tested line
DocClass.getLineStatus = function(self,line)
  local status = self.status
  -- print(status, line)
  if line:match("^%s*%%%%") then
    -- api_doc starts with two %%
    return "api_doc"
  elseif line:match("^%s*%%") then
    -- commented lines that follow api_doc start are part
    -- of api_doc
    if status == "api_doc" then 
      return status
    else
      -- they are normal comments otherwise
      return "comment"
    end
  elseif line:match("^%s*$") then
    -- blank line (paragraph break)
    return "blank"
  else 
    return "code"
  end
end

---
-- this function closes the current chunk and initiates a new one
DocClass.testStatus = function(self,status)
  local status = status or self.status
  local current_chunk = self.current_chunk 
  current_chunk.status = status
  table.insert(self.chunks, current_chunk)
  self.current_chunk = {}
end


DocClass.addLine = function(self, line)
  -- process input lines
  local status = self.status
  local line_status = self:getLineStatus(line)
  -- if line_status == "doc" or line_status == "api_doc" then line = line:gsub("^%s*%%","") end
  -- close current chunk when the status changes
  if status ~= "init" and status ~= line_status then
    self:testStatus(status)
  end
  self.status = line_status
  table.insert(self.current_chunk, line)
end

---
-- Parse API doc tags
-- supported tags:
-- @package -- package name
-- @author  -- author name
-- @option  -- package option
-- @cmd     -- command name
-- @marg    -- mandatory argument
-- @oarg    -- optional argument
-- @darg    -- argument with custom delimiters
-- @key     -- keyval option for command
-- @id      -- id of this api_doc block and the following code block
-- @type    -- type of this api_doc block and the following code block
DocClass.parseTags = function(self)

  for i, chunk in ipairs(self.chunks) do
    if chunk.status == "api_doc" then
      -- replace the old chunk with a new one, with tags removed
      local newchunk = {status = "api_doc", tags = {}}
      for _, line in ipairs(chunk) do
        -- remove "%" characters from the line start
        local line = line:gsub("^%s*%%*", "")
        -- match tags, they start with @<tagname>
        local tag, params = line:match("%s*@(%w+)%s*(.*)")
        if tag then
          table.insert(newchunk.tags, {tag = tag, params = params})
        else
          -- copy lines that are not tags as input text
          -- it can be description of the command etc.
          table.insert(newchunk, line)
        end
      end
      self.chunks[i] = newchunk
    end
  end
end
--- 
-- parse table containing LaTeX source
-- individual lines are table elements
DocClass.parseSource = function(self,lines) 
  for i=1,#lines do 
    local line = lines[i]
    self:addLine(line)
  end
  -- save the latest chunk
  self:testStatus()
  self:parseTags()
end

---
-- Parse the literate LaTeX source
function m.load_file(filename)
  -- enable reusing of the parsed content
  local cached = object_cache[filename]
  if cached then return cached end
  local x = init()
  local lines = {}
  for line in io.lines(filename) do
    lines[#lines+1] = line
  end
  x:parseSource(lines)
  object_cache[filename] = x
  return x
end

return m
