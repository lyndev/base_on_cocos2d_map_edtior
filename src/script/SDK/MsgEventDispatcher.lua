--[[
-- Copyright (C), 2015, 
-- 文 件 名: MsgEventDispatcher.lua
-- 作    者: lyn
-- 版    本: V1.0.0
-- 创建日期: 2016-07-18
-- 完成日期: 
-- 功能描述: 网络通信消息事件分发器
-- 其它相关: 
-- 修改记录: 
--]]

-- 日志文件名
local LOG_FILE_NAME = 'CMsgEventDispatcher.log'

CMsgEventDispatcher = class('CMsgEventDispatcher')
CMsgEventDispatcher._instance = nil

--[[
-- 函数类型: public
-- 函数功能: 构造一个CMsgEventDispatcher管理器对象
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CMsgEventDispatcher:New()
    local o = {}
    setmetatable( o, CMsgEventDispatcher )
    o.msgEvents = {}
    return o
end

--[[
-- 函数类型: public
-- 函数功能: 单例获取
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CMsgEventDispatcher:GetInstance(msg)
    if not CMsgEventDispatcher._instance then
        CMsgEventDispatcher._instance = self:New()
    end
    return  CMsgEventDispatcher._instance
end

--[[
-- 函数类型: public
-- 函数功能: add时间监听对象
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CMsgEventDispatcher:AddMsgEventListener(msgType, obj, callback)
    if type(msgType) ~= "number" or type(obj) ~= "table" or type(callback) ~= "function" then
        log_error(LOG_FILE_NAME, "CMsgEventDispatcher:AddMsgEventListener() param error:msgType=%s,obj=%s,callback=%s", msgType, type(obj), type(callback))
        return false
    end
	local _objMsgType = {}
	_objMsgType.obj = obj
	_objMsgType.callback = callback
	_objMsgType.msgType = msgType
	if not self.msgEvents[msgType] then
		self.msgEvents[msgType] = {}
	end
	table.insert(self.msgEvents[msgType], _objMsgType)
end

--[[
-- 函数类型: public
-- 函数功能: 移除对象的所有通信消息监听
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CMsgEventDispatcher:RemoveMsgEventListener(obj)
	for k, v in pairs(self.msgEvents) do
		for index, vv in pairs(v) do
			if vv.obj == obj then
				table.remove(v, index)
			end
		end
	end
end

--[[
-- 函数类型: public
-- 函数功能: 消息分发
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CMsgEventDispatcher:DispatchMsgEvent(nMsgID, pData, nLen)
	for k,v in pairs(self.msgEvents) do
		if nMsgID == k then
			for index, objMsgs in pairs(v) do
				objMsgs.callback(objMsgs.obj, nMsgID, pData, nLen)
			end	
		end
	end
end

--[[
-- 函数类型: public
-- 函数功能: 销毁(析构)
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CMsgEventDispatcher:Destroy()
	for k, v in pairs(self.msgEvents) do
		for index, vv in pairs(v) do
			table.remove(v, index)
		end
	end
	self.msgEvents = nil
    CMsgEventDispatcher._instance = nil
end

MsgEventRegister = CMsgEventDispatcher:GetInstance()