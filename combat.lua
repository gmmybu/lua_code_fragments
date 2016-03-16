local Thread = require 'thread'

local EventTrigger = require 'event_trigger'

local asyncio = require 'asyncio'

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

--事件列表

--character

--character_enter_combat
--character_leave_combat

--character_begin_round
--character_enter_round
--character_check_disabled
--character_begin_action
--character_leave_round

--

---------------------------

--combat

--combat_initialize
--combat_shutdown

--combat_begin_player_round
--combat_enter_player_round
--combat_leave_player_round

--combat_begin_enemy_round
--combat_enter_enemy_round
--combat_leave_enemy_round


local Combat = Class(EventTrigger)

function Combat:__init__(players, enemies)
  EventTrigger.__init__(self)

  self._players = players
  self._enemies = enemies

  self._gold = 0
  self._experience = 0
  self._reward = {}
end

--道具或技能等可导致经验或金钱加成可调用get获取当前值计算完再set

function Combat:add_experience(exp)
  self._experience = self._experience + exp
end

function Combat:set_experience(exp)
  self._experience = exp
end

function Combat:get_experience()
  return self._experience
end

function Combat:add_reward(obj)
  table.insert(self._reward, obj)
end

function Combat:get_reward()
  return self._reward
end

function Combat:add_gold(gold)
  self._gold = self._gold + gold
end

function Combat:set_gold(gold)
  self._gold = gold
end

function Combat:get_gold()
  return self._gold
end

function Combat:start()
  asyncio.start(self._routine)
end

function Combat:_routine()
  self.trigger('combat_initialize', self)

  for _, character in ipairs(self._players) do
    character.trigger('character_enter_combat', self, character)
  end

  for _, character in ipairs(self._enemies) do
    character.trigger('character_enter_combat', self, character)
  end

  local round = 1
  while true do
    self._player_round(round)
    self._enemy_round(round)
    round = round + 1
  end
end

Combat.SUCCESS = 1
Combat.DEFEAT_CONTINUE = 2
Combat.DEFEAT_GAMEOVER = 3
Combat.ABORT = 4

function Combat:finish(reason)
  for _, character in ipairs(self._players) do
    character.trigger('character_leave_combat', character, combat)
  end

  for _, character in ipairs(self._enemies) do
    character.trigger('character_leave_combat', character, combat)
  end

  self.trigger('combat_shutdown', self)

  if reason == Combat.SUCCESS then
  --显示战斗胜利画面，给予玩家经验，金钱以及奖励品
  end

  if reason == Combat.DEFEAT_CONTINUE or
     reason == Combat.DEFEAT_GAMEOVER
  then
  --显示战斗失败画面，根据条件是否结束游戏
  end

  asyncio.leave()
end

function Combat:_character_round(character, round, is_player)
  character.trigger('character_begin_round', character, self, round)
  if character.is_dead() then return end

  character.trigger('character_enter_round', character, self, round)
  if character.is_dead() then return end

  local disabled = character.trigger('character_check_disabled', character, self, round)
  if not disabled then
    local executed = character.trigger('character_begin_action', character, self, round)
    if not executed then
    -- 弹出用户操作面板，让用户选择角色动作或者调用敌人AI来计算操作
    end
  end

  character.trigger('character_leave_round', character, self, round)
end

function Combat:_player_round(round)
  self.trigger('combat_begin_player_round', self, round)

  self.trigger('combat_enter_player_round', self, round)

  table.sort(self._players, Character.compare_by_speed)

  for _, character in ipairs(self._players) do
    self._character_round(character, round, true)
  end

  self.trigger('combat_leave_player_round', self, round)
end

function Combat:_enemy_round(round)
  self.trigger('combat_begin_enemy_round', self, round)

  self.trigger('combat_enter_enemy_round', self, round)

  table.sort(self._enemies, Character.compare_by_speed)

  for _, character in ipairs(self._enemies) do
    self._character_round(character, round, false)
  end

  self.trigger('combat_leave_enemy_round', self, round)
end
