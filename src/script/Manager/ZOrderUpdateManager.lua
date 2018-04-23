--[[
-- Copyright (C), 2015, 
-- 文 件 名: ZOrderUpdateManager.lua
-- 作    者: lyn
-- 版    本: V1.0.0
-- 创建日期: 2016-03-29
-- 完成日期: 
-- 功能描述: 
-- 其它相关: 
-- 修改记录: 
--]]

-- 日志文件名
local LOG_FILE_NAME = 'CZOrderUpdateManager.log'
CZOrderUpdateManager = {}
CZOrderUpdateManager.__index = CZOrderUpdateManager
CZOrderUpdateManager._instance = nil

--[[
-- 函数类型: public
-- 函数功能: 构造一个CZOrderUpdateManager管理器对象
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CZOrderUpdateManager:New()
    local o = {}
    setmetatable( o, CZOrderUpdateManager )
    o.m_tNeedUpdateEntityID = {}
    return o
end

--[[
-- 函数类型: public
-- 函数功能: 单例获取
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CZOrderUpdateManager:GetInstance( msg )
    if not CZOrderUpdateManager._instance then
        CZOrderUpdateManager._instance = self:New()
        CZOrderUpdateManager._instance:Init()
    end
    return  CZOrderUpdateManager._instance
end

--[[
-- 函数类型: public
-- 函数功能: 加入一个实体更新他的全局zorder
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CZOrderUpdateManager:AddUpdateEntitiyID( entityID )
	self.m_tNeedUpdateEntityID[entityID] = entityID 
end

--[[
-- 函数类型: public
-- 函数功能: 移除一个在更新zorder的实体
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CZOrderUpdateManager:RemoveUpdateEntityID(entityID)
	self.m_tNeedUpdateEntityID[entityID] = nil
end

--[[
-- 函数类型: public
-- 函数功能: 初始化
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CZOrderUpdateManager:Init(param)
	if GameScene then

		cc.Director:getInstance():getScheduler():scheduleScriptFunc( function( ... )
			self:UpdateZorder()
		end,0.1, false)
	end
end

--[[
-- 函数类型: public
-- 函数功能: 更新实体的全局Zorder
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CZOrderUpdateManager:UpdateZorder()
	for k, v in pairs(self.m_tNeedUpdateEntityID) do
		local _entity = CEntityManager:GetInstance():GetEntity(v)
		if _entity then
			local _show = _entity:GetShow()
			if _show then
				local _posX, _posY = _show:getPositionX(), _show:getPositionY()
				local _bodyContentSize = _entity:GetBody():getContentSize().height
				local tilePos = CMapManager:GetInstance():GetTileCoordinateByPosition(cc.p(_posX, _posY - _bodyContentSize * 0.5))
				local _mapSize = CMapManager:GetInstance():GetMapSize()
				_show:setGlobalZOrder(-(_mapSize.height - tilePos.y))
				_entity:GetBody():setGlobalZOrder(-(_mapSize.height - tilePos.y))
				_entity:GetTower():setGlobalZOrder(-(_mapSize.height - tilePos.y) + 1)
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
function CZOrderUpdateManager:Destroy()
	self.m_pRootNode:removeFromParent()
	self.m_pRootNode = nil
    -- 移除事件
    gPublicDispatcher:RemoveEventListenerObj(self)
    CZOrderUpdateManager._instance = nil
end
