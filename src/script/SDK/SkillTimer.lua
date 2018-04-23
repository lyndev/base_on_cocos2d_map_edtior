require "script/SDK/TimerEvent"
CSkillTimer = class("CSkillTimer", CTimerEvent)
CSkillTimer.type = "CSkillTimer"
local LOG_FILE_NAME = "CSkillTimer.log"

function CSkillTimer:New(o)
    o = CTimerEvent:New(o)
    setmetatable(o, CSkillTimer)
    o.m_bCanBreak = true                --能否打断
    o.m_nEntityID = 0                   --攻击者ID
    o.m_Skill = nil                     --当前使用技能
    return o
end
--功能: 添加技能打断监听
--参数: entity:实体
--返回: 无
--备注: 
function CSkillTimer:AddListener(nAttackerID)
    local entity = CEntityManager:GetInstance():GetEntity(nAttackerID)
    if not entity then
        return
    end
    self.m_nEntityID = nAttackerID
    entity:GetEventDispatcherMgr():AddEventListener(CEvent.BreakSkill, self, self.EventHandle)
end

function CSkillTimer:Action()
    CTimerEvent.Action(self)
    if self.nLoop <= 0 then
        local entity = CEntityManager:GetInstance():GetEntity(self.m_nEntityID)
        entity:GetEventDispatcherMgr():RemoveEventListenerObj(self)
    end
end


--功能: 打断事件处理
--参数: evt:事件类
--返回: 无
--备注: 
function CSkillTimer:EventHandle(evt)
    local entity = CEntityManager:GetInstance():GetEntity(self.m_nEntityID)
    if not entity then
        return
    end
    --判断当前技能能否打断
    if self.m_bCanBreak or evt.m_bForce then
        entity:GetTimerEventMgr():RemoveEvent(self)
        entity:GetEventDispatcherMgr():RemoveEventListenerObj(self)
        --判断是否是组合技能，并设置打断标记
        local curSkill = entity:GetCurUseSkill()
        if not curSkill then
            return
        end
        local bGroupSkill = false
        local skillTmp = curSkill:GetSkillData()
        if skillTmp then
            local groupType = skillTmp[q_skill_index.q_group_type]
            if groupType == CSkill.EGroupType.ETYPE_GROUP then
                entity.m_bGroupSkillBreakFlag = true
                bGroupSkill = true
            end
        end
        local bBigSkill = false
        if bGroupSkill then
            bBigSkill = curSkill:IsBigSkill()
        else
            bBigSkill = self.m_Skill:IsBigSkill()
        end
        --处理大招在中途被打断
        if self.m_bIsActionTimer and bBigSkill then
            --如果正在放大，则缩小
            local pShow = entity.m_SpineShowObject
            if pShow then
                local action = pShow:GetShowObj():getActionByTag(1158)
                if action then
                    pShow:GetShowObj():stopAction(action)
                    pShow:GetShowObj():setScaleX(entity.m_nObjectScale)
                    pShow:GetShowObj():setScaleY(entity.m_nObjectScale)
                end
            end
            local event = CEvent:New(CEvent.UseBigSkillEnd)
            event.m_nEntityId = self.m_nEntityID
            gPublicDispatcher:DispatchEvent(event)
        end
        entity.m_bNormalSkillBreakFlag = true
        local evt = CEvent:New(CEvent.SkillUseEnd)
        evt.m_nSkillId = self.m_Skill:GetModelID()
        evt.m_nEntityId = self.m_nEntityID
        gPublicDispatcher:DispatchEvent(evt)
    end

    --不管是否打断成功,都要清除施法特效和动作
    --清除施法特效
    if entity.m_SpineShowObject then
        entity.m_SpineShowObject:RemoveBySource(ENUM.EAnimSourceType.ESource_Type_SkillCast)
    end
    --entity:SetState(ENUM.EStateType.EState_Type_Stand, ENUM.EActionID.EActionID_Stand)
    
end