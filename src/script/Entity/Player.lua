-- [[
-- Copyright (C), 2015, 
-- 文 件 名: Player.lua
-- 作    者: lyn
-- 版    本: V1.0.0
-- 创建日期: 2015-12-28
-- 完成日期: 
-- 功能描述: 
-- 其它相关: 
-- 修改记录: 
-- ]]
  
-- 日志文件名
local LOG_FILE_NAME = 'CPlayer.log'

require("script.Package.BackPackage")

CPlayer = {}
CPlayer.__index = CPlayer
CPlayer._instance = nil

G_HEART_BEAT_IDLE_INTERVAL     = 30
G_HEART_BEAT_FIGHT_INTERVAL    = 15

-- 游戏下载后的本地标记key
local Game_Daer_Down_Flag    = "game_daer"
local Game_Majiang_Down_Flag = "game_Majiang"
local Game_Dezhou_Down_Flag  = "game_Dezhou"

function CPlayer:New(o)
    o = o or {}
    setmetatable(o, CPlayer)
    o.m_nHeartBeatInterval = 10                     -- 心跳间隔时间
    o.m_sNickName          = ''                     -- 用户昵称
    o.m_nRoleId            = 0                      -- 用户ID
    o.m_nLoginTimeMs       = 0                      -- 登陆时间(服务器)
    o.m_nLevel             = 1                      -- 等级(可以获取军衔)
    o.m_nCoinNum           = 0                      -- 金币的数量
    o.m_nGem               = 0                      -- 钻石的数量
    o.m_nAccountType       = 0                      -- 账号类型(0:游客 1:微信)
    o.m_nSex               = 0                      -- 性别 (0：男 1：女)
    o.m_nVipDays           = 0                      -- VIP天数 (0天代表没有VIP)
    o.m_nExp               = 0                      -- 经验
    o.m_nCurServerTimeMs   = 0                      -- 当前服务器时间 (毫秒)
    o.m_nCurInterval       = 0                      -- 当前间隔时间
    o.m_nHeartBeatState    = 0                      -- 0: 正常   1：等待回复中
    o.m_gameFightState     = ENUM.GameFightState.None
    o.m_emailList          = {}                     -- 邮件列表key = 邮件id, value = 邮件内容
    o.m_backpackge         = CBackPackage:New()
    return o
end

--[[
-- 函数类型: public
-- 函数功能: 玩家单例对象
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CPlayer:GetInstance()
    if not CPlayer._instance then
        CPlayer._instance = CPlayer:New()
        CMsgRegister:RegMsgListenerHandler(MSGID.SC_GAME_HEARTBEATEACK, function ( msgData )
            CPlayer._instance:HeartBeatAck(msgData)
        end, "CPlayer_SC_GAME_HEARTBEATEACK")
    end
    return CPlayer._instance
end

function CPlayer:Init(msg)
    if self.m_backpackge then
        self.m_backpackge:Init()
    end
    local baseInfo = msg.base
    if baseInfo then
        self.m_nRoleId      = baseInfo.uid
        self.m_sNickName    = baseInfo.name
        self.m_nSex         = baseInfo.sex
        self.m_nLevel       = baseInfo.level
        self.m_nExp         = baseInfo.exp
        self.m_nVipDays     = baseInfo.vipLeftDay or 0
        self.m_nCoinNum     = baseInfo.coin
        self.m_nGem         = baseInfo.gem
        self.m_nAccountType = baseInfo.accountType
        self.m_sHeadUrl     = baseInfo.headerUrl
    else
        log_error(LOG_FILE_NAME, "初始玩家基本信息失败")
    end

    local playerExtraInfo = msg.extra
    if playerExtraInfo then
        -- 设置背包
        self:GetBackPackage():ParseItemList(playerExtraInfo.items)
        
        CSignInManager:GetInstance():Init()
        --TODO:签到
        CSignInManager:GetInstance():SetSignAndTaskInfo(playerExtraInfo)

        --TODO:胜利/失败场
    else
        log_error(LOG_FILE_NAME, "初始化玩家额外的基本信息失败")
    end
    CSystemSetting:GetInstance():SetSetting(Game_Daer_Down_Flag, 1, "int")

    -- 金钱资源更新
    CMsgRegister:RegMsgListenerHandler(MSGID.SC_PLAYER_RESOURCENOTIFY, function ( msgData )
        self:UpdateResources(msgData)
    end, "CPlayer_SC_PLAYER_RESOURCENOTIFY")

    CMsgRegister:RegMsgListenerHandler(MSGID.SC_REENTER_FIGHT_NOTIFY, function ( msgData )
        self:ReEnterFight(msgData)
    end, "CPlayer_SC_REENTER_FIGHT_NOTIFY")
    
    -- 初始化邮件
    CMsgRegister:RegMsgListenerHandler(MSGID.SC_PLYAER_INIT_EMAIL, function ( msgData )
        self:ResInitEmailHandler(msgData)
    end, "CPlayer_SC_PLYAER_INIT_EMAIL")

    -- 新增邮件
    CMsgRegister:RegMsgListenerHandler(MSGID.SC_PLAYER_ADD_EMAIL, function ( msgData )
        self:ResAddEmailHandler(msgData)
    end, "CPlayer_SC_PLAYER_ADD_EMAIL")

    -- 移除邮件
    CMsgRegister:RegMsgListenerHandler(MSGID.SC_PLAYER_REMOVE_EMAIL, function ( msgData )
        self:ResAddEmailHandler(msgData)
    end, "CPlayer_SC_PLAYER_REMOVE_EMAIL")

    -- 接收到对战邀请
    CMsgRegister:RegMsgListenerHandler(MSGID.SC_PLAYER_INVITEJIONFIGHTNOTIFY, function ( msgData )
        self:ResInviteFight(msgData)
    end, "CPlayer_SC_PLAYER_INVITEJIONFIGHTNOTIFY")

end

-- 函数功能: 重新进入战斗
-- 参    数: 无
-- 返 回 值: 无
-- 备    注:
function CPlayer:ReEnterFight( msgData )

    if msgData.gameType == "none" then
        if self:GetGameFightState() ~= ENUM.GameFightState.None then
            if CLobbyManager:GetInstance():GetCurrentPlayingGameType() == ENUM.GameType.DAER then
                local myRoleId = CPlayer:GetInstance():GetRoleID()
                local msg = {}
                msg.playerID = myRoleId
                if gFightMgr then
                    gFightMgr:Destroy()
                end
            end
        end
    else
        -- 1 = 匹配房间大贰 2 = 匹配房间麻将 3 = 匹配房间德州
        -- 4 = 自建房间大贰 5 = 自建房间麻将 6 = 自建房间德州
        -- 7 = 比赛房间大贰 8 = 比赛房间麻将 9 = 比赛房间德州
        if msgData.gameType == "1" then
            CLobbyManager:GetInstance():SetCurrentPlayingGameType(ENUM.GameType.DAER)
            CLobbyManager:GetInstance():ReqEnterRoom(msgData.roomType, msgData.gameType)
        elseif msgData.gameType == "2" then            
        elseif msgData.gameType == "3" then

        elseif msgData.gameType == "4" then
            CLobbyManager:GetInstance():SetCurrentPlayingGameType(ENUM.GameType.DAER)
            CLobbyManager:GetInstance():ReqEnterCustomRoom(msgData.roomType, msgData.gameType)
        elseif msgData.gameType == "5" then
        elseif msgData.gameType == "6" then
        elseif msgData.gameType == "7" then
        elseif msgData.gameType == "8" then
        elseif msgData.gameType == "9" then
        end
    end
end

function CPlayer:ReqSaveOrGetGold(sendData) 
    if sendData then
        local _sendData = {}
        _sendData.bWithdraw = sendData.bSave
        _sendData.value = sendData.value
        SendMsgToServer(MSGID.CS_PLAYER_REQINSURENCEMONEY, sendData)
    end  
end

function CPlayer:ResInitEmailHandler(msgData)
    for i, v in ipairs(msgData.maillist or {}) do
        self.m_emailList[v.mailId] = v
    end
end

function CPlayer:ReadOneEmail(mailId)
    local _emailInfo = self.m_emailList[mailId]
    if _emailInfo then
        _emailInfo.bRead = true
    end 
    self:NotifyRedPoint(ENUM.RedPointType.EMail, self:IsHaveNotReadEmail())
end

function CPlayer:ResAddEmailHandler(msgData)
    self.m_emailList[msgData.emailID] = msgData.emailData
    self:NotifyRedPoint(ENUM.RedPointType.EMail, self:IsHaveNotReadEmail())
end

function CPlayer:ResRemoveEmailHandler(msgData)
    if msgData then
        for i, v in ipairs(msgData.maillist or {}) do
            self.m_emailList[v.mailId] = v   
        end
    end
    self:NotifyRedPoint(ENUM.RedPointType.EMail, self:IsHaveNotReadEmail())
end

function CPlayer:GetEmails()
    return self.m_emailList
end

function CPlayer:GetEmail(emailId)
   return self.m_emailList[emailId]
end

function CPlayer:IsHaveNotReadEmail()
    local _count = TableSize(self.m_emailList)
    local _countHaveNotReadEmail = 0
    if _count > 0 then
        for k, v in pairs(self.m_emailList) do
            if not v.bRead then
                _countHaveNotReadEmail = _countHaveNotReadEmail + 1
            end
        end
        if _countHaveNotReadEmail > 0 then
            return true
        end
    else
        return false
    end
    return false
end

function CPlayer:ResInviteFight(msgData)
    if msgData.code == 0 then
        if not gFightMgr then
            local _msg = {}
            local _coinType = ""
            if msgData.currencyType == 1 then
                _coinType = "积分房"
            elseif msgData.currencyType == 2 then
                _coinType = "金币房"
            end
            _msg.content = msgData.invitePlayerName.."邀请你进入".._coinType..",是否同意？"
            _msg.title = "提示"
            _msg.callbackok = function()
                msgData.roomType = msgData.roomID
                self:ReEnterFight(msgData)
            end

            _msg.callbackcancel = function()
                --TODO
            end
            local _ui = CUICommonCallbackTips:Create(_msg)
            if _ui then
                _ui:Init(_msg)
            end
        end
    else
        local ErrorCode = {
            [-1] = "进入房间失败",
            [1] = "进入房间失败,房间已满",
            [2] = "进入房间失败,房间不存在",
            [3] = "进入房间失败,你的金币不够",
        }
        Notice(ErrorCode[msgData.code or -1])
    end
end

-- 发送一条公告
function CPlayer:SendSysNotice(content)
    local sendData = {}
    sendData.playerID = self:GetRoleID()
    sendData.content = content or ""
    SendMsgToServer(MSGID.CS_PLAYER_SEND_NOTICE, sendData)  
end

function CPlayer:NotifyRedPoint(redType, bShow)
    local event = {}
    event.name = CEvent.MainRedPoint
    event.redType = redType
    event.bShow = bShow or false
    gPublicDispatcher:DispatchEvent(event)
end

--[[
-- 函数类型: private
-- 函数功能: 更新金币和宝石
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CPlayer:UpdateResources(msgData)
    if msgData.coin then self:SetGold(msgData.coin) end
    if msgData.gem then self:SetGem(msgData.gem) end
    if msgData.insurCoin then self:SetBoxGold(msgData.insurCoin) end
    SendLocalMsg(MSGID.CC_PLAYER_UPDATE_RESOURCES, 0, 0)
end

function CPlayer:SetGameFightState(fightState)
    self.m_gameFightState = fightState
end

function CPlayer:GetGameFightState()
    return self.m_gameFightState
end

-- 函数类型: 接口
-- 函数功能: 游戏是否下载
-- 参    数: 无
-- 返 回 值: 无
-- 备    注:
function CPlayer:IsAlreadyDownGame(gameType)
    if gameType == ENUM.GameType.DAER then
        local _daerFlag = CSystemSetting:GetInstance():GetSetting(Game_Daer_Down_Flag, "int")
        if _daerFlag == 1 then
            return true
        end
    elseif gameType == ENUM.GameType.POKER then
        local _dezhouFlag = CSystemSetting:GetInstance():GetSetting(Game_Dezhou_Down_Flag, "int")
        if _dezhouFlag == 1 then
            return true
        end
    elseif gameType == ENUM.GameType.MAJIANG then
        local _mjFlag = CSystemSetting:GetInstance():GetSetting(Game_Majiang_Down_Flag, "int")
        if _mjFlag == 1 then
            return true
        end
    end
    return false
end

--[[
-- 函数类型: public
-- 函数功能: 设置游戏已经下载的标记
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CPlayer:SetGameAlreadyDown(gameType)
    if gameType == ENUM.GameType.DAER then
        CSystemSetting:GetInstance():SetSetting(Game_Daer_Down_Flag, 1, "int")
    elseif gameType == ENUM.GameType.DAER then
        CSystemSetting:GetInstance():SetSetting(Game_Dezhou_Down_Flag, 1, "int")
    elseif gameType == ENUM.GameType.DAER then
        CSystemSetting:GetInstance():SetSetting(Game_Majiang_Down_Flag, 1, "int")
    end
end

-- 获取存款
function CPlayer:GetBoxGold()
    return self.m_boxMoney or 0
end

-- 设置存款
function CPlayer:SetBoxGold(gold)
    self.m_boxMoney = gold
end

function CPlayer:GetGold()
    return self.m_nCoinNum or 0
end

function CPlayer:SetGold(num)
    self.m_nCoinNum = num
end

function CPlayer:GetHeadURL(  )
    return self.m_sHeadUrl
end

function CPlayer:SetGem(num)
    return self.m_nGemNum
end

function CPlayer:GetGem()
    self.m_nGemNum = num
end

function CPlayer:GetSex()
    return self.m_nSex
end

function CPlayer:IsVIP()
    if self.m_nVipDays > 0 then
        return true
    end
    return false
end

function CPlayer:GetVipDay()
    return self.m_nVipDays or 0
end


function CPlayer:SetHeartBeatInterval( interval )
    self.m_nHeartBeatInterval = interval
end

function CPlayer:Update(dt)
    if CLuaLogic.LoginState == 1 then
        --本地时间更新
        local dt_ms = dt * 1000
        self.m_nCurServerTimeMs = self.m_nCurServerTimeMs + dt_ms
        --心跳时间检测
        self.m_nCurInterval = self.m_nCurInterval + dt
        if self.m_nCurInterval >= self.m_nHeartBeatInterval then
            self.m_nCurInterval = 0
            self:SendHearBeatMsg()
        end
    end
end

--发送心跳包
function CPlayer:SendHearBeatMsg( )
    if self.m_nHeartBeatState == 0 then
        SendMsgToServer(MSGID.CS_GAME_HEARTBEATREQ, {}, true)
        self.m_nHeartBeatState = 1
    else
        CLuaLogic.LoginState = 0
        CLuaLogic.DisConnect()
        self.m_nHeartBeatState = 0
        self.m_nCurInterval = 0
        --弹出重新连接提示框
        --OpenUI("CUICommonTips", "UILogic", {title = "掉线通知", content = "当前网络超时，与服务器断开连接！"})
    end
end

function CPlayer:HeartBeatAck( msgData )
    self.m_nCurServerTimeMs = msgData.time
    self.m_nHeartBeatState = 0
end

--设置登录时间
function CPlayer:SetLoginTime( server_time )
    self.m_nLoginTimeMs = server_time
    self.m_nCurServerTimeMs = server_time

end

--获取登录时间
function CPlayer:GetLoginTime(  )
    return self.m_nLoginTimeMs
end

-- 获取当前服务器时间
function CPlayer:GetServerTimeMs(  )
    return self.m_nCurServerTimeMs
end

--[[
-- 函数类型: public
-- 函数功能: 设置用户ID
-- 参数[IN]: userID
-- 返 回 值: 无
-- 备    注:
--]]
function CPlayer:SetRoleID( userID )
    assert(userID)
    if userID ~=0 then
        self.m_nRoleId  = userID
    else
        log_error(LOG_FILE_NAME, '设置玩家id错误:%d', userID)
    end
end


--[[
-- 函数类型: public
-- 函数功能: 获取玩家ID
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CPlayer:GetRoleID()
    return self.m_nRoleId
end

--[[
-- 函数类型: public
-- 函数功能: 设置玩家昵称
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CPlayer:SetUserName( nickName )
    self.m_sNickName = nickName
end

--[[
-- 函数类型: public
-- 函数功能: 获取玩家昵称
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CPlayer:GetUserNickName()
    return self.m_sNickName
end

--[[
-- 函数类型: public
-- 函数功能: 获取玩家等级
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CPlayer:GetLevel()
    return self.m_nLevel or 1
end

--[[
-- 函数类型: public
-- 函数功能: 设置玩家等级
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CPlayer:SetLevel( level )
    self.m_nLevel = level
end

function CPlayer:GetBackPackage()
    return self.m_backpackge
end

--获取时间点
function CPlayer:GetTimePoint(hour, min, sec)
    if self.m_Timestamp == 0 then
        local nNow = CPlayer:GetInstance():GetClientTime()
        local tabTime = os.date("*t", math.floor(nNow))
        tabTime.hour = 0
        tabTime.min  = 0
        tabTime.sec  = 0
        self.m_Timestamp = os.time(tabTime)
    end
    return self.m_Timestamp + hour * 3600 + min * 60 + sec
end


function CPlayer:Destroy()
    gPublicDispatcher:RemoveEventListenerObj(CPlayer._instance)
    CMsgRegister:UnRegListenerHandler(MSGID.SC_PLYAER_INIT_EMAIL, "CPlayer_SC_PLYAER_INIT_EMAIL")
    CMsgRegister:UnRegListenerHandler(MSGID.SC_PLAYER_ADD_EMAIL, "CPlayer_SC_PLAYER_ADD_EMAIL")
    CMsgRegister:UnRegListenerHandler(MSGID.SC_PLAYER_REMOVE_EMAIL, "CPlayer_SC_PLAYER_REMOVE_EMAIL")
    CMsgRegister:ClearRegListenerHandler(MSGID.SC_GAME_HEARTBEATEACK)
    CMsgRegister:ClearRegListenerHandler(MSGID.SC_REENTER_FIGHT_NOTIFY)
    CPlayer._instance = nil
end