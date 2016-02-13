require 'luaOO'

local states = {
  resumed   = 1,
  running   = 2,
  suspended = 3,
  joined    = 4,
  dead      = 5,
}

local threads = {}

local current

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

local function _any(tbl, pred)
  for _, v in ipairs(tbl) do
    if pred(v) then
      return true
    end
  end
end

local function _thread_is_dead(t)
  return t._state == states.dead
end

local function _thread_is_not_dead(t)
  return t._state ~= states.dead
end

local function _thread_is_resumed(t)
  return t._state == states.resumed
end

local function _thread_wakeup_joined(t)
  for _, thread in ipairs(t._join_sources) do
    if thread._state == states.joined then
      thread._state = states.resumed
    end
  end

  t._join_sources = {}
end

------------------

Thread = Class()

-- static functions

function Thread.create(func, ...)
  local thread = Thread(func, ...)
  table.insert(threads, thread)

  return thread
end

function Thread.current()
  return current
end

function Thread.dispatch()
  -- when called inside a thread function, do nothing
  if current then
    return
  end

  -- loop until no resumed thread
  while true do
    local resumed_threads = _filter(threads, _thread_is_resumed)
    if #resumed_threads == 0 then
      break
    end

    for _, thread in ipairs(resumed_threads) do
      -- may be terminated
      if thread._state == states.resumed then
        local coro = thread._coro
        local args = thread._resume_args
        thread._resume_args = {}

        current = thread
        thread._state = states.running
        coroutine.resume(coro, table.unpack(args))
        current = nil

        if coroutine.status(coro) == 'dead' then
          thread._state = states.dead
          _thread_wakeup_joined(thread)
        end
      end
    end
  end

  -- remove dead thread
  if _any(threads, _thread_is_dead) then
    threads = _filter(threads, _thread_is_not_dead)
  end
end

function Thread.suspend()
  if current then
    current._state = states.suspended
    return coroutine.yield()
  end
end

function Thread.terminate(thread)
  if not thread then
    thread = current
    if not thread then
      return
    end
  end

  thread._state = states.dead
  _thread_wakeup_joined(thread)

  if thread == current then
    coroutine.yield()
  end
end

-- member functions

function Thread:__init__(func, ...)
  self._coro = coroutine.create(func)
  self._state = states.resumed
  self._resume_args = {...}

  self._join_sources = {}
end

function Thread:resume(...)
  if self._state == states.suspended then
    self._state = states.resumed
    self._resume_args = {...}
  end
end

function Thread:join()
  if current and self._state ~= states.dead then
    table.insert(self._join_sources, current)
    current._state = states.joined
    coroutine.yield()
  end
end
