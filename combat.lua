local Thread = require 'thread'

local AsyncIO = require 'asyncio'

local EventEmitter = require 'eventemitter'

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


--回合制游戏中的实现
--流程伪代码

--纯回合制

--playerphase
--按速度从大到小排序, 死掉的除外
--对于每一个角色 
--0 dot, hot, buff结算
--1 如果死亡或处于无法攻击状态，则结束
--2 弹出战斗菜单, 用户选择战斗动作
--3 播放战斗动画
--4 战斗结算

--enemyphase
--按速度从大到小排序(或自定义排序)
--对于每一个敌人
--0 dot, hot, buff结算
--1 如果死亡或处于无法攻击状态，则结束
--2 调用敌人AI脚本计算战斗动作
--3 播放战斗动画
--4 战斗结算

--结算分为多种，包括dot, hot, buff, 伤害(分为物理, 法术, 治疗等)
--结算动画和战斗动画可能有重叠部分 *(不太严密确定)
--战斗结算触发角色死亡检测, 全灭检测等, 引发战斗结束

--战斗结束
--播放结束动画
--如果胜利, 战利品结算


--事件触发列表
--beforePlayerPhase
--beforeEnemyPhase

local Combat = Class(EventEmittor)

function Combat:__init__(players, enemies)
  EventEmitter.__init__(self)

  self._players = players
  self._enemies = enemies
end

function Combat:start()
  AsyncIO.invoke(self._routine)
end

--始终为玩家先手

function Combat:_routine()
  self.invoke('beforeCombat', self)

  local round = 1
  while true do
    self._playerPhase(round)
    self._enemyPhase(round)
    round = round + 1
  end
end

function Combat:complete(success)
  self.invoke('afterCombat', self)

  --战斗结算
end

function Combat:_player_action(player, round)
  -- 被某触发器杀死
  if player.is_dead() then return end

  -- 跳过角色回合
  local freeze = self.invoke('trigger_player_action_freeze', self, player, round)
  if freeze then return end

  -- 触发回合前hot, dot, buff
  self.invoke('trigger_player_action_start', self, player, round)
  if player.is_dead() then return end

  -- 情节触发点
  self.invoke('trigger_player_action_start_story', self, player, round)
  if player.is_dead() then return end

  -- 角色行动托管，可以用来实现眩晕，睡眠，以及疯狂效果 
  local executed = self.invoke('trigger_player_action_execute', self, player, round)
  if not executed then
    -- 弹出用户操作面板，让用户选择角色动作
  end

  -- 触发回合后hot, dot, buff
  self.invoke('trigger_player_action_finish', self, player, round)
  if player.is_dead() then return end

  -- 情节触发点
  self.invoke('trigger_player_action_finish_story', self, player, round)
end

function Combat:_player_round(round)
  -- 跳过玩家回合
  local freeze = self.invoke('trigger_player_round_freeze', self, round)
  if freeze then return end

  -- 玩家回合前触发器
  self.invoke('trigger_player_round_start', self, round)

  -- 情节触发点
  self.invoke('trigger_player_round_start_story', self, round)

  local players = _filter(self._players, Player.isAlive)
  table.sort(players, Player.compareBySpeed)

  for i, player in ipairs(players) do
    self._player_action(player, round)
  end

  -- 玩家回合后触发器
  self.invoke('trigger_player_round_finish', self, round)

  -- 情节触发点
  self.invoke('trigger_player_round_finish_story', self, round)
end

------------------------------------------------------------------

-- 同上面类似

function Combat:_enemy_action(enemy, round)
  -- 被某触发器杀死
  if enemy.is_dead() then return end

  -- 跳过敌人回合
  local freeze = self.invoke('trigger_enemy_action_freeze', self, enemy, round)
  if freeze then return end

  -- 触发回合前hot, dot, buff
  self.invoke('trigger_enemy_action_start', self, enemy, round)
  if enemy.is_dead() then return end

  -- 情节触发点
  self.invoke('trigger_enemy_action_start_story', self, enemy, round)
  if enemy.is_dead() then return end

  -- 角色行动托管，可以用来实现眩晕，睡眠，以及疯狂效果 
  local executed = self.invoke('trigger_enemy_action_execute', self, enemy, round)
  if not executed then
    -- 调用敌人的AI来计算操作
  end

  -- 触发回合后hot, dot, buff
  self.invoke('trigger_enemy_action_finish', self, enemy, round)
  if enemy.is_dead() then return end

  -- 情节触发点
  self.invoke('trigger_enemy_action_finish_story', self, enemy, round)
end

function Combat:_enemy_round(round)
  -- 跳过敌人回合
  local freeze = self.invoke('trigger_enemy_round_freeze', self, round)
  if freeze then return end

  -- 敌人回合前触发器
  self.invoke('trigger_enemy_round_start', self, round)

  -- 情节触发点
  self.invoke('trigger_enemy_round_start_story', self, round)

  local enemies = _filter(self._enemies, Enemy.isAlive)
  table.sort(enemies, Enemy.compareBySpeed)

  for i, enemy in ipairs(enemies) do
    self._enemy_action(player, round)
  end

  -- 敌人回合后触发器
  self.invoke('trigger_enemy_round_finish', self, round)

  -- 情节触发点
  self.invoke('trigger_enemy_round_finish_story', self, round)
end
