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
local EventTrigger = Class()

---------------------------------------------------

function Handler:__init__(func)
  self._func = func
  self._retired = false
end

function Handler:retire()
  self._retired = true
end

function Handler:invoke(...)
  return self._func(...)
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

function EventHandler:invoke(...)
  if self._invoking then
    error('should not call EventHandler:invoke nested')
  end

  local ret = {}

  self._invoking = true
  for _, handler in ipairs(self._handlers) do
    if handler.running() then
      ret = {handler.invoke(...)}
    end
  end
  self._invoking = false

  if self._outgoing then
    self._outgoing = false
    self._handlers = _filter(self._handlers, Handler.running)
  end

  if #self._incoming > 0 then
    for _, handler in ipairs(self._incoming) do
      table.insert(self._handlers, handler)
    end
    self._incoming = {}
  end

  return table.unpack(ret)
end

---------------------------------------------------

function EventTrigger:__init__()
  self._event_handlers = {}
end

function EventTrigger:register(event, func)
  local target = self._event_handlers[event]
  if not target then
    target = EventHandler()
    self._event_handlers[event] = target
  end
  target.register(func)
end

function EventTrigger:unregister(event, func)
  local target = self._event_handlers[event]
  if not target then return end

  target.unregister(func)
  if #target._handlers == 0 then
    self._event_handlers[event] = nil
  end
end

function EventTrigger:trigger(event, ...)
  local target = self._event_handlers[event]
  if not target then return end

  local ret = {target.invoke(...)}
  if #target._handlers == 0 then
    self._event_handlers[event] = nil
  end
  
  return table.unpack(ret)
end

return EventTrigger
