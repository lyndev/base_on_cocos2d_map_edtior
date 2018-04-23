require "script/SDK/SkillTimer"
CBulletTimer = class("CBulletTimer", CSkillTimer)
CBulletTimer.type = "CBulletTimer"
local LOG_FILE_NAME = "CBulletTimer.log"

function CBulletTimer:New(o)
    o = CSkillTimer:New(o)
    setmetatable(o, CBulletTimer)
    o.m_Skill = false           --当前使用技能
    o.m_nAttackerID = 0         --攻击者ID
    o.m_nCurRefTargetID = 0     --当前攻击目标
    o.m_nActionType = 0         --目标的作用方式（火球--ETYPE_RANGE，飞箭--ETYPE_COUNT）
    o.m_nTargetID = 0 		    --目标ID
    o.m_nEffectID = 0           --效果ID
    return o
end

--功能: 初始化飞弹延迟Timer数据
--参数: nAttackerID:攻击者ID, nCurRefTargetID:参考目标, nTargetID:目标, Skill:当前使用技能, nEffectID:效果ID, nDelay:延迟时间, nActionType:飞弹类型（火球，飞箭）
--返回: 无
--备注: 
function CBulletTimer:SetBulletData(nAttackerID, nCurRefTargetID, nTargetID, Skill, nEffectID, nDelay, nActionType, bBreak)
	if not Skill then
        log_error(LOG_FILE_NAME, "SetActionData Skill is nil")
        return
    end
	self.m_nAttackerID = nAttackerID
    self.m_nCurRefTargetID = nCurRefTargetID
    self.m_Skill = Skill
    self.m_nActionType = nActionType
    self.m_nEffectID = nEffectID
    self.m_nTargetID = nTargetID
    self.m_bCanBreak = bBreak
    self:AddListener(self.m_nAttackerID)
	self:TimerEventByDelay(1, nDelay)
end

function CBulletTimer:Action()
    CSkillTimer.Action(self)
    local attacker = CEntityManager:GetEntity(self.m_nAttackerID)
    if not attacker then
        return
    end
    if self.m_nActionType == CSkill.ETrajectoryType.ETYPE_ARROW or self.m_nActionType == CSkill.ETrajectoryType.ETYPE_METEOR then
        --TODO:判断能否产生作用（如果目标已经不在目标点了，则不产生作用）
        attacker:UseEffect(self.m_Skill, self.m_nEffectID, self.m_nCurRefTargetID, self.m_nTargetID)
        local entity = CEntityManager:GetEntity(self.m_nTargetID)
        if entity then
            local x,y = entity:GetLocalPosition()
            self:_CreateShareEffect(attacker, x, y)
        end
    else
        --if self.m_nActionType == CSkill.ETrajectoryType.ETYPE_FIREBALL then
            --产生公共爆炸效果
            --local x,y = attacker:GetAtkPoint()
            local x, y = CEffectTargetChooser:GetRangeSelectorRefPoint(self.m_nAttackerID, self.m_nCurRefTargetID, self.m_nEffectID)
            
            self:_CreateShareEffect(attacker, x, y)
        --end
    	attacker:UseEffect(self.m_Skill, self.m_nEffectID, self.m_nCurRefTargetID, nil)
    end
    
end
--功能: 产生火球公共爆炸效果
--参数: 
--返回: 无
--备注: 
function CBulletTimer:_CreateShareEffect(attacker, x, y)
    
    if x == nil or y == nil then
        log_info(LOG_FILE_NAME, "GetAtkPoint x or y is nil, So Create Bomb Effect Failed")
        return
    end
    local EffectTmp = q_effect[self.m_nEffectID]
    if 0 ~= #EffectTmp[q_effect_index.q_range_effect] then
        local arg = PackEffectArg(attacker:GetMirror(), x, y)
        local tbEffect = StrSplit(EffectTmp[q_effect_index.q_range_effect], ";")
        for i,var in ipairs(tbEffect) do
            local effect = CEffectFactory:GetInstance():CreateEffect(var, arg)
            if effect then
                attacker:AddSceneEffect(effect)
            else
                log_error(LOG_FILE_NAME, "Create Bomb Effect = %s Failed!", var)
            end
        end
    end
end