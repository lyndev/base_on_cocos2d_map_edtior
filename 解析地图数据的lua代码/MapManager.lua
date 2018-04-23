-- [[
-- Copyright (C), 2015, 
-- 文 件 名: CMapManager.lua
-- 作    者: lyn
-- 版    本: V1.0.0
-- 创建日期: 2015-12-29
-- 完成日期: 
-- 功能描述: 地图加载管理器
-- 其它相关: 
-- 修改记录: 
-- ]]

-- 日志文件名
local LOG_FILE_NAME = 'CMapManager.log'

require "script.Map.MapBase"

CMapManager= {}
CMapManager.__index = CMapManager
CMapManager._instance = nil

local MAP_BREAK_ELEMENT_PLIST = "map/map_res/map_elments2.plist"

function CMapManager:New()
    local o = {}
    o.m_pCurMap                 = nil           -- 当前地图对象
    o.m_tMapAlreadyReplaceTile  = {}            -- 已经替换显示的体块
    o.m_tHurtTileSprite         = {}
    o.m_tCampTile               = {}            -- 阵营地块
    o.m_tElementCollision       = {}            -- 元素碰撞块坐标
    o.m_tElementsShadow         = {}            -- 元素的影子(元素的影子)
    setmetatable( o, CMapManager )
    return o
end

function CMapManager:GetInstance( msg )
    if not CMapManager._instance then
        CMapManager._instance = self:New()
    end
    return  CMapManager._instance
end

--[[
-- 函数类型: public
-- 函数功能: 初始化
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CMapManager:Init(param)

    self.m_pMapRootLayer           = cc.Layer:create()
    self.m_pMapBottomLayer         = cc.Layer:create()
    self.m_pMapTopLayer            = cc.Layer:create()
    self.m_pMapTopBreakLayer       = cc.Layer:create()
    self.m_pMoveLayer              = cc.Layer:create()
    self.m_pTouchLayer             = cc.Layer:create() 
    
    self.m_pMapRootLayer:addChild(self.m_pMapBottomLayer, 1)   -- 底层
    self.m_pMapRootLayer:addChild(self.m_pMapTopLayer, 5)      -- 顶层
    self.m_pMapRootLayer:addChild(self.m_pMapTopBreakLayer, 6) -- 顶层受损层
    self.m_pMapRootLayer:addChild(self.m_pMoveLayer, 7)        -- 移动层
    self.m_pMapRootLayer:addChild(self.m_pTouchLayer, 8)       -- 触摸层
    GameScene:GetSceneLayer():addChild(self.m_pMapRootLayer)

    -- 加载受损显示的元素图集
    CPlistCache:GetInstance():RetainPlist(MAP_BREAK_ELEMENT_PLIST)

    local listener = cc.EventListenerTouchOneByOne:create()  

    -- 注册两个回调监听方法  
    local function onTouchBegan( touch, event)
        return true
    end

    local function onTouchMoved( touch, event )
        local _dif = touch:getDelta()
        local _posX, _posY = self.m_pMapRootLayer:getPositionX(), self.m_pMapRootLayer:getPositionY()
        self.m_pMapRootLayer:setPosition(cc.p(_posX + _dif.x, _posY + _dif.y))
    end

    listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN )  

    -- 时间派发器 
    local eventDispatcher = self.m_pTouchLayer:getEventDispatcher() 

    -- 吞并事件
    listener:setSwallowTouches(true)

    -- 绑定触摸事件到层当中  
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self.m_pTouchLayer) 

end

--[[
-- 函数类型: public
-- 函数功能: 根据ID加载地图
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CMapManager:LoadMapByID(mapTemplateID)
    -- 初始化地图
    local _mapPath = Q_Map.GetTempData(mapTemplateID, 'q_tmx')
    if _mapPath ~= '' then
        self:LoadMapByName(_mapPath, mapTemplateID)        
    else
        log_error(LOG_FILE_NAME, '添加地图到场景失败,地图加载失败了!加载路径:%s', _mapPath)
    end
end

--[[
-- 函数类型: public
-- 函数功能: 通过地图路径加载地图
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CMapManager:LoadMapByName( path, mapID )
    -- 注明: 不能用ccexp 创建，不然使用块坐标获取不了地块
    local _pMap = cc.TMXTiledMap:create(path) --ccexp.TMXTiledMap:create('map/map.tmx') 
    if _pMap then 
        self.m_pCurMap = _pMap
        self:LoadObjectLayerElements(_pMap, mapID)
        self:AddToMapTopLayer(_pMap)
        local _collison =  _pMap:getLayer('map_collision')
        if _collison then
            _collison:setVisible(false)
        else
            log_error(LOG_FILE_NAME, "当期地图的碰撞图层没找到！")
        end
    else
        log_error(LOG_FILE_NAME, '添加地图到场景失败,地图加载失败了!加载路径:%s', _mapPath)
    end
end

--[[
-- 函数类型: public
-- 函数功能: 加载对象层元素
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CMapManager:LoadObjectLayerElements( pMap, mapID )
    self.m_tElements = {}
    local _mapLua = require( Q_Map.GetTempData(mapID, 'q_lua'))
    local _layers = _mapLua.layers
    local tObject = {}

    -- 对象层
    for i,v in pairs(_layers) do
        if v.type == "objectgroup" then
           table.insert(tObject, v)
        end
    end

    -- 对象层的元素
    self.m_mapElTable = {}
    for i, v in pairs(tObject) do
        local objects =  v.objects

        -- 是否加入数组管理地块
        local _bJionArray = true
        local _bBackElement = false
        local _bShadow = false
        
        -- 是否背景层
        if v.name == 'background_elements' then
            _bJionArray = false
            _bBackElement = true
        end

        -- 把同元素的图片归类到一个table(同类元素必须同时创建才能auto-batch)
        for i, v in pairs(objects) do
            local _gid = v.gid 
            local _gidInfo = pMap:getPropertiesForGID(_gid)
            if type(_gidInfo) == 'table' then
                local _configID = tonumber(_gidInfo.Elementid) or 0
                if not self.m_mapElTable[_configID] then
                    self.m_mapElTable[_configID] = {}
                end
                v.bJionArray = _bJionArray
                v.bBackElement = _bBackElement
                table.insert(self.m_mapElTable[_configID], v)
            end
        end
    end

    -- 创建地块
    local _mapH = self:GetMapRect().height
    local _mapTileHight = self:GetMapSize().height
    local _count = 0
    self.m_backElementBatchNodeList = {}
    for configID, sameTileTable in pairs(self.m_mapElTable) do
        local _spritePng = Q_MapElement.GetTempData(configID, "q_picture_id")
        for k, tileInfo in pairs(sameTileTable) do
            self:CreateElements(configID, tileInfo, _mapH, _spritePng)
            _count = _count + 1
        end
    end

end

--[[
-- 函数类型: public
-- 函数功能: 创建对象层的对象
-- 参数[IN]: 对象table, 是否加入地块数组中管理
-- 返 回 值: 无
-- 备    注:
--]]
function CMapManager:CreateElements( configID, tileInfo, mapH, png )
    if tileInfo then
        if png then
            local _texture = display.getImage("map/map_res/"..png)
            if not _texture then
                _texture = display.loadImage("map/map_res/"..png)
                if not _texture then
                    log_error(LOG_FILE_NAME, '加载地图元素图片失败:%d', configID)
                    return
                end
            end
            local _sprite = display.newSprite(_texture)
            local _configPosX = tonumber(tileInfo.x)
            local _configPosY = tonumber(tileInfo.y)
            local _posX = _configPosX
            local _posY = mapH - _configPosY

            _sprite:setAnchorPoint(cc.p(0, 0))
            _sprite:setPosition(_posX, _posY)

            local _tileX = math.floor(_configPosX / 32)
            local _tileY = math.floor(_configPosY / 32) - 1
            if tileInfo.bJionArray then
                if not self.m_tElements[_tileX] then
                    self.m_tElements[_tileX] = {}
                end
                self.m_tElements[_tileX][_tileY] = { sprite = _sprite, configID = configID, shadowSprite = false }
                
                -- 加入阵营列表的地块
                local _camp = Q_MapElement.GetTempData(configID, "q_camp")
                if _camp == ENUM.ENTITY_CAMP.RED or _camp == ENUM.ENTITY_CAMP.BLUE then
                    local _collsionWidth = Q_MapElement.GetTempData(configID, "q_obj_width")   --  x
                    local _collsionHeight = Q_MapElement.GetTempData(configID, "q_obj_height") --  y
                    local _startTileY = _tileY - _collsionHeight + 1
                    for x = _tileX, _tileX + _collsionWidth  do
                        for y = _startTileY, _tileY do
                            if not self.m_tCampTile[x] then
                                self.m_tCampTile[x] = {}
                            end
                            self.m_tCampTile[x][y] = _camp
                        end
                    end
                end

                -- 可阻挡子弹
                local _ispenetration = Q_MapElement.GetTempData(configID, "q_ispenetration")
                if _ispenetration == 1 then
                    local _collsionWidth = Q_MapElement.GetTempData(configID, "q_obj_width")   --  x
                    local _collsionHeight = Q_MapElement.GetTempData(configID, "q_obj_height") --  y
                    local _startTileY = _tileY - _collsionHeight + 1
                    for x = _tileX, _tileX + _collsionWidth  do
                        for y = _startTileY, _tileY do

                            -- 加入元素碰撞地块
                            if not self.m_tElementCollision[x] then
                                self.m_tElementCollision[x] = {}
                            end
                            self.m_tElementCollision[x][y] = true
                        end
                    end
                end

                -- 是否遮挡坦克
                local _shade = Q_MapElement.GetTempData(configID, "q_shade")
                if _shade == 1 then 
                    _sprite:setLocalZOrder(300 + _tileY)
                else
                    _sprite:setLocalZOrder(_tileY)
                end

                -- 是否显示
                local _visible = Q_MapElement.GetTempData(configID, "q_visible")
                if _visible == 1 then
                    _sprite:hide()
                end

                -- 是否加影子
                local _shadowPath = Q_MapElement.GetTempData(configID, "q_shadow_id")
                if _shadowPath and _shadowPath ~= '0' and _shadowPath ~= '' then
                    local _shadowTexture = display.getImage("map/map_res/".._shadowPath)
                    if not _shadowTexture then
                        _shadowTexture = display.loadImage("map/map_res/".._shadowPath)
                    end
                    if _shadowTexture then
                        local _shadowSprite = display.newSprite(_shadowTexture)

                        -- 影子元素使用spritebatchnode创建(极大的提高帧率)
                        if not self.m_tElementsShadow[configID] then
                            self.m_tElementsShadow[configID] = cc.SpriteBatchNode:create("map/map_res/".._shadowPath)
                            self.m_tElementsShadow[configID]:setLocalZOrder(2)
                            self:AddToMapTopLayer(self.m_tElementsShadow[configID])
                        end

                        -- 影子锚点和偏移值
                         local _strOffset = Q_MapElement.GetTempData(configID, "q_shadow_offset")
                         _strOffset = StrSplit(_strOffset, "|")
                         local _anchor = StrSplit(_strOffset[1] or "0_0", "_")
                         _anchor = TableValueToNumber(_anchor)
                         local _offest = StrSplit(_strOffset[2] or "10_-10", "_")
                         _offest = TableValueToNumber(_offest)
                        _shadowSprite:setAnchorPoint(cc.p(_anchor[1], _anchor[2]))
                        _shadowSprite:setPosition(_posX + _offest[1], _posY + _offest[2])
                        
                        _shadowSprite:setLocalZOrder(_tileY)
                        self.m_tElements[_tileX][_tileY].shadowSprite = _shadowSprite

                        -- 加入地图
                        --self:AddToMapTopLayer(_shadowSprite)
                        self.m_tElementsShadow[configID]:addChild(_shadowSprite)
                    end
                end

            else
                _sprite:setLocalZOrder(1)
            end

            if not tileInfo.bBackElement then

                -- 加入地图
                self:AddToMapTopLayer(_sprite)
            else

                -- 背景层元素使用spritebatchnode创建(极大的提高帧率)
                if not self.m_backElementBatchNodeList[configID] then
                    self.m_backElementBatchNodeList[configID] = cc.SpriteBatchNode:create("map/map_res/"..png)
                    self.m_backElementBatchNodeList[configID]:setLocalZOrder(0)
                    self:AddToMapTopLayer(self.m_backElementBatchNodeList[configID])
                end
                self.m_backElementBatchNodeList[configID]:addChild(_sprite)
                _sprite:setLocalZOrder(0)
            end
        else
            print("没找到配置的图片id", _gidInfo.Elementid)
        end   
    end
end

--[[
-- 函数类型: public
-- 函数功能: 将普通地块替换为受损状态
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CMapManager:ReplaceHurtElement(tilePos)
    if self.m_tElements[tilePos.x] then
        local _spriteInfo = self.m_tElements[tilePos.x][tilePos.y]
        if _spriteInfo then
            local _sprite = _spriteInfo.sprite 
            if _sprite then
                
                -- 是否已经替换过了
                if self.m_tHurtTileSprite[tilePos.x] and self.m_tHurtTileSprite[tilePos.x][tilePos.y] then
                    return
                end

                local _configID = _spriteInfo.configID
                local _replacePng = Q_MapElement.GetTempData(_configID, 'q_replace_id')
                local _replaceSprite = cc.Sprite:createWithSpriteFrameName(_replacePng)
                _replaceSprite:setAnchorPoint(cc.p(0, 0))
                _sprite:hide()
                local _zOrder = _sprite:getLocalZOrder()
                local _posX = _sprite:getPositionX()
                local _posY = _sprite:getPositionY()
                _replaceSprite:setPosition(_posX, _posY)
                _replaceSprite:setLocalZOrder(_zOrder)
                _replaceSprite:setCameraMask(cc.CameraFlag.USER2)
                if not self.m_tHurtTileSprite[tilePos.x] then
                    self.m_tHurtTileSprite[tilePos.x] = {}
                end
                self.m_tHurtTileSprite[tilePos.x][tilePos.y] = _replaceSprite
                self:AddToMapTopLayer(_replaceSprite)
            end
        end
    end
end

--[[
-- 函数类型: public
-- 函数功能: 获取地块所属阵营
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CMapManager:GetTileCamp( tilePos )
    if self.m_tCampTile[tilePos.x] then
        return self.m_tCampTile[tilePos.x][tilePos.y]
    end
end

--[[
-- 函数类型: public
-- 函数功能: 获取地块是否阻碍子弹
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CMapManager:IsTileCollisionBullet(tilePos )
    if self.m_tElementCollision[tilePos.x] then
        return self.m_tElementCollision[tilePos.x][tilePos.y]
    end
end

--[[
-- 函数类型: public
-- 函数功能: 获取地块元素的信息
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CMapManager:GetTileElementInfo( tilePos )
    if self.m_tElements[tilePos.x] then
        return self.m_tElements[tilePos.x][tilePos.y]
    end
    return nil
end

--[[
-- 函数类型: public
-- 函数功能: 销毁地块
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CMapManager:DetroyTileObject( tilePos )
    self:DestroyHurtTileElements(tilePos)
    self:DestroyNormalTileElements(tilePos)
end

--[[
-- 函数类型: public
-- 函数功能: 移除碰撞地块
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CMapManager:DestroyTileCollsion( tilePos )
    -- 移除怪地块的碰撞
    local _collsionID = self:GetCollisionLayer():getTileGIDAt(tilePos)
    if _collsionID ~= 0 then
         self:GetCollisionLayer():removeTileAt(tilePos)
    end
end

--[[
-- 函数类型: public
-- 函数功能: 销毁受损地块
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CMapManager:DestroyHurtTileElements( tilePos )
    if self.m_tHurtTileSprite[tilePos.x] then
        local _hurtSprite = self.m_tHurtTileSprite[tilePos.x][tilePos.y]
        if _hurtSprite then
            _hurtSprite:removeFromParent()
            self.m_tHurtTileSprite[tilePos.x][tilePos.y] = nil
        end

        -- 移除地块影子
        if self.m_tElements[tilePos.x][tilePos.y].shadowSprite then
            self.m_tElements[tilePos.x][tilePos.y].shadowSprite:removeFromParent()
        end        
    else
        log_error(LOG_FILE_NAME, '销毁受伤地块错误，坐标不对', tilePos.x, tilePos.y)
    end
end

--[[
-- 函数类型: public
-- 函数功能: 销毁普通地块
-- 参数[IN]: 地块位置
-- 返 回 值: 无
-- 备    注:
--]]
function CMapManager:DestroyNormalTileElements( tilePos )
    local _spriteInfo = self.m_tElements[tilePos.x][tilePos.y]
    if _spriteInfo then
        local _sprite = _spriteInfo.sprite
        if _sprite then
            _sprite:removeFromParent()
            self.m_tElements[tilePos.x][tilePos.y] = nil
        end
    end
end

--[[
-- 函数类型: public
-- 函数功能: 获取地图范围
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CMapManager:GetMapRect()
    local _mapSize     = self:GetMapSize()
    local _mapTileSize = self:GetMapTileSize()
    local _width = _mapSize.width * _mapTileSize.width
    local _height = _mapSize.height * _mapTileSize.height
    self.m_maxW = _width
    self.m_maxH = _height
    return { x = 0, y = 0, width = _width, height = _height}
end

--[[
-- 函数类型: public
-- 函数功能: 边界检测
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CMapManager:ChenckBoundary(posX, posY)
    if posX > self.m_maxW then
        posX = self.m_maxW
    end

    if posY > self.m_maxW then
        posY = self.m_maxH
    end

    if posY < 0 then
        posY = 0
    end
    if posX < 0 then
        posX = 0
    end
    return posX, posY
end

--[[
-- 函数类型: public
-- 函数功能: 获取地图地块总数
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CMapManager:GetMapSize()
    if self.m_pCurMap then
        return self.m_pCurMap:getMapSize()
    end
    return cc.size(0, 0)
end

--[[
-- 函数类型: public
-- 函数功能: 获取地块地块大小
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CMapManager:GetMapTileSize()
    if self.m_pCurMap then
        return self.m_pCurMap:getTileSize()
    end
    return cc.size(0, 0)
end

--[[
-- 函数类型: public
-- 函数功能: 获取当前地块
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CMapManager:GetMap()
    return self.m_pCurMap
end

--[[
-- 函数类型: public
-- 函数功能: 后去地图根节点
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CMapManager:GetMapRootLayer()
    return self.m_pMapRootLayer
end

--[[
-- 函数类型: public
-- 函数功能: 获取地图顶层
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CMapManager:GetMapTopLayer()
    return self.m_pMapTopLayer
end

--[[
-- 函数类型: public
-- 函数功能: 获取移动层
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CMapManager:GetMoveLayer()
    return self.m_pMoveLayer
end

--[[
-- 函数类型: public
-- 函数功能: 添加到底层
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CMapManager:AddToMapBottomLayer(node)
    self.m_pMapBottomLayer:addChild(node)
end

--[[
-- 函数类型: public
-- 函数功能: 添加到移动层
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CMapManager:AddToMoveLayer(node)
    self.m_pMoveLayer:addChild(node)
end

--[[
-- 函数类型: public
-- 函数功能: 添加到顶层
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CMapManager:AddToMapTopLayer(node)
    self.m_pMapTopLayer:addChild(node)
end

--[[
-- 函数类型: public
-- 函数功能: 获取地图的碰撞图层
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CMapManager:GetCollisionLayer()
    if self.m_pCurMap then
        if self.m_pCurMap:getLayer('map_collision') then
            return self.m_pCurMap:getLayer('map_collision')
        else
            log_error(LOG_FILE_NAME, '地块的碰撞图层没有找到')
        end
    end
end

--[[
-- 函数类型: public
-- 函数功能: 地图元素替换
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CMapManager:ReplaceElements(tlieCoordinate)
    if self.m_pCurMap then
        local _children = self.m_pCurMap:getChildren()
        for k, _layer in pairs(_children) do
            if _layer then
                local _spriteID = _layer:getTileGIDAt(tlieCoordinate)
                if _spriteID ~= 0  then

                    -- 建立第一维索引
                    if not self.m_tMapAlreadyReplaceTile[tlieCoordinate.x] then
                        self.m_tMapAlreadyReplaceTile[tlieCoordinate.x] = {}
                    end

                    if not self.m_tMapAlreadyReplaceTile[tlieCoordinate.x][tlieCoordinate.y] then

                        -- 建立第二维索引
                        self.m_tMapAlreadyReplaceTile[tlieCoordinate.x][tlieCoordinate.y] = true

                        -- 获取地块属性
                        local info = self.m_pCurMap:getPropertiesForGID(_spriteID)
                        if info then
            
                            local _elementConfigID = info["Elementid"]
                            if  _elementConfigID then
                                _elementConfigID = tonumber(_elementConfigID)

                                -- 替换块的显示
                                local _breakShowPng = Q_MapElement.GetTempData(_elementConfigID, 'q_replace_id')
                                self:AddBreakShowElements( tlieCoordinate, _breakShowPng)

                                -- 隐藏原来的地块
                                local _coorDinateSprite = _layer:getTileAt(tlieCoordinate)
                                if _coorDinateSprite then
                                    _coorDinateSprite:hide()
                                end
                                return
                            else
                                log_error(LOG_FILE_NAME, "地块的替换类型没配置,请检查地图配置")
                                return
                            end
                        end
                    else
                        log_info(LOG_FILE_NAME, "这个地块已经替换过了%d, %d", tlieCoordinate.x, tlieCoordinate.y)
                    end
                end
            else
                log_error(LOG_FILE_NAME, "好替换的地块的图层没找到！")
            end
        end
    else
        log_error(LOG_FILE_NAME, "顶层地图不存在！")
    end
end

--[[
-- 函数类型: public
-- 函数功能: 替换受损状态的元素显示
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CMapManager:AddBreakShowElements(tlieCoordinate, breakPng)
    assert(tlieCoordinate)
    local _sprite   = cc.Sprite:createWithSpriteFrameName(breakPng)
    if _sprite then
        local _tileSize = self:GetMapTileSize()
        local _mapTileCount = self:GetMapSize()
        self:AddToMapTopLayer(_sprite)
        local _posX, _posY = tlieCoordinate.x * _tileSize.width, (_mapTileCount.height - 1 - tlieCoordinate.y) * _tileSize.width

        _sprite:setPosition(_posX, _posY)
        _sprite:setAnchorPoint(cc.p(0,0))

        -- 加入管理便于移除
        if not self.m_tBreakShowMap then
            self.m_tBreakShowMap = {}
        end
        if not self.m_tBreakShowMap[tlieCoordinate.x] then
            self.m_tBreakShowMap[tlieCoordinate.x] = {}
        end

        -- x和y建立一个二维数组的key
        self.m_tBreakShowMap[tlieCoordinate.x][tlieCoordinate.y] = _sprite

    end 
end

--[[
-- 函数类型: public
-- 函数功能: 移除替换过的某个元素
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CMapManager:RemoveReplaceElements(tlieCoordinate)
    if self.m_tBreakShowMap then
        if self.m_tBreakShowMap[tlieCoordinate.x] then
            local _sprite = self.m_tBreakShowMap[tlieCoordinate.x][tlieCoordinate.y]
            if _sprite then
                _sprite:removeFromParent()
                self.m_tBreakShowMap[tlieCoordinate.x][tlieCoordinate.y] = nil
            else
                log_error(LOG_FILE_NAME, "移除的元素不存在, 坐标:%d, %d", tlieCoordinate.x, tlieCoordinate.y )
            end
        end
    end
end

--[[
-- 函数类型: public
-- 函数功能: 销毁地块
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CMapManager:DestoryElements( tlieCoordinate )
    if self.m_pCurMap then
        local _children = self.m_pCurMap:getChildren()
        for k, _layer in pairs(_children) do
            if _layer then
                
                local _spriteID = _layer:getTileGIDAt(tlieCoordinate)
                if _spriteID ~= 0 then
                    
                    -- 移除显示的地块
                    _layer:removeTileAt(tlieCoordinate)
                    
                    -- 移除怪地块的碰撞
                    local _collsionID = self:GetCollisionLayer():getTileGIDAt(tlieCoordinate)
                    if _collsionID ~= 0 then
                        self:GetCollisionLayer():removeTileAt(tlieCoordinate)
                    end
                end
            end
        end
    end
end

--[[
-- 函数类型: public
-- 函数功能: 位置转换为地块坐标
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注: 因为精灵的坐标是从左下角开始计算，而瓦块的坐标是从左上角开始计算的所以我们需要通过这个函数将精灵坐标转化为瓦块需要的坐标。
--]]
function CMapManager:GetTileCoordinateByPosition(pos)  
    if self.m_pCurMap then
        local mapTiledNum = self.m_pCurMap:getMapSize() 
        local tiledSize = self.m_pCurMap:getTileSize() 
        
        -- 转换为瓦块的个数横坐标   
        local tile_x = pos.x / tiledSize.width

        -- 转换为瓦块的个数纵坐标  
        local tile_y = (tiledSize.height * mapTiledNum.height - pos.y) / tiledSize.height 
        
        return cc.p( math.floor(tile_x), math.floor(tile_y))
    else
        log_error(LOG_FILE_NAME, '转化地块坐标失败, 地图数据没找到')
    end
end

--[[
-- 函数类型: public
-- 函数功能: 地块坐标转换为位置坐标
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CMapManager:ConvertTileCoordinateToPixel(pos)  
    if pos then
        if self.m_pCurMap then
            local mapTiledNum = self.m_pCurMap:getMapSize()
            local y = mapTiledNum.height - pos.y 
             
            local _mapTileSize = self.m_pCurMap:getTileSize()
            local _posX = pos.x * _mapTileSize.width
            local _posY = y * _mapTileSize.width 
            return _posX, _posY
        else
            log_error(LOG_FILE_NAME, '当前没有地图, 转换为位置坐标失败')
        end
    else
        log_error(LOG_FILE_NAME, '传入的坐标错误')
    end
end

--[[
-- 函数类型: public
-- 函数功能: 销毁
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CMapManager:Destroy()
    -- 移除事件
    gPublicDispatcher:RemoveEventListenerObj(self)

    CPlistCache:GetInstance():ReleasePlist(MAP_BREAK_ELEMENT_PLIST)

    if self.m_pCurBottomMap then
        self.m_pCurBottomMap:Destroy()
    end

    if self.m_pCurMap then
        self.m_pCurMap:removeFromParent()
        self.m_pCurMap = nil
    end
    
    if  self.m_pBatchNodeBreakShow then
        self.m_pBatchNodeBreakShow:removeFromParent()
    end
    
    if  self.m_pMapBottomLayer then
        self.m_pMapBottomLayer:removeFromParent()
    end
    
    if  self.m_pMoveLayer then
        self.m_pMoveLayer:removeFromParent()
    end
    
    if self.m_pMapTopLayer then
        self.m_pMapTopLayer:removeFromParent()
    end

    if self.m_pMapTopBreakLayer then
        self.m_pMapTopBreakLayer:removeFromParent()
    end
    if self.m_pMapRootLayer then
        self.m_pMapRootLayer:removeFromParent()
        self.m_pMapRootLayer = nil
    end

    self.m_pBatchNodeBreakShow    = nil
    self.m_pMapBottomLayer        = nil
    self.m_pMoveLayer             = nil
    self.m_pMapTopLayer           = nil
    self.m_pMapTopBreakLayer      = nil
    self.m_pCurMap                = nil
    self.m_tElements              = nil
    self.m_tCampTile              = nil
    self.m_tElementCollision      = {}
    self.m_tMapAlreadyReplaceTile = {}
    self.m_tHurtTileSprite        = {}
    self.m_tCampTile              = {}
    self.m_tElementsShadow        = {}

   	CMapManager._instance = nil
end