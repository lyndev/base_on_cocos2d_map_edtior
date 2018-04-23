--[[
-- Copyright (C), 2016, 
-- 文 件 名: UINoticeForCenterManager.lua
-- 作    者: 
-- 版    本: V1.0.0
-- 创建日期: 2016-03-3
-- 完成日期: 
-- 功能描述:管理提示框
-- 其它相关: 
-- 修改记录: 
--]]

-- 日志文件名
local LOG_FILE_NAME = 'CUINoticeForCenterManager.log'

CUINoticeForCenterManager = {}
CUINoticeForCenterManager.__index = CUINoticeForCenterManager 
CUINoticeForCenterManager._instance = nil


function CUINoticeForCenterManager:New()
    local o = {}
    o.m_bCreateNoticeUi  = false
    setmetatable( o, CUINoticeForCenterManager )
    return o
end

--[[
-- 函数类型: public
-- 函数功能: 得到单例
-- 参    数: 
-- 返 回 值: 返回单例
-- 备    注:
-- ]]
function CUINoticeForCenterManager:GetInstance()
    if not CUINoticeForCenterManager._instance then
        CUINoticeForCenterManager._instance = self:New()
    end
    return  CUINoticeForCenterManager._instance
end

--[[
-- 函数类型: public
-- 函数功能: 打开提示UI
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CUINoticeForCenterManager:ShowNotice( data )
	OpenUI("CUITipsNoticeForCenter", nil, {noticeData = data})
end

-- [[
-- 函数类型: private
-- 函数功能: 销毁单例
-- 参    数: 无
-- 返 回 值: 
-- 备    注:
-- ]]
function CResCachePoolManager:Destroy()
    CUINoticeForCenterManager._instance = nil
end

