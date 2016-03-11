local Thread = require 'thread'

local AsyncIO = require 'asyncio'

local EventEmittor = require 'eventemittor'

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
  self._players = players
  self._enemies = enemies
end

function Combat:start()
  AsyncIO.invoke(self._routine)
end

--始终为玩家先手

function Combat:_routine()
  local round = 1
  while true do
    if self._playerPhase(round) then
      break
    end

    if self._enemyPhase(round) then
      break
    end

    round = round + 1
  end
end

function Combat:complete(success)

end

function Combat:_playerPhase(round)
  self.raise('beforePlayerPhase', self, round)


end

function Combat:_enemyPhase(round)
  self.raise('beforeEnemyPhase', self, round)
end
