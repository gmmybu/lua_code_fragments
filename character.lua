local EventTrigger = require 'event_trigger'

local Character = Class(EventTrigger)













--[[

template = {
  guid : 12345,
  name : '拉格纳罗斯',

  -- 基本属性
  health : 10000,
  mana : 250,

  attack : 200,
  attack_delta : 50,  --随机附加值
  armor  : 25,


  -- 战斗奖励
  gold : 250,
  experience : 1000,
  reward : {{0.3, 250}, {0.4, 251}, {0.1, 252}},

  -- ai
  action : function(character, combat, round)
    --条件1，一定概率释放技能x
    --条件2，一定概率释放技能y
    --...

    --选择目标进行普通攻击
  end,

  character_enter_combat : function(combat, character)
    -- 释放光环
    -- 初始化被动技能
  end,

  character_enter_combat : function(combat, character)
    -- 收回光环
  end

}

--]]


-- 普通怪物直接配置文件创建
function Character.create_from_template(template)
  local character = Character(template.guid, template.name, template.health, template.mana, template.armor)

  if template.character_enter_combat then
    character.register('character_enter_combat', template.character_enter_combat)
  end

  if template.character_leave_combat then
    character.register('character_leave_combat', template.character_leave_combat)
  end

  if template.character_dead then
    character.register('character_dead', function(combat, character)
      combat.add_gold(template.gold)
      combat.add_experience(template.experience)


      combat.add_reward(xxx)
    end)
  end





end














































