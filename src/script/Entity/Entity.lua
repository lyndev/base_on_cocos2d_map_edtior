-- [[
-- Copyright (C), 2015, 
-- 文 件 名: Entity.lua
-- 作    者: lyn
-- 版    本: V1.0.0
-- 创建日期: 2016-01-08
-- 完成日期: 
-- 功能描述: 游戏实体
-- 其它相关: 
-- 修改记录: 
-- ]]

-- 日志文件名
local LOG_FILE_NAME = 'CEntity.log'

require "script.Entity.Template"

CEntity = class("CEntity", CTemplate)

function CEntity:New()
    local o = CTemplate:New()
    setmetatable( o, CEntity )
    o.m_nEntityID           = IDMaker.GetID()              -- ID生成器生成ID
    o.m_nServerID           = 0
    o.m_curDirection        = ENUM.EDirection.Up
    o.m_pLogicNode          = cc.Node:create()              -- 实体逻辑节点
    o.m_posX                = 0
    o.m_posY                = 0
    o.m_nCurTileX           = 0
    o.m_nCurTileY           = 0
    o.m_nLastTileX          = 0
    o.m_nLastTileY          = 0
    o.m_partOfRoleID        = 0              -- 所属实体ID
    -- 逻辑节点加入到移动层
    CMapManager:GetInstance():GetMoveLayer():addChild(o.m_pLogicNode)
    return o
end

function CEntity:SetPartOfRoleID( roleID )
    self.m_partOfEffectID = effectID or 0
end

function CEntity:GetPartOfRoleID()
    return self.m_partOfEffectID
end

function CEntity:GetEntityID()
    return self.m_nEntityID
end

function CEntity:GetServerID()
    return self.m_nServerID
end

function CEntity:SetServerID( id )
    self.m_nServerID = id
end

function CEntity:GetDirection()
    return self.m_curDirection
end

function CEntity:GetLogicNode()
    return self.m_pLogicNode
end

function CEntity:SetDirection( direction )
    if direction ~= self.m_curDirection then
        self.m_curDirection = direction
        
        -- 设置显示方向
        if self["SetShowDirection"] then
            self:SetShowDirection(direction)
        end
    end
end

function CEntity:GetTileCoordinate()
    return self.m_nCurTileX, self.m_nCurTileY
end

function CEntity:SetTileCoordinate( tileX,tileY )
   self.m_nCurTileX = tileX
   self.m_nCurTileY = tileY
end

function CEntity:SetLastTileCoordinate(tileX, tileY)
    self.m_nLastTileX = tileX
    self.m_nLastTileY = tileY
end

function CEntity:GetLastTileCoordinate()
    return self.m_nLastTileX,self.m_nLastTileY
end


function CEntity:GetPosition()

    return self.m_posX, self.m_posY
end

function CEntity:SetPosition( x, y )
   self.m_posX, self.m_posY = x, y

    -- 更新显示位置
    if self["SetShowPostion"] then
        self:SetShowPostion( x, y)
    end
end

function CEntity:SetPositionX(x)
    self.m_posX = x

    -- 更新快
    local _tileCoordinate = CMapManager:GetInstance():GetTileCoordinateByPosition(cc.p(self:GetPositionX(),
       self:GetPositionY()))

    self:SetTileCoordinate(_tileCoordinate.x, self.m_nCurTileY)

    -- 更新显示位置
    if self["SetShowPostionX"] then
        self:SetShowPostionX( x )
    end
end

function CEntity:SetPositionY( y )
    self.m_posY = y

    -- 更新快
    local _tileCoordinate = CMapManager:GetInstance():GetTileCoordinateByPosition(cc.p(self:GetPositionX(),
       self:GetPositionY()))
    
    self:SetTileCoordinate(self.m_nCurTileX, _tileCoordinate.y)

    -- 更新显示位置
    if self["SetShowPostionY"] then
        self:SetShowPostionY(y)
    end
end

function CEntity:SetContentSize(size)
    self.m_pLogicNode:setContentSize(size)
end

function CEntity:GetBoundingBoxWidth()
    if self.m_pLogicNode then
        return  self.m_pLogicNode:getBoundingBox().width
    else
        return 0
    end
end

function CEntity:GetBoundingBoxHeight()
    if self.m_pLogicNode then
        return  self.m_pLogicNode:getBoundingBox().height
    else
        return 0
    end 
end


function CEntity:GetPositionX( )
    return self.m_posX
end

function CEntity:GetPositionY( )
    return self.m_posY
end

function CEntity:GetState()
    return self.m_nState
end

function CEntity:SetState( type )
    self.m_nState = type
end

function CEntity:Update( dt )
    if self.components_ then
        for k,component in pairs(self.components_) do
            if component and component["Update"] then
                component:Update(dt)
            end
        end
    end
end

function CEntity:SetLastSyncPosition(x, y)
    self.m_lastSycncX = x
    self.m_lastSycncY = y
end

function CEntity:GetLastSyncPosition()
    return self.m_lastSycncX, self.m_lastSycncY
end

function CEntity:Destroy()
    
    -- 移除组件
    if self.components_ then
        for name, v in pairs(self.components_) do
            self:RemoveComponent(name)
        end
    end

    -- 移除逻辑节点
    if self.m_pLogicNode then
        self.m_pLogicNode:removeFromParent()
    end
    self.m_pLogicNode = nil
end  