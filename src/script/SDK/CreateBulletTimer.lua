require "script/SDK/TimerEvent"

CCreateBulletTimer = class("CCreateBulletTimer", CTimerEvent)
CCreateBulletTimer.type = "CCreateBulletTimer"

function CCreateBulletTimer:New(o)

    o = CTimerEvent:New(o)
    setmetatable(o, CCreateBulletTimer)
    o.m_nAttackerID = 0    -- 攻击者ID
    o.m_nTargetID   = 0    -- 目标ID
    o.m_nSkillID    = 0    -- 技能ID
    o.m_bBulletPath = false
    o.m_nRefTargetID= 0    -- 参考点ID
    o.m_fTime       = 0
    return o
end

function CCreateBulletTimer:SetData(nAttackerID, nTargetID, nSkillID, bBulletPath, nRefTargetID, fDelay)
    self.m_nAttackerID = nAttackerID
    self.m_nTargetID = nTargetID
    self.m_nSkillID = nSkillID
    self.m_bBulletPath = bBulletPath
    self.m_nRefTargetID = nRefTargetID

    self:TimerEventByDelay(1, fDelay)
end

--获取弹道存在时间
function CCreateBulletTimer:GetTotalTime()
    local attacker = CEntityManager:GetInstance():GetEntity(self.m_nAttackerID)
    local pTarget  = CEntityManager:GetInstance():GetEntity(self.m_nTargetID)
    if not attacker or not pTarget then
        return 0
    end
    if (q_skill.GetTempData(self.m_nSkillID, "q_enemy_action") or 0) == CSkill.ESelectTargetType.ETYPE_COUNT then
        self.m_fTime = (math.abs(attacker:GetTileX() - pTarget:GetTileX()) + math.abs(attacker:GetTileY() - pTarget:GetTileY())) / q_skill.GetTempData(self.m_nSkillID, "q_trajectory_speed") or 1
    elseif (q_skill.GetTempData(self.m_nSkillID, "q_enemy_action") or 0) == CSkill.ESelectTargetType.ETYPE_RANGE then
        self.m_fTime = math.abs(attacker:GetPixelX() - pTarget:GetPixelX())/(q_skill.GetTempData(self.m_nSkillID, "q_trajectory_speed") or 1)
    end
    return self.m_fTime
end

--弹道行动
function CCreateBulletTimer:Action()
    CTimerEvent.Action(self)
    
    local pAttacker = CEntityManager:GetInstance():GetEntity(self.m_nAttackerID) -- 获取攻击者
    local pTarget = CEntityManager:GetInstance():GetEntity(self.m_nTargetID)     -- 获取目标
    if not pAttacker or pAttacker:IsDead() or not pTarget or pTarget:IsDead() then
        return
    end

    local pSkill = pAttacker:GetSkillByModelID(self.m_nSkillID) -- 获取技能
    if not pSkill then
        log_error("CCreateBulletTimer.log", "Action the pAttacker not has the skill of nSkillID = " .. self.m_nSkillID)
        return
    end

    local pSkillTmp = pSkill:GetSkillData() -- 获取技能模板数据
    if not pSkillTmp then
        log_error("CCreateBulletTimer.log", "Action the skill template data is not exist nSkillID = " .. self.m_nSkillID)
        return
    end

    local sEffect = q_skill.GetTempData(self.m_nSkillID, "q_trajectory_effect") or ""
    local nSpeed  = q_skill.GetTempData(self.m_nSkillID, "q_trajectory_speed") or 1
    local nAction = q_skill.GetTempData(self.m_nSkillID, "q_enemy_action") or 0

    -- 创建打人的子弹
    if nAction == CSkill.ESelectTargetType.ETYPE_COUNT then
        if pSkill:GetModelID() == 171 then
            self:CreateStretch(pAttacker, pTarget, pSkillTmp, pSkill)   --周瑜
            do return end
        end
        local bullet = CBulletBase:New(self.m_nAttackerID, self.m_nTargetID, sEffect, nSpeed, self.m_bBulletPath, self.m_nSkillID, self.m_nRefTargetID)
        if bullet then
            CEntityManager:GetInstance():AddEntity(bullet)
            local bullerOrbit = CBulletActivity:New(bullet)
            bullet:DoActivity(bullerOrbit)
        end
    -- 创建打地块的子弹
    elseif nAction == CSkill.ESelectTargetType.ETYPE_RANGE then
        local tbTargetList = pSkill:GetRealTarget(CSkill.EEffectActionType.ETYPE_ENEMY, self.m_nTargetID, nil, self.m_nAttackerID)
        local nX, nY = pSkill:ExecuteEffectPosition(tbTargetList)
        self.m_fTime = math.abs(pAttacker:GetPixelX() - nX) / nSpeed
        if not IsGameServer then
            local nMirror = 0
            if pAttacker:GetPixelX() > nX then
                nMirror = 1
            end
            local arg = PackEffectArg(nMirror, pAttacker:GetPixelX(), pAttacker:GetPixelY(), nX, nY)
            local tbEffect = StrSplit(sEffect, ";")
            for i=1, #tbEffect do
                local effect = CEffectFactory:GetInstance():CreateEffect(tbEffect[i], arg)
                if effect then
                    CGameMap:GetInstance():AddChild(effect) -- 默认自动播放
                end
            end
        end
        pSkill:UseEffect(self.m_nAttackerID, self.m_nRefTargetID, nil, tonumber((q_skill.GetTempData(self.m_nSkillID, "q_delay") or 0))/1000 + self.m_fTime)
    end
end

--周瑜拉伸弹道
function CCreateBulletTimer:CreateStretch(pAttacker, pTarget, pSkillTmp, pSkill)
    if not IsGameServer then
        local arg = PackEffectArg(0, pAttacker:GetPixelX(), pAttacker:GetPixelY(), pTarget:GetPixelX(), pTarget:GetPixelY())
        local effect = CEffectFactory:GetInstance():CreateEffect(q_skill.GetTempData(self.m_nSkillID, "q_trajectory_effect") or "", arg)
        effect:retain()
        if effect then
            CGameMap:GetInstance():AddChild(effect)
            local timer1 = CCallbackTimer:New(self, {}, function()
            if pAttacker:IsDead() or pTarget:IsDead() then
                if effect then
                    effect:removeFromParent()
                    effect:release()
                    effect = nil
                end
            end end, 20, 0.2)
            gFightMgr.m_Timer:AddEvent(timer1, pSkill:IsBigSkill())
        end
    end

    local fTime = (math.abs(pAttacker:GetPixelX() - pTarget:GetPixelX()) + math.abs(pAttacker:GetPixelY() - pTarget:GetPixelY())) / (q_skill.GetTempData(self.m_nSkillID, "q_trajectory_speed") or 1)
    local timer= CCallbackTimer:New(self, {aniEffect=effect}, function(param)
        pSkill:UseEffect(self.m_nAttackerID, self.m_nRefTargetID, self.m_nTargetID)
        if param.aniEffect then
            param.aniEffect:removeFromParent()
            param.aniEffect:release()
            param.aniEffect = nil
        end
    end, 1, fTime)
    gFightMgr.m_Timer:AddEvent(timer, pSkill:IsBigSkill())
end

return CCreateBulletTimer