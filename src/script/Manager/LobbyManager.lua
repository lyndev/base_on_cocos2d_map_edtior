--[[
-- Copyright (C), 2015, 
-- 文 件 名: LobbyManager.lua
-- 作    者: lyn
-- 版    本: V1.0.0
-- 创建日期: 2016-11-12
-- 完成日期: mm
-- 功能描述: 
-- 其它相关: 
-- 修改记录: 
--]]

-- 日志文件名
local LOG_FILE_NAME = 'CLobbyManager.lua.log'

CLobbyManager = class('CLobbyManager')
CLobbyManager._instance = nil

--[[
-- 函数类型: public
-- 函数功能: 构造一个C*管理器对象
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CLobbyManager:New()
    local o = {}
    setmetatable( o, CLobbyManager )
    return o
end

--[[
-- 函数类型: public
-- 函数功能: 单例获取
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CLobbyManager:GetInstance(msg)
    if not CLobbyManager._instance then
        CLobbyManager._instance = CLobbyManager:New()

        -- 进入房间列表
        CMsgRegister:RegMsgListenerHandler(MSGID.SC_ROOM_GAMEROOMINFO, function ( msgData )
            CLobbyManager._instance:UpdateRoomInfoHandler(msgData)
        end, "CLobbyManager_SC_ROOM_GAMEROOMINFO")

        -- 进入普通对战
        CMsgRegister:RegMsgListenerHandler(MSGID.SC_DAER_ENTERROOMACK, function ( msgData )
            msgData.roomType = ENUM.RoomType.Normal
            CLobbyManager._instance:EnterFightRoomHandler(msgData)
        end, "CLobbyManager_SC_DAER_ENTERROOMACK")


        -- 创建自定义房间成功
        CMsgRegister:RegMsgListenerHandler(MSGID.SC_PLAYER_CREATEROOMACK, function ( msgData )
            CLobbyManager._instance:CreateCustomRoomHandler(msgData)
        end, "CLobbyManager_SC_PLAYER_CREATEROOMACK")

        -- 进入自定义房间成功
        CMsgRegister:RegMsgListenerHandler(MSGID.SC_PLAYER_ENTERCUSTOMROOMACK, function ( msgData )
            msgData.roomType =  ENUM.RoomType.Custom
            self:SetCurrentPlayingGameType(msgData.gameType)
            CloseUI("CUIPlayerCreateRoom")
            CLobbyManager._instance:EnterFightRoomHandler(msgData)
        end, "CLobbyManager_SC_PLAYER_ENTERCUSTOMROOMACK")
    end
    return  CLobbyManager._instance
end

--[[
-- 函数类型: public
-- 函数功能: 初始化
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CLobbyManager:Init(param)
    print("初始大厅管理器")
end

function CLobbyManager:SetCurrentPlayingGameType(gameType)
    self.m_currentPlayGame = gameType
end
function CLobbyManager:GetCurrentPlayingGameType()
    return self.m_currentPlayGame
end

function CLobbyManager:ReqGameRoomInfo()
    local _bDownDaer = CPlayer:GetInstance():IsAlreadyDownGame(ENUM.GameType.DAER)
    local _bDownPoker = CPlayer:GetInstance():IsAlreadyDownGame(ENUM.GameType.POKER)
    local _bDownMj = CPlayer:GetInstance():IsAlreadyDownGame(ENUM.GameType.MAJIANG)
    local sendMsg = {}
    sendMsg.partIds = {}
    if _bDownDaer then
        table.insert(sendMsg.partIds, 1)
    end

    if _bDownPoker then
        table.insert(sendMsg.partIds, 2)
    end

    if _bDownMj then
        table.insert(sendMsg.partIds, 3)
    end

    if #sendMsg.partIds > 0 then
        SendMsgToServer(MSGID.CS_ROOM_ROOMINFO, sendMsg)   
    end
end

function CLobbyManager:ReqGameRoomInfoByGameType(gameType)
    local sendMsg = {}
    sendMsg.partIds = {}

    if gameType == ENUM.GameType.DAER then
        table.insert(sendMsg.partIds, 1)
    elseif gameType == ENUM.GameType.POKER then
        table.insert(sendMsg.partIds, 2)
    elseif gameType == ENUM.GameType.MAJIANG then
        table.insert(sendMsg.partIds, 3)
    end

    if #sendMsg.partIds > 0 then
        SendMsgToServer(MSGID.CS_ROOM_ROOMINFO, sendMsg)   
    end
end

function CLobbyManager:UpdateRoomInfoHandler(msgData)
    
    if msgData.daerInfo then
        self.m_daerCount = 0
        for i, room in ipairs(msgData.daerInfo.info or {}) do
           self.m_daerCount =  self.m_daerCount + room.num or 0 
        end
    end

    
    if msgData.mjInfo then
        self.m_mjCount = 0
        for i, room in ipairs(msgData.mjInfo.info or {}) do
           self.m_mjCount =  self.m_mjCount + room.num or 0 
        end
    end

    
    if msgData.pokerInfo then
        self.m_pokerCount = 0
        for i, room in ipairs(msgData.pokerInfo.info or {}) do
           self.m_pokerCount =  self.m_pokerCount + room.num or 0 
        end
    end

    self.m_daerRoomInfo = msgData.daerInfo
    self.m_mjRoomInfo = msgData.mjInfo
    self.m_pokerRoomInfo = msgData.pokerInfo
    
    SendLocalMsg(MSGID.CC_LOBBY_UPDATE_GAMEPEOPLE, 0, 0)  
end

function CLobbyManager:GetDaerRoomInfo()
    return self.m_daerRoomInfo
end

function CLobbyManager:GetDaerRoomPeopleById(roomId)
    if self.m_daerRoomInfo then
        for i, v in ipairs( self.m_daerRoomInfo.info or {}) do
            if roomId == v.roomId then
                return v.num
            end
        end
    end
end

function CLobbyManager:GetPokerRoomInfo()
    return self.m_mjRoomInfo or 0
end

function CLobbyManager:GetMJRoomInfo()
    return self.m_pokerRoomInfo or 0
end

function CLobbyManager:GetDaerCount()
    return self.m_daerCount or 0
end

function CLobbyManager:GetMaJiangCount()
    return self.m_mjCount or 0
end

function CLobbyManager:GetPokerCount()
    return self.m_pokerCount or 0
end

function CLobbyManager:EnterFightRoomHandler(msgData)
    if not msgData.code or msgData.code == 0 then
        local _curPlayingGameType = self:GetCurrentPlayingGameType()
        if _curPlayingGameType == ENUM.GameType.DAER then
            self:FightDaerBegin(msgData)
        elseif _curPlayingGameType == ENUM.GameType.POKER then

        elseif _curPlayingGameType == ENUM.GameType.MAJIANG then

        end
    elseif (msgData.code == 1 or msgData.code == 2) and msgData.roomType == ENUM.RoomType.Normal then
        local _bTooMoney = false
        if msgData.code == 1 then
            _bTooMoney = false
        else
            _bTooMoney = true
        end
          
        local _canWillEnterRoomData = self:CheckCanEnterRoomID(_curGameType)
        if _canWillEnterRoomData then
             self:ResTooMoneyChangeRoomHandler(_bTooMoney, _canWillEnterRoomData)
        else
            if _bTooMoney then
                Notice("金币太多了！请放一些到保险箱吧。")
            elseif msgData.code == 2 then
                Notice("金币不够了！")
            end
        end
    end 
end

function CLobbyManager:ResTooMoneyChangeRoomHandler(bTooMoney, configData )
    if not configData then
        log_error(LOG_FILE_NAME, "房间数据获取为空")
        return
    end
    local _curGameType = self:GetCurrentPlayingGameType()
    local _levelType = configData[q_room_index.LevelType]
    local _roomID = configData[q_room_index.Id]
    local _roomName = ENUM.RoomLevelWord[_levelType]

    local _msg = {}
    _msg.callbackcancel = function()
        if gFightMgr then
            gFightMgr:ReqLeaveRoom(false)
        end
    end

    _msg.callbackok = function()
        if gFightMgr then
            gFightMgr:ReqLeaveRoom(false)
        end
        local _gameTypeString = "1"
        local _gameType = self:GetCurrentPlayingGameType()
        if _gameType == ENUM.GameType.DAER then
            _gameTypeString = "1"
        elseif _gameType == ENUM.GameType.MAJIANG then
            _gameTypeString = "2"
        elseif _gameType == ENUM.GameType.POKER then
            _gameTypeString = "3"
        end
        self:ReqEnterRoom(_roomID, _gameTypeString)
    end

    _msg.title = "提示"
    if bTooMoney then
        _msg.content = "金币金币太多,是否切换到".. _roomName
    else
        _msg.content = "金币金币太少,是否切换到".. _roomName
    end

    local _ui = CUICommonCallbackTips:Create(_msg)
    if _ui then
        _ui:Init(_msg)
    end
end

function CLobbyManager:CheckCanEnterRoomID(gameType)
    local _curMoney = CPlayer:GetInstance():GetGold()
    local _gameConfigData = self:GetRoomConfig(gameType)
    for i, roomConfigData in ipairs(_gameConfigData) do
        local _min = roomConfigData[q_room_index.MinLimit]
        local _max = roomConfigData[q_room_index.MaxLimit]
        if _max < 0 then
            if _curMoney >= _min then
                return roomConfigData
            end
        else
            if _curMoney >= _min and _curMoney <= _max then
                return roomConfigData
            end
        end
    end
end

function CLobbyManager:GetRoomConfig(gameType)
    local _tableData = {}
    for roomId, pConfigData in pairs( q_room ) do
        if type(pConfigData) == 'table'  then
            local _eType = pConfigData[ q_room_index.GameType ]
            if _eType == gameType then
                table.insert(_tableData, pConfigData)
            end
        end
    end
    return _tableData
end

--[[
-- 函数类型: private
-- 函数功能: 玩家进对战
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CLobbyManager:FightDaerBegin(msgData)
    if not msgData.playerInfo then
        log_error(LOG_FILE_NAME, "服务器下发数据错误,玩家数据为空")
        return
    end
    local myRoleId = CPlayer:GetInstance():GetRoleID()
    if msgData.playerInfo and msgData.playerInfo.uid == myRoleId then
        if gFightMgr then
            gFightMgr:Destroy()
        end
        gFightMgr = CFightDaerManager:New()
        if gFightMgr then
            gFightMgr:Init(msgData)
            OpenUI("CUIFightDaer", nil, msgData)
        else
            log_error(LOG_FILE_NAME, "战斗创建失败")
        end
    else
        if gFightMgr then
            gFightMgr:ResOtherPlayerEnterRoom(msgData)
        end
    end
end

function CLobbyManager:CreateCustomRoomHandler(msgData)
    if msgData.code == 0 then
        log_info(LOG_FILE_NAME, "创建自定义房间成功, 开始请求进入自己创建的房间,房间ID：%d", msgData.room.id)
        CloseUI("CUIPlayerCreateRoomOptional")
        self.m_roomPlayTimes = msgData.room.times
        self:ReqEnterCustomRoom(msgData.room.id, "4")
    else
        ErrorCode = {
            [1] = "房间的名字长度错误",
            [2] = "密码长度错误",
            [3] = "底注不在指定范围内",
            [4] = "比赛次数错误",
            [5] = "创建房间太频繁了",
            [6] = "配置表错误",
            [7] = "转换房间失败",
            [8] = "没有可用的ID了",
            [9] = "没有达到创建房间的最小金币限制",
            [10]= "未知错误",
            [11]= "已经在房间了，不能再创建房间",
            [12]= "房间的进入金币限制不应该大于自己的金币",
            [13]= "不在倍数限制范围内",
        }
        Notice("创建房间失败,"..(ErrorCode[msgData.code]) or msgData.code )
    end
end

function CLobbyManager:ReqEnterCustomRoom(roomId, gameType)
    local _sendData = {}
    _sendData.id = roomId
    _sendData.gameType = gameType
    SendMsgToServer(MSGID.CS_PLAYER_ENTERCUSTOMROOMREQ, _sendData)
end

function CLobbyManager:ReqEnterRoom(roomId, gameType)
    local roomData = {}
    roomData.roomType = roomId or 1
    roomData.gameType = gameType or "1"
    SendMsgToServer(MSGID.CS_ROOM_ENTERROOMREQ, roomData)   
end

function CLobbyManager:ReqQuickEnterRoom(roomId)
    SendMsgToServer(MSGID.CS_ROOM_QUICKENTERROOMREQ, {})   
end

function CLobbyManager:Destroy()
    CMsgRegister:UnRegListenerHandler(MSGID.SC_ROOM_GAMEROOMINFO, "CLobbyManager_SC_ROOM_GAMEROOMINFO")
    CMsgRegister:UnRegListenerHandler(MSGID.SC_DAER_ENTERROOMACK, "CLobbyManager_SC_DAER_ENTERROOMACK")
    CMsgRegister:UnRegListenerHandler(MSGID.SC_PLAYER_CREATEROOMACK, "CLobbyManager_SC_PLAYER_CREATEROOMACK")    

    CLobbyManager._instance = nil
end