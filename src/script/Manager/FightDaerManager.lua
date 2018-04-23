--[[
-- Copyright (C), 2015, 
-- 文 件 名: FightDaerManager.lua
-- 作    者: lyn
-- 版    本: V1.0.0
-- 创建日期: 2016-10-20
-- 完成日期: 
-- 功能描述: 
-- 其它相关: 
-- 修改记录: 
--]]

-- 日志文件名
local LOG_FILE_NAME = 'CFightDaerManager.log'

require "script.Manager.FightBase"

CFightDaerManager = class('CFightDaerManager', CFightBase)

CFightDaerManager._instance = nil

--[[
-- 函数类型: public
-- 函数功能: 构造一个C*管理器对象
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CFightDaerManager:New()
    local o = CFightBase:New()
    setmetatable(o, CFightDaerManager)
    return o
end

--[[
-- 函数类型: public
-- 函数功能: 初始化
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CFightDaerManager:Init(msg)
    print("初始化大贰管理器", CPlayer:GetInstance():GetRoleID())
    CFightDaerManager.super.Init(self, msg)
    self:SetGameType(ENUM.GameType.DAER)
    self:SetFightPlayerInfo(msg)

    if not self.m_fightPlayerInfo then
        self.m_fightPlayerInfo = {}
    end
    self.m_fightState = ENUM.GameFightState.Begin
    self.m_lastReusltInfo = nil

    -- 游戏对战开始
    CMsgRegister:RegMsgListenerHandler(MSGID.SC_DAER_GAMESTARTACK, function ( msgData )
        self:InitFightInfo(msgData)
    end, "CFightDaerManager_SC_DAER_GAMESTARTACK")

    -- 动作回复
    CMsgRegister:RegMsgListenerHandler(MSGID.SC_DAER_ACTIONACK, function ( msgData )
        self:ResActionHandler(msgData)
    end, "CFightDaerManager_SC_DAER_ACTIONACK")
    
    -- 其他玩家的动作通知
    CMsgRegister:RegMsgListenerHandler(MSGID.SC_DAER_ACTIONNOTIFYACK, function ( msgData )
        self:ResActionNotifyHandler(msgData)
    end, "CFightDaerManager_SC_DAER_ACTIONNOTIFYACK")  

    -- 玩家倒计时
    CMsgRegister:RegMsgListenerHandler(MSGID.SC_DAER_COUNTDOWNNOTIFYACK, function ( msgData )
        self:ResCountDownNotifyHandler(msgData)
    end, "CFightDaerManager_SC_DAER_COUNTDOWNNOTIFYACK")

    -- 注册结算消息
    CMsgRegister:RegMsgListenerHandler(MSGID.SC_DAER_JIESUANNOTIFYACK, function ( msgData )
        self:SetFightState(ENUM.GameFightState.End)
        if msgData.addi then
            self:SetStateEnd(msgData.addi.stageEnd)
        end
        local msg = SerializeToStr(msgData)
        SendLocalMsg(MSGID.CC_DAER_FIFHGT_RESULT, msg, #msg) 
    end, "CFightDaerManager_SC_DAER_JIESUANNOTIFYACK")

    -- 注册自建房间终极结算消息
    CMsgRegister:RegMsgListenerHandler(MSGID.SC_PLAYER_CUSTOMROOM_FINALJIESUANNOTIFYACK, function ( msgData )
        self:ResLastResultHandler(msgData)
    end, "CFightDaerManager_SC_DAER_JIESUANNOTIFYACK")

    CPlayer:GetInstance():SetHeartBeatInterval(G_HEART_BEAT_FIGHT_INTERVAL)
end


-- 设置托管
function CFightDaerManager:SetTuoGuan(bTuoguan)
    self.m_bTuoGuan = bTuoguan or false
end

-- 是否处于托管
function CFightDaerManager:IsTuoGuan()
    return self.m_bTuoGuan or false
end

-- 是否是庄
function CFightDaerManager:IsZhuang()
    return self.m_bZhuang
end

-- 是否是报
function CFightDaerManager:IsBao()
    return self.m_bBaoPai or false
end

-- 设置庄
function CFightDaerManager:SetZhuang(bZhuang)
    self.m_bZhuang = bZhuang or false
end

-- 设置报
function CFightDaerManager:SetBao(bBao)
    self.m_bBaoPai = bBao or false
end

function CFightDaerManager:GetDeskScore()
    local _roomType = self:GetRoomType()
    local _duzhu = 0
    if _roomType == ENUM.RoomType.Custom then
        return self.m_mDeskScore
    else
        _duzhu = q_room.GetTempData(self:GetRoomID(), "Difen") or 0
    end
    return _duzhu
end

function CFightDaerManager:ReqAction(sendData)
    sendData.playerID = CPlayer:GetInstance():GetRoleID()
    sendData.sysType = self:GetRoomType()
    SendMsgToServer(MSGID.CS_DAER_ACTIONREQ, sendData)   
end

function CFightDaerManager:IsHavePlayerOnLocation(location)
    for k,v in pairs(self.m_fightPlayerInfo) do
        if v.locationType == location then
            return true
        end
    end
    return false
end

function CFightDaerManager:SetFightPlayerInfo(msgData)
    if not self.m_fightPlayerInfo then
        self.m_fightPlayerInfo = {}
    end
    self.m_fightPlayerInfo[msgData.playerInfo.uid]              = msgData.playerInfo
    self.m_fightPlayerInfo[msgData.playerInfo.uid].locationType = msgData.shangjiaType
    self.m_fightPlayerInfo[msgData.playerInfo.uid].bReady       = msgData.bReady
    self.m_fightPlayerInfo[msgData.playerInfo.uid].bRoomMaster  = msgData.isOwner

    -- 如果是积分房间,金币就是积分
    local _roomType = self:GetRoomType()
    if _roomType == ENUM.RoomType.Custom then
        self.m_fightPlayerInfo[msgData.playerInfo.uid].coin = 0
    end

    local event = {}
    event.name = CEvent.OnePlayerEnterRoom
    event.locationType = msgData.shangjiaType
    event.action = "enter"
    gPublicDispatcher:DispatchEvent(event)
end

function CFightDaerManager:IsMineRoomMaster()
    local _myRoleId = CPlayer:GetInstance():GetRoleID()
    local _myInfo = self:GetFightPlayerInfo(_myRoleIds)
    if _myInfo then
        return _myInfo.bRoomMaster
    end
end

function CFightDaerManager:ResOtherPlayerEnterRoom(msgData)
    log_info(LOG_FILE_NAME, "其他人进入房间,刷新信息")
    self:SetFightPlayerInfo(msgData)
    local _plaeyrInfo = self:GetFightPlayerInfo(msgData.playerInfo.uid)
    local msg = 
    {
        playerInfo = _plaeyrInfo,
    }
    local buf = SerializeToStr(msg)
    SendLocalMsg(MSGID.CC_DAER_UPDATE_PLAYERINFO, buf, #buf)    
end

function CFightDaerManager:GetFightPlayerInfo(playerId)
    if self.m_fightPlayerInfo then
        return self.m_fightPlayerInfo[playerId]
    end
end

function CFightDaerManager:ResLastResultHandler(msgData)
    local _isOpen = CUIManager:GetInstance():IsUIOpen("CUIDaerResult")
    if _isOpen then
        if msgData.jieSuanInfo then
            print("设置最终结算信息")
            self:SetTheLastResult(msgData.jieSuanInfo)
        end
    else
        print("设置最终结算信息, 并打开UI")
        if msgData.jieSuanInfo then
            self:SetTheLastResult(msgData.jieSuanInfo)
            OpenUI("CUICoustomResult")
        end
    end
end

function CFightDaerManager:SetTheLastResult(lastResult)
    self.m_lastReusltInfo = lastResult
end

function CFightDaerManager:GetTheLastResult()
    return self.m_lastReusltInfo
end

function CFightDaerManager:GetPlayerSex(playerId)
    local _playerInfo = self:GetFightPlayerInfo(playerId)
    if _playerInfo then
        return _playerInfo.sex
    end
end

-- 函数功能: 根据玩家id获取玩家基本信息
function CFightDaerManager:GetFightPlayersInfo()
    return self.m_fightPlayerInfo
end

-- 函数功能: 玩家离开战斗房间
function CFightDaerManager:PlayerLeaveFightRoom(playerID)
    if self.m_fightPlayerInfo then
        self.m_fightPlayerInfo[playerID] = nil
    end
end

-- 函数功能: 初始化对战信息
function CFightDaerManager:InitFightInfo(msgData)
    self:SetFightState(msgData.fightState)
    local buf = SerializeToStr(msgData)
    SendLocalMsg(MSGID.CC_DAER_UPDATE_FIGHTINFO, buf, #buf)
end

function CFightDaerManager:ResetFightInfo()
    self.m_fightPlayerInfo       = {}
end

-- 函数功能: 同步玩家动作处理
function CFightDaerManager:ResActionNotifyHandler(msgData)
    local buf = SerializeToStr(msgData)
    SendLocalMsg(MSGID.CC_DAER_UPDATE_ACTION_NOTIFY, buf, #buf)    
end

function CFightDaerManager:ResCountDownNotifyHandler(msgData)
    local buf = SerializeToStr(msgData)
    SendLocalMsg(MSGID.CC_DAER_COUNT_DOWN, buf, #buf)    
end

-- 函数功能: 玩家回复动作处理
function CFightDaerManager:ResActionHandler(msgData)
    local buf = SerializeToStr(msgData)
    SendLocalMsg(MSGID.CC_DAER_UPDATE_ACTIONACK, buf, #buf)
end

-- 函数功能: 玩家离开房间通知(如果playerID和自己相同，自己退出房间)
function CFightDaerManager:ResPlayerLeaveRoomHandler(msgData)
    
    local _myRoleId = CPlayer:GetInstance():GetRoleID()
    
    -- 换桌
    if msgData.isChangeDesk and msgData.playerID == _myRoleId then
        log_error(LOG_FILE_NAME, "换桌")
        local _roomType = self:GetRoomType()
        if _roomType ~= ENUM.RoomType.Custom then
            local _myFightPlayerInfo = clone(self.m_fightPlayerInfo[_myRoleId])
            self.m_fightPlayerInfo = {}
            self.m_fightPlayerInfo[_myRoleId] = _myFightPlayerInfo
            self.m_changeDeskCountDown = TIME_COUNT_DOWN
            local msg = {
                time = self.m_changeDeskCountDown
            }
            local buffer = SerializeToStr(msg)
            SendLocalMsg(MSGID.CC_DAER_FIFHGT_CHANGEROOM, buffer, #buffer)
        end
    else

        local _roomType = self:GetRoomType()
        if _roomType ~= ENUM.RoomType.Custom then 
            if self.m_fightPlayerInfo and msgData.playerID ~= _myRoleId then
                self.m_fightPlayerInfo[msgData.playerID] = nil
            end    
        end

        if msgData.playerID == _myRoleId and not self:GetTheLastResult() then
            self:Destroy()
            return
        else
            -- xx离开房间
            local buf = SerializeToStr(msgData)
            SendLocalMsg(MSGID.CC_DAER_UPDATE_LEAVEROOM, buf, #buf)

            local event = {}
            event.name = CEvent.OnePlayerEnterRoom
            event.locationType = msgData.shangjiaType
            event.action = "leave"
            gPublicDispatcher:DispatchEvent(event)
        end
    end
end

function CFightDaerManager:ResPlayerLeaveCustomRoomHandler(msgData)
    self:ResPlayerLeaveRoomHandler(msgData)
end

--[[
-- 函数类型: public
-- 函数功能: 销毁(析构)
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CFightDaerManager:Destroy()
    self:ResetFightInfo()
    CMsgRegister:UnRegListenerHandler(MSGID.SC_DAER_GAMESTARTACK, "CFightDaerManager_SC_DAER_GAMESTARTACK")
    CMsgRegister:UnRegListenerHandler(MSGID.SC_DAER_ACTIONACK, "CFightDaerManager_SC_DAER_ACTIONACK")
    CMsgRegister:UnRegListenerHandler(MSGID.SC_DAER_ACTIONNOTIFYACK, "CFightDaerManager_SC_DAER_ACTIONNOTIFYACK")
    CMsgRegister:UnRegListenerHandler(MSGID.SC_DAER_COUNTDOWNNOTIFYACK, "CFightDaerManager_SC_DAER_COUNTDOWNNOTIFYACK")
    CMsgRegister:UnRegListenerHandler(MSGID.SC_DAER_JIESUANNOTIFYACK, "CFightDaerManager_SC_DAER_JIESUANNOTIFYACK")
    CFightDaerManager.super.Destroy(self)
    CFightDaerManager._instance = nil
    log_info(LOG_FILE_NAME, "销毁大贰战斗管理器")
end