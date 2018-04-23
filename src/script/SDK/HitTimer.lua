require "script/SDK/TimerEvent"

CHitTimer = class("CHitTimer", CTimerEvent)
CHitTimer.type = "CHitTimer"

function CHitTimer:New(o)

    o = CTimerEvent:New(o)
    setmetatable(o, CHitTimer)
    o.AttackerID = 0
    o.TargetID = 0
    o.SkillID = 0
    o.EffectInfo = {}
    o.EType = 0

    return o
end

--[[
-- 参    数:
--    attackerID: 攻击者ID
--    nRefTargetID: 参考点目标ID
--    nTargetID: 选择的目标ID
--    nSkillID: 技能ID
--    nDelay: 延迟时间
--    eType: 选择目标的方式
--    effectInfo: 效果信息
--]]
function CHitTimer:SetHitData(attackerID, nRefTargetID, nTargetID, nSkillID, nDelay, eType)
    self.AttackerID = attackerID
    self.RefTargetID = nRefTargetID
    self.TargetID = nTargetID
    self.SkillID = nSkillID
    self.EType = eType

    self:TimerEventByDelay(1, nDelay)
end

function CHitTimer:Action()
    CTimerEvent.Action(self)
    -- 攻击者死亡不产生效果
    local attacker = CEntityManager:GetInstance():GetEntity(self.AttackerID)
    if not attacker or attacker:IsDead() then
        return
    end

    if attacker:GetEntityType() == CEntity.EType.ETYPE_HERO then
        local a = 1
    end

    -- 获取技能信息
    local pSkillInfo = attacker:GetSkillByModelID(self.SkillID)
    if not pSkillInfo then
        log_error("CHitTimer.log", "skill not find:%d", self.SkillID)
        return
    end
    
    -- 获取震动屏幕参数
    local strCraze = q_skill.GetTempData(self.SkillID, "q_zhendong")
    if strCraze and #strCraze > 0 then
        local tbParam = StrSplit(strCraze, "_")
        if #tbParam >= 3 then
            CGameMap:GetInstance():MapCraze(tbParam[1], tbParam[2], tbParam[3])
        end
    end
    -- 获取作用目标
    local tbTargetList = {}
    local objAtt = CEntityManager:GetInstance():GetEntity(self.AttackerID)
    if objAtt and objAtt:HasBuffChangeState(CDeffender.EBuffState.EBUFF_TAUNT) then
        local nTargetID = objAtt:GetBuffParam(CDeffender.EBuffState.EBUFF_TAUNT)
        if nTargetID then
            local objTar = CEntityManager:GetInstance():GetEntity(nTargetID)
            if objTar and not objTar:IsDead() then
                table.insert(tbTargetList, nTargetID)
            else
                tbTargetList = pSkillInfo:GetRealTarget(self.EType, self.RefTargetID, self.TargetID, self.AttackerID)
            end
        else
            tbTargetList = pSkillInfo:GetRealTarget(self.EType, self.RefTargetID, self.TargetID, self.AttackerID)
        end
    else
       tbTargetList = pSkillInfo:GetRealTarget(self.EType, self.RefTargetID, self.TargetID, self.AttackerID)
    end
    if gFightMgr and gFightMgr:GetFightType() == CFightMgr.Type.GUIDE_DEMO then   --非引导战斗受击回复能量
        tbTargetList = gFightMgr:FixTargetList(pSkillInfo, tbTargetList)
    end
    if not tbTargetList or #tbTargetList == 0 then
        return
    end
    attacker.m_BuffMgr:Event(CTriggerBuff.TriggerType.EBUFF_ATTACK, {pSkill = pSkillInfo, tTarget = tbTargetList})   --攻击触发buff
    if pSkillInfo:GetPassiveType() == CSkill.SkillType.DEF_SKILL then
        attacker.m_BuffMgr:Event(CTriggerBuff.TriggerType.EBUFF_COMSKILL, {pSkill = pSkillInfo, tTarget = tbTargetList}) --使用普通攻击触发buff
    end
    local tbEnemyEffect = nil -- 作用于敌人的效果参数
    local pSkillTmp = pSkillInfo:GetSkillData()
    if self.EType == CSkill.EEffectActionType.ETYPE_ENEMY then
        if (q_skill.GetTempData(self.SkillID, "q_enemy_action") or 0) ~= 0 then
            tbEnemyEffect = pSkillInfo:ParseEffectVarByType(self.EType)
        end
    elseif self.EType == CSkill.EEffectActionType.ETYPE_FRIEND then
        if (q_skill.GetTempData(self.SkillID, "q_friend_action") or 0) ~= 0 then
            tbEnemyEffect = pSkillInfo:ParseEffectVarByType(self.EType)
        end
    elseif self.EType == CSkill.EEffectActionType.ETYPE_SELF then
        if (q_skill.GetTempData(self.SkillID, "q_self_action") or 0) ~= 0 then
            tbEnemyEffect = pSkillInfo:ParseEffectVarByType(self.EType)
        end
    end
    
    if not tbEnemyEffect or #tbEnemyEffect == 0 then
        return
    end
    local times = 4
    for _,var in pairs(tbEnemyEffect) do
        -- 获取效果
        local effect = CCEffectManager:GetInstance():GetEffectObject(var.nEffectID)
        if effect then
            -- 对目标执行相应的效果
            for _, v in pairs(tbTargetList) do
                local tar = CEntityManager:GetInstance():GetEntity(v)
                if tar and not tar:IsDead() and tar:IsCanBeAttack() then
                    if LogFight then
                        table.insert(gUpdateTbl[gFightMgr.m_Process], {"hittimer", v, gFightMgr.m_fTime, "\n"})
                    end
                    local tParam = {sVar = var.strVar, tar = tar, att = attacker, pSkill = pSkillInfo}
                    tar:RemoveSkillEffect(self.SkillID, attacker.m_nTemplateID)
                    if pSkillInfo:GetModelID() == 231 then
                        local varMulti = {sVar = var.strVar, tar = tar:GetEntityID(), att = attacker:GetEntityID(), pSkill = pSkillInfo, effect=var.nEffectID}
                        local timer = CCallbackTimer:New({}, varMulti, function(obj, paraMulti)
                            local attMulti = CEntityManager:GetInstance():GetEntity(paraMulti.att)
                            if not attMulti or attMulti:IsDead() then
                                return
                            end
                            local vicMulti = CEntityManager:GetInstance():GetEntity(paraMulti.tar)
                            if not vicMulti or vicMulti:IsDead() then
                                return
                            end
                            local effectMulti = CCEffectManager:GetInstance():GetEffectObject(paraMulti.effect)
                            if not effectMulti then
                                return
                            end
                            local tParamMulti = {sVar = paraMulti.strVar, tar = vicMulti, att = attMulti, pSkill = paraMulti.pSkill}    
                            effectMulti:EnterEffect(tParamMulti)
                        end, 1, 0.3*times)
                        gFightMgr.m_Timer:AddEvent(timer, pSkillInfo:IsBigSkill())
                        times = times + 1
                    else
                        effect:EnterEffect(tParam)
                    end
                end
            end
        end
    end
end

