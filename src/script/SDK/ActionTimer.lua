require "script/SDK/SkillTimer"
require "script/SDK/BulletTimer"
require "script/SDK/EffectTimer"
CActionTimer = class("CActionTimer", CSkillTimer)
CActionTimer.type = "CActionTimer"
local LOG_FILE_NAME = "CActionTimer.log"

function CActionTimer:New(o)

    o = CSkillTimer:New(o)
    setmetatable(o, CActionTimer)
    o.m_nAttackerID = 0       --攻击者ID
    o.m_nCurRefTargetID = 0      --参考目标
    o.m_nSkillID = 0            --技能ID
    o.m_bIsActionTimer = true   --标识是动作匹配延迟Timer
    return o
end

--功能: 初始化动作匹配延迟Timer数据
--参数: nAttackerID:攻击者ID, nCurRefTargetID:参考目标, Skill:当前使用技能, nDelay:延迟时间
--返回: 无
--备注: 
function CActionTimer:SetActionData(nAttackerID, nCurRefTargetID, Skill, nDelay)
    if not Skill then
        log_error(LOG_FILE_NAME, "SetActionData Skill is nil")
        return
    end
    self.m_nAttackerID = nAttackerID
    self.m_nCurRefTargetID = nCurRefTargetID
    self.m_Skill = Skill
    local skillData = self.m_Skill:GetSkillData()
    if skillData[q_skill_index.q_break_type] == CSkill.EBreakType.ETYPE_CANTBREAK then
        self.m_bCanBreak = false
    end
    self:AddListener(self.m_nAttackerID)
    self:TimerEventByDelay(1, nDelay)   --设置定时器信息
end

function CActionTimer:Action()
    CSkillTimer.Action(self)
    local skillData = self.m_Skill:GetSkillData()
    --检查技能是否被打断
    if self.m_bCanBreak then
        if skillData[q_skill_index.q_break_type] == CSkill.EBreakType.ETYPE_ACTIONTIME then
            self.m_bCanBreak = false
        elseif skillData[q_skill_index.q_break_type] == CSkill.EBreakType.ETYPE_ALLTIME then
            self.m_bCanBreak = true
        end
    end
    local attacker = CEntityManager:GetEntity(self.m_nAttackerID)
    attacker:CreateEffect(self.m_nCurRefTargetID, self.m_Skill, self.m_bCanBreak)
end