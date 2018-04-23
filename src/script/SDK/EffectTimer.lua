require "script/SDK/SkillTimer"
require "script/SDK/BulletTimer"
require "script/Entity/Bullet"
CEffectTimer = class("CEffectTimer", CSkillTimer)
CEffectTimer.type = "CEffectTimer"
local LOG_FILE_NAME = "CEffectTimer.log"

function CEffectTimer:New(o)

    o = CSkillTimer:New(o)
    setmetatable(o, CEffectTimer)
    o.m_Skill = false         --当前使用技能
    o.m_nAttackerID = 0       --攻击者ID
    o.m_nCurRefTargetID = 0      --参考目标
    o.m_nSkillID = 0            --技能ID
    o.m_bBreak = true         --能否打断标记
    o.m_nEffectID = 0           --效果ID
    return o
end

--功能: 初始化动作匹配延迟Timer数据
--参数: nAttackerID:攻击者ID, nCurRefTargetID:参考目标, Skill:当前使用技能,nEffectID:效果ID, nDelay:延迟时间
--返回: 无
--备注: 
function CEffectTimer:SetActionData(nAttackerID, nCurRefTargetID, Skill, nEffectID, nDelay, bBreak)
    if not Skill then
        log_error(LOG_FILE_NAME, "SetActionData Skill is nil")
        return
    end
    self.m_nAttackerID = nAttackerID
    self.m_nCurRefTargetID = nCurRefTargetID
    self.m_Skill = Skill
    self.m_nEffectID = nEffectID
    self.m_nSkillID = Skill:GetModelID()
    self.m_bCanBreak = bBreak
    self.m_nDelay = nDelay
    self:AddListener(self.m_nAttackerID)
    
    self:TimerEventByDelay(1, nDelay)   --设置定时器信息
end

function CEffectTimer:Action()
    CSkillTimer.Action(self)
    local attacker = CEntityManager:GetEntity(self.m_nAttackerID)
    if not attacker then
        return
    end
    local EffectTmp = q_effect[self.m_nEffectID]
    if not EffectTmp then
        log_error(LOG_FILE_NAME, "Dont Find EffectID=%d!", self.m_nEffectID)
        return
    end
    --判断技能是否有弹道轨迹
    if 0 ~= EffectTmp[q_effect_index.q_trajectory_mode] then
        --判断是否有飞弹特效
        local hasEffect = false
        if 0 ~= #EffectTmp[q_effect_index.q_trajectory_effect] then
            hasEffect = true
        end
        
        --火球类飞弹处理
        if EffectTmp[q_effect_index.q_trajectory_mode] == CSkill.ETrajectoryType.ETYPE_FIREBALL then
            
            local effect = nil
            local refX, refY = CEffectTargetChooser:GetRangeSelectorRefPoint(self.m_nAttackerID, self.m_nCurRefTargetID, self.m_nEffectID)
            if hasEffect then
                --effect = self:_CreateBullet(attacker, attacker:GetAtkPoint())
                effect = self:_CreateBullet(attacker, refX, refY)
            end
            --获取延时
            local delay = self:_GetDelayTime(effect, attacker, refX, refY)
            --创建轨迹延迟timer
            local bulletTimer = CBulletTimer:New()
            bulletTimer:SetBulletData(self.m_nAttackerID, self.m_nCurRefTargetID, nRefTargetID, 
                        self.m_Skill, self.m_nEffectID, delay, CSkill.ETrajectoryType.ETYPE_FIREBALL, self.m_bCanBreak)
            attacker.m_oEventTimerMgr:AddEvent(bulletTimer, self.m_Skill:IsBigSkill())
        end
        --飞箭类飞弹处理
        if EffectTmp[q_effect_index.q_trajectory_mode] == CSkill.ETrajectoryType.ETYPE_ARROW then
            --取得效果作用目标
            local objType = EffectTmp[q_effect_index.q_effect_object]
            --获取真实目标
            local tbRealTargetID = CEffectTargetChooser:GetAttackTarger(self.m_nAttackerID, self.m_nCurRefTargetID, self.m_nEffectID) --or {self.m_nCurRefTargetID}
            if not tbRealTargetID then
                log_info(LOG_FILE_NAME, "AttackerID=%d Use SkillID=%d Dont Find Targets!", self.m_nAttackerID, self.m_nSkillID)
                return
            end
            for _,id in ipairs(tbRealTargetID) do                           
                --计算目地的坐标
                local targetEntity = CEntityManager:GetEntity(id)
                if targetEntity then
                    local effect = nil
                    if hasEffect then
                        effect = self:_CreateBullet(attacker, targetEntity:GetLocalPosition())
                    end
                    --获取延时
                    local delay = self:_GetDelayTime(effect, attacker, targetEntity:GetLocalPosition())
                    --创建轨迹延迟timer
                    local bulletTimer = CBulletTimer:New()
                    bulletTimer:SetBulletData(self.m_nAttackerID, self.m_nCurRefTargetID, id, self.m_Skill, self.m_nEffectID, delay, CSkill.ETrajectoryType.ETYPE_ARROW, self.m_bCanBreak)
                    attacker.m_oEventTimerMgr:AddEvent(bulletTimer, self.m_Skill:IsBigSkill())
                    -- local pBullet = CBullet:New()
                    -- pBullet:InitData(1000, "effect/bulletTest.xml", self.m_nEffectID, self.m_nAttackerID, id, self.m_nCurRefTargetID, self.m_nSkillID)
                    -- CEntityManager:GetInstance():AddEntity(pBullet)
                end
                
            end
        end
        --暴风雪类处理
        if EffectTmp[q_effect_index.q_trajectory_mode] == CSkill.ETrajectoryType.ETYPE_SNOWSTORM then
            local refX, refY = CEffectTargetChooser:GetRangeSelectorRefPoint(self.m_nAttackerID, self.m_nCurRefTargetID, self.m_nEffectID)
            local effect = self:_CreateSnowstormEffect(attacker, refX, refY)
            --获取延时
            local delay = EffectTmp[q_effect_index.q_snowstorm_delay] / 1000
            --创建轨迹延迟timer
            local bulletTimer = CBulletTimer:New()
            bulletTimer:SetBulletData(self.m_nAttackerID, self.m_nCurRefTargetID, nRefTargetID, 
                        self.m_Skill, self.m_nEffectID, delay, CSkill.ETrajectoryType.ETYPE_SNOWSTORM, self.m_bCanBreak)
            attacker.m_oEventTimerMgr:AddEvent(bulletTimer, self.m_Skill:IsBigSkill())
        end
        --流星雨类处理
        if EffectTmp[q_effect_index.q_trajectory_mode] == CSkill.ETrajectoryType.ETYPE_METEOR then
            --取得效果作用目标
            local objType = EffectTmp[q_effect_index.q_effect_object]
            --获取真实目标
            local tbRealTargetID = CEffectTargetChooser:GetAttackTarger(self.m_nAttackerID, self.m_nCurRefTargetID, self.m_nEffectID) --or {self.m_nCurRefTargetID}
            if not tbRealTargetID then
                log_info(LOG_FILE_NAME, "AttackerID=%d Use SkillID=%d Dont Find Targets!", self.m_nAttackerID, self.m_nSkillID)
                return
            end
            for _,id in ipairs(tbRealTargetID) do                           
                --计算目地的坐标
                local targetEntity = CEntityManager:GetEntity(id)
                if targetEntity then
                    local x, y = targetEntity:GetLocalPosition()    
                    local effect = self:PlayShowerEffect(targetEntity, attacker, x, y)
                    --获取延时
                    local delay = EffectTmp[q_effect_index.q_snowstorm_delay] / 1000
                    --创建轨迹延迟timer
                    local bulletTimer = CBulletTimer:New()
                    bulletTimer:SetBulletData(self.m_nAttackerID, self.m_nCurRefTargetID, id, self.m_Skill, self.m_nEffectID, delay, CSkill.ETrajectoryType.ETYPE_METEOR, self.m_bCanBreak)
                    attacker.m_oEventTimerMgr:AddEvent(bulletTimer, self.m_Skill:IsBigSkill())
                end
                
            end
        end
    else
        --判断攻击者实体是否死亡
        if not attacker or attacker:IsDead() then
            log_info(LOG_FILE_NAME, "AttackerID=%d Is Dead", self.m_nAttackerID)
            return
        end
        --无轨迹直接作用效果
        attacker:UseEffect(self.m_Skill, self.m_nEffectID, self.m_nCurRefTargetID, nil)
    end

end
--功能: 创建一个飞弹
--参数: attacker:攻击者实体,  nX:目标X, nY:目标Y
--返回: 飞行时间
--备注: 
function CEffectTimer:_CreateBullet(attacker, nX2, nY2)
    if nX2 == nil or nY2 == nil then
        log_info(LOG_FILE_NAME, "x or y is nil, So Create Trajectory Effect Failed")
        return nil
    end
    local sEffect = q_effect.GetTempData(self.m_nEffectID, "q_trajectory_effect") or ""
    local nMirror = 0
    --起始坐标
    local nX1, nY1 = attacker:GetLocalPosition()
    --判断是否要转向
    if nX1 > nX2 then
        nMirror = 1
    end
    --解析飞弹在配置表中的参数
    --飞行速度
    local nSpeed  = q_effect.GetTempData(self.m_nEffectID, "q_trajectory_speed") or 1
    --加速度
    local nAcceleration  = q_effect.GetTempData(self.m_nEffectID, "q_trajectory_acceleration")
    --角度
    local nAngle  = q_effect.GetTempData(self.m_nEffectID, "q_trajectory_angle")
    --产生飞弹特效
    local arg = PackEffectArg(nMirror, nX1, nY1, nX2, nY2 + 50, nSpeed, nAcceleration, nAngle)
    local effect = CEffectFactory:GetInstance():CreateEffect(sEffect, arg)
    if effect then
        attacker:AddSceneEffect(effect)
    else
        log_error(LOG_FILE_NAME, "Create Trajectory Effect = %s Failed!", sEffect)
    end
    return effect
end
--功能: 获取弹道飞行延迟
--参数: start:起始点,  nX:目标X
--返回: 无
--备注: 
function CEffectTimer:_GetDelayTime(effect, attacker, nX2, nY2)
    if nX2 == nil or nY2 == nil then
        return 0
    end
    local nSpeed  = q_effect.GetTempData(self.m_nEffectID, "q_trajectory_speed") or 1
    local nX1, nY1
    if effect then
        nX1 = effect:getPositionX()
        nY1 = effect:getPositionY()
    else
        nX1, nY1 = attacker:GetLocalPosition()
    end
    
    --角度
    local nAngle  = q_effect.GetTempData(self.m_nEffectID, "q_trajectory_angle")
    local dis
    if nAngle == 0 then
        --直线是两点之间的距离
        dis = math.sqrt(math.pow(nX1 - nX2, 2) + math.pow(nY1 - nY2, 2))
        --dis = math.abs(nX1 - nX2)
    else
        --抛物线的距离是两点x之间的距离
        dis = math.abs(nX1 - nX2)
    end
    local v = math.cos(math.rad(nAngle)) * nSpeed
    local time = dis / v
    return time
end

--功能: 产生暴风雪效果
--参数: 
--返回: 无
--备注: 
function CEffectTimer:_CreateSnowstormEffect(attacker, nX, nY, zOrder)
    if nX == nil or nY == nil then
        log_error(LOG_FILE_NAME, "nX or nY is nil, Create Snowstorm Effect Failed!")
        return
    end
    local EffectTmp = q_effect[self.m_nEffectID]
    if not EffectTmp then
        log_error(LOG_FILE_NAME, "Dont Find EffectID=%d, Create Snowstorm Effect Failed!", self.m_nEffectID)
        return
    end
    if  0 ~= #EffectTmp[q_effect_index.q_snowstorm_effect] then
        local arg = PackEffectArg(attacker:GetMirror(), nX, nY)
        local tbEffect = StrSplit(EffectTmp[q_effect_index.q_snowstorm_effect], ";")
        for i,var in ipairs(tbEffect) do
            local effect = CEffectFactory:GetInstance():CreateEffect(var, arg)
            if zOrder ~= nil then
                zOrder = effect:getZOrder() + zOrder
            end
            if effect then
                attacker:AddSceneEffect(effect, zOrder)
                return effect
            else
                log_error(LOG_FILE_NAME, "Create Snowstorm Effect Failed!")
            end
        end
    end
end

--功能: 创建流星雨特效
--参数: 无
--返回: 无
--备注: 
function CEffectTimer:PlayShowerEffect(target, attacker, nX, nY)
    local EffectTmp = q_effect[self.m_nEffectID]
    if not EffectTmp then
        log_error(LOG_FILE_NAME, "Dont Find EffectID=%d, Create Shower Effect Failed!", self.m_nEffectID)
        return
    end
    if  0 ~= #EffectTmp[q_effect_index.q_snowstorm_effect] then
        --添加到target身上的特效
        local arg1 = PackEffectArg(0)
        --添加到target所在地块上的特效(注意：特效是添加到人物身上，还是添加到地块上是由xml里面挂接类型来判断的)
        local arg2 = PackEffectArg(attacker:GetMirror(), nX, nY)
        local tbEffect = StrSplit(EffectTmp[q_effect_index.q_snowstorm_effect], ";")
        for i,var in ipairs(tbEffect) do
            local effect = CEffectFactory:GetInstance():CreateEffect(var, arg1)
            if effect then
                local hookType = effect:GetHookType()
                if hookType == 1 then
                    target:AddChildEffect(effect, ENUM.EAnimSourceType.ESource_Type_Hit)
                    return effect
                else
                    local effect2 = CEffectFactory:GetInstance():CreateEffect(var, arg2)
                    if effect2 then
                        local zOrder = target:GetOrder() + effect:getZOrder()
                        attacker:AddSceneEffect(effect2, zOrder)
                        return effect2
                    end
                end
            else
                log_error(LOG_FILE_NAME, "Create Shower Effect Failed!")
            end
        end
    end
end