require 'luaOO'

local AsyncContext = Class()
function AsyncContext:__init__(coro)
  self._coro = coro
  self._done = false
end

function AsyncContext:cancel()
  self._done = true
  self._result = {false, 'canceled'}
end

function AsyncContext:result()
  if not self._result then
    error('must be called when .done() returns true')
  end

  return table.unpack(self._result)
end

function AsyncContext:done()
  return self._done
end

------------------------------------------

local contexts = {}

-- private functions

local function _context_create(func)
  local context = AsyncContext(coroutine.create(func))
  table.insert(contexts, context)
  return context
end

local function _context_remove(context)
  for i, v in ipairs(contexts) do
    if v == context then
      table.remove(contexts, i)
      break
    end
  end
end

local function _context_current()
  local coro = coroutine.running()
  for _, context in ipairs(contexts) do
    if context._coro == coro then
      return context
    end
  end
end

local function _context_resume(context, ...)
  local result = {coroutine.resume(context._coro, ...)}
  if coroutine.status(context._coro) ~= 'dead' then
    return
  end

  _context_remove(context)
  context._done = true
  context._result = result
end

------------------------------------------

local exports = {}

function exports.invoke(func, ...)
  local context = _context_create(func)
  _context_resume(context, ...)
  return context
end

function exports.yield(func, ...)
  local current = _context_current()
  if not current then
    error('must be called inside .invoke')
  end

  local args = {...}
  -- in case that callback is called in current context
  local immediate_result
  table.insert(args, function(...)
    if _context_current() == current then
      immediate_result = {...}
    elseif not current._done then
      _context_resume(current, ...)
    end
  end)

  func(table.unpack(args))

  if immediate_result then
    return table.unpack(immediate_result)
  else
    return coroutine.yield()
  end
end

function exports.return(...)
  local current = _context_current()
  if not current then
    error('must be called inside asyncio.invoke')
  end

  _context_remove(current)
  current._done = true
  current._result = {true, ...}
  return coroutine.yield()
end

return exports
