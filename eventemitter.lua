require 'luaOO'

-- helper functions

local function _filter(tbl, pred)
  local ret = {}
  for _, v in ipairs(tbl) do
    if pred(v) then
      table.insert(ret, v)
    end
  end
  return ret
end

---------------------------------------------------

local Handler = Class()
local EventHandler = Class()
local EventEmitter = Class()

---------------------------------------------------

function Handler:__init__(func)
  self._func = func
  self._retired = false
end

function Handler:retire()
  self._retired = true
end

function Handler:call(...)
  if not self._retired then
    self._func(...)
  end
end

function Handler:running()
  return not self._retired
end

---------------------------------------------------

function EventHandler:__init__()
  self._handlers = {}
  self._invoking = false
  
  --when _invoking == true, to avoid iterator issues
  self._incoming = {}
  self._outgoing = false
end

function EventHandler:register(func)
  if self._invoking then
    table.insert(self._incoming, Handler(func))
  else
    table.insert(self._handlers, Handler(func))
  end
end

function EventHandler:unregister(func)
  for i, handler in ipairs(self._handlers) do
    if handler._func == func then
      if self._invoking then
        handler.retire()
        self._outgoing = true
      else
        table.remove(self._handlers, i)
      end
      break
    end
  end
end

function EventHandler:raise(...)
  if self._invoking then
    error('should not call EventHandler:raise nested')
  end

  self._invoking = true
  for _, handler in ipairs(self._handlers) do
    if handler.call(...) then
      break
    end
  end
  self._invoking = false

  if self._outgoing then
    self._outgoing = false
    self._handlers = _filter(self._handlers, Handler.running)
  end

  if #self._incoming then
    for _, handler in ipairs(self._incoming) then
      table.insert(self._handlers, handler)
    end
    self._incoming = {}
  end
end

---------------------------------------------------

function EventEmitter:__init__()
  self._eventHandlers = {}
end

function EventEmitter:register(what, func)
  local eventHandler = self._eventHandlers[what]
  if not eventHandler then
    eventHandler = EventHandler()
    self._eventHandlers[what] = eventHandler
  end
  eventHandler.register(func)
end

function EventEmitter:unregister(what, func)
  local eventHandler = self._eventHandlers[what]
  if eventHandler then
    eventHandler.unregister(func)
    if #eventHandler._handlers == 0 then
      self._eventHandlers[what] = nil
    end
  end
end

function EventEmitter:raise(what, ...)
  local eventHandler = self._eventHandlers[what]
  if eventHandler then
    eventHandler.raise(...)
    if #eventHandler._handlers == 0 then
      self._eventHandlers[what] = nil
    end
  end
end

return EventEmitter
