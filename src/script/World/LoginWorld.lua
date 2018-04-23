-- [[
-- Copyright (C), 2015, 
-- 文 件 名: UILogin.lua
-- 作    者: lyn
-- 版    本: V1.0.0
-- 创建日期: 2015-12-22
-- 完成日期: 
-- 功能描述: 登录世界
-- 其它相关: 
-- 修改记录: 
-- ]]

local LOG_FILE_NAME = "CLoginWorld.lua"

require "script.Login.LoginLogic"

CLoginWorld = class("CLoginWorld", CWorld)

function CLoginWorld:New()
    local o = {}
    setmetatable(o, CLoginWorld)
    o.m_pLoginLogic = CLoginLogic:New()
    return o
end

--[[
函数原型: Init()
功    能: 登录世界初始化
参    数: 无
返 回 值: true/false
--]]
function CLoginWorld:Init()
    CLuaLogic.m_ServerIp = nil
    CMsgRegister.ClearMsgList()
    
    CLoginLogic:GetInstance():Init()
    return true
end

function CLoginWorld:GetName()
    return "LoginWorld"
end

function CLoginWorld:Update(dt)
    
    -- 登录逻辑更新
    CLoginLogic:GetInstance():Update(dt)

    -- UI管理器
    CUIManager:GetInstance():Update(dt)
    
    CPlayer:GetInstance():Update(dt)
end

function CLoginWorld:Destroy()
    
    -- 释放
    CLoginLogic:GetInstance():Destroy()
    
    -- 关闭所有UI
    CUIManager:GetInstance():Destroy()

    -- 释放一次未使用的资源
    display.removeUnusedSpriteFrames()
end

function CLoginWorld:MessageProc(nMsgID, pData, nLen)

    CLoginLogic:GetInstance():MessageProc(nMsgID, pData, nLen)

end

function CLoginWorld:ccTouchBegan(touch, event)

end

function CLoginWorld:ccTouchEnded(touch, event)

end

function CLoginWorld:ccTouchMoved(touch, event)

end

function CLoginWorld:ccTouchCancelled(touch, event)

end