--[[
-- Copyright (C), 2015, 
-- 文 件 名: FightDaerPlayer.lua
-- 作    者: lyn
-- 版    本: V1.0.0
-- 创建日期: 2016-12-27
-- 完成日期: 
-- 功能描述: 
-- 其它相关: 
-- 修改记录: 
--]]

-- 日志文件名
local LOG_FILE_NAME = 'CFightDaerPlayer.lua.log'

require "script.Entity.FightPlayerBase"

CFightDaerPlayer = class('CFightDaerManager', CFightPlayerBase)

function CFightDaerPlayer:New()
    local o = CFightBase:New()
    setmetatable(o, CFightDaerManager)
    return o
end

function CFightDaerPlayer:Init(msg)
    CFightDaerPlayer.super.init(self, msg)
end


-- 设置托管
function CFightDaerPlayer:SetTuoGuan(bTuoguan)
    self.m_bTuoGuan = bTuoguan or false
end

-- 是否处于托管
function CFightDaerPlayer:IsTuoGuan()
    return self.m_bTuoGuan or false
end

-- 是否是庄
function CFightDaerPlayer:IsZhuang()
    return self.m_bZhuang
end

-- 是否是报
function CFightDaerPlayer:IsBao()
    return self.m_bBaoPai or false
end

-- 设置庄
function CFightDaerPlayer:SetZhuang(bZhuang)
    self.m_bZhuang = bZhuang or false
end

-- 设置报
function CFightDaerPlayer:SetBao(bBao)
    self.m_bBaoPai = bBao or false
end