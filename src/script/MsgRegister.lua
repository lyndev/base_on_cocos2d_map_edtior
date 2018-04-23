-- [[
-- Copyright (C), 2015, 
-- 文 件 名: MsgRegister.lua
-- 作    者: lyn
-- 版    本: V1.0.0
-- 创建日期: 2015-12-22 
-- 完成日期:  
-- 功能描述: 消息相关处理函数及定义 
-- 其它相关:  
-- 修改记录: 
-- ]] 

-- 日志文件名
local LOG_FILE_NAME = 'CMsgRegister.log'

protobuf = require "script.SDK.protobuf"
CMsgRegister = {}
CMsgRegister.__index = CMsgRegister  


-- 前三位为功能编号（100~999）(注：客户端独立功能1-99)
-- 第四位为来源（1:SC   2:CS  3:SS  4:CC） 
-- 后两位为具体功能来源的消息编号
-- 1-99 客户端占用,所以通信协议ID从100起

MSG_SED_RSSULT_TYPE = 
{
    [0] = '发送成功',
    [-1] = '参数传入失败',
    [-2] = '连接已经断开，不能发送数据',
    [-4] = '发送队列已满',
    [-5] = '分配内存失败',
}

-- 消息功能分类
MSGFUNC = 
{
    CONNECT        = 1,       -- 连接服务器相关
    UI             = 2,       -- UI
    LOGIN          = 100,     -- 登录功能
    PLAYER         = 103,     -- 玩家系统
    DAER           = 104,     -- 大贰游戏
    ROOM           = 105,     -- 房间
    GAME           = 200,     -- 游戏主要
    PROXY          = 925,      -- 代理消息
}

-- 消息来源分类
MSGSOURCE =
{
    SC = 1,         -- 服务器->客户端
    CS = 2,         -- 客户端->服务器
    SS = 3,         -- 服务器->服务器
    CC = 4,         -- 客户端->客户端
}
 
-- 消息ID
MSGID = 
{
-- C++端发送按钮播放音效
    CC_SOUND                                  = 001300,               -- C++端播放音效

-- 世界
    CC_CHANGE_WORLD                           = 100403,               -- 改变世界

-- 连接服务器相关:MSGFUNC.CONNECT
    CC_CONNECT_SUCCESS                        = 001401,               -- 连接成功
    CC_CONNECT_FAILED                         = 001402,               -- 连接失败
    CC_CONNECT_BREAK                          = 001403,               -- 连接断开
    CC_SEND_SUCCESS                           = 001404,               -- 服务器消息发送成功
-- 微信相关
    CC_WECHAT_ACCESSTOKEN                     = 001601,               -- 微信返回access token
    CC_WECHAT_REFRESHTOKEN                    = 001602,               -- 刷新access token
    CC_WECHAT_USERINFO                        = 001603,               -- 获取微信用户信息
    CC_WECHAT_USERHEAD                        = 001604,               -- 获取用户头像
    CC_WECHAT_SHARE_CHAT                      = 001701,               -- 分享到好友聊天成功
    CC_WECHAT_SHARE_FRIENDCIRCLE              = 001702,               -- 分享到朋友圈成功

-- UI功能:MSGFUNC.UI      
    CC_OPEN_UI                                = 002401,               -- 打开UI
    CC_CLOSE_UI                               = 002402,               -- 关闭UI
    CC_SHOW_TIPS                              = 002403,               -- 显示tips
    CC_DAER_UPDATE_PLAYERINFO                 = 002410,               -- 大贰对战更新玩家信息
    CC_DAER_UPDATE_FIGHTINFO                  = 002411,               -- 大贰对战更新对战玩家的牌和桌面的牌
    CC_DAER_UPDATE_ACTIONACK                  = 002412,               -- 大贰对战更新我的卡牌ACTION
    CC_DAER_UPDATE_ACTION_NOTIFY              = 002413,               -- 大贰对战更新卡牌ACTION通知
    CC_DAER_UPDATE_LEAVEROOM                  = 002414,               -- 大贰对战更新某某离开房间
    CC_DAER_COUNT_DOWN                        = 002415,               -- 大贰玩家的倒计时
    CC_DAER_FIFHGT_RESULT                     = 002416,               -- 大贰计算
    CC_DAER_FIFHGT_HUANGZHUANG                = 002419,               -- 大贰黄庄
    CC_DAER_FIFHGT_CHANGEROOM                 = 002420,               -- 大贰换桌
    CC_LOBBY_UPDATE_GAMEPEOPLE                = 002417,               -- 游戏的在线人数
    CC_PLAYER_UPDATE_RESOURCES                = 002430,               -- 更新金币
    CC_PLAYER_ADD_ONE_SYS_NOTICE              = 002450,               -- 增加了一条系统公告

-- 游戏心跳
    CS_GAME_HEARTBEATREQ                      = 200201,                -- 游戏心跳请求
    SC_GAME_HEARTBEATEACK                     = 200101,                -- 游戏心跳回复

-- 与服务器通信消息
    CS_LOGINREQ                                = 100201,               -- 登录消息
    SC_LOGINACK                                = 100101,               -- 登录回复
    CS_ACCOUNT_BIND_REQ                        = 100202,               -- 帐号绑定消息
    SC_PLAYER_INFO                             = 100102,               -- 玩家基本信息
    SC_PLAYER_RESOURCENOTIFY                   = 100103,               -- 玩家金币更新
    CS_PLAYER_READ_EMAIL                       = 100204,               -- 阅读邮件
    CS_PLAYER_SEND_NOTICE                      = 100205,               -- 发送公告
    CS_PLAYER_REQINSURENCEMONEY                = 100206,               -- 存取钱
    CS_PLAYER_GET_ATTACH_EMAIL                 = 100207,               -- 获取邮件附件
    CS_PLAYER_REQFIGHTCHAT                     = 100220,               -- 棋牌对战发送聊天
    CS_PLAYER_ENTERCUSTOMROOMREQ               = 100221,            
    CS_PLAYER_LEAVECUSTOMROOMREQ               = 100222,            
    CS_PLAYER_FINDROOMREQ                      = 100223,            
    CS_PLAYER_ROOMLISTREQ                      = 100224,            
    CS_PLAYER_CREATEROOMREQ                    = 100225, 
    CS_PLAYER_KICK_PLAYER                      = 100230,               -- 踢人         
    CS_PLAYER_REQINVITEFRIEND                  = 100235,
    CS_PLAYER_REQSIGNIN                        = 100236, 
    CS_PLAYER_REREPLENISHQSIGNIN               = 100237,
    CS_PLAYER_REQGETTASKAWRD                   = 100238, 
    SC_PLYAER_INIT_EMAIL                       = 100110,               -- 初始化邮件
    SC_PLAYER_ADD_EMAIL                        = 100111,               -- 新曾邮件
    SC_PLAYER_REMOVE_EMAIL                     = 100112,               -- 移除邮件
    SC_PLAYER_SYS_NOTICE                       = 100113,               -- 接收系统通知
    SC_PLAYER_FIGHT_CHAT                       = 100120,               -- 棋牌对战接收聊天
    SC_REENTER_FIGHT_NOTIFY                    = 100104,               -- 重进游戏
    SC_PLAYER_CREATEROOMACK                    = 100121,
    SC_PLAYER_ROOMLISTACK                      = 100122,
    SC_PLAYER_ENTERCUSTOMROOMACK               = 100123,
    SC_PLAYER_LEAVECUSTOMROOMACK               = 100124,
    SC_PLAYER_FINDROOMACK                      = 100125,
    SC_PLAYER_CUSTOMROOM_FINALJIESUANNOTIFYACK = 100130,
    SC_PLAYER_INVITEJIONFIGHTNOTIFY            = 100135,
    SC_PLAYER_SIGNINUPDATE                     = 100136,
    SC_PLAYER_TASKUPDATE                       = 100137,
-- 房间
    CS_ROOM_ENTERROOMREQ                       = 105201,                -- 进入房间
    CS_ROOM_ROOMINFO                           = 105202,                -- 请求房间列表信息：参数：游戏类型
    CS_ROOM_QUICKENTERROOMREQ                  = 105203,                -- 快速进入房间
    SC_ROOM_GAMEROOMINFO                       = 105101,                -- 服务器返回的房间信息

-- 好友
    CS_FRIEND_REQFRIENDACTION                  = 108201,
    CS_FRIEND_REQADDFRIEND                     = 108203,
    CS_FRIEND_REQREMOVEFRIEND                  = 108204,
    CS_FRIEND_REQSEARCHFRIEND                  = 108205,
    CS_FRIEND_REQFIRENDCHAT                    = 108206,
    CS_FRIEND_REQAPPLYFRIEND                   = 108207,
    SC_FRIEND_RESALLFRIENDINFO                 = 108101,
    SC_FRIEND_RESALLAPPLYFRIENDLIST            = 108102,
    SC_FRIEND_RESADDFRIEND                     = 108103,
    SC_FRIEND_RESREMOVEFRIEND                  = 108104,
    SC_FRIEND_NOTIFYFRIENDONOFFLINE            = 108105,
    SC_FRIEND_RESSEARCHFRIEND                  = 108106,
    SC_FRIEND_RESFIRENDCHAT                    = 108107,
    SC_FRIEND_OFFLINEMSGNOFITY                 = 108108,

-- 泸州大贰游
    CS_DAER_LEAVEROOMREQ                       = 103201,                -- 发送一个离开房间的请求
    CS_DAER_ACTIONREQ                          = 103202,                -- 请求一个动作

    SC_DAER_ENTERROOMACK                       = 103101,                -- 玩家进入房间(没准备)
    SC_DAER_LEAVEROOMACK                       = 103102,                -- 离开房间通知其他人
    SC_DAER_GAMESTARTACK                       = 103103,                -- 所有玩家准备好看，游戏开始
    SC_DAER_ACTIONACK                          = 103104,                -- 动作回复
    SC_DAER_ACTIONNOTIFYACK                    = 103105,                -- 广播给其他人的动作
    SC_DAER_COUNTDOWNNOTIFYACK                 = 103106,                -- 玩家倒计时
    SC_DAER_JIESUANNOTIFYACK                   = 103107,                -- 大贰结算消息
    SC_DAER_PASSCARDNOTIFYACK                  = 103108,                -- 大贰玩家出和过的牌
    SC_DAER_PASSEDNOTIFYACK                    = 103109,                -- 大贰玩家过过的牌提示（客户端要文字提示）

 }

-- 消息类型[ 对应proto ]
MSGTYPE = 
{
    [MSGID.CS_LOGINREQ]                = 'rpc.Login',
    [MSGID.SC_LOGINACK]                = 'rpc.LoginResult',
    [MSGID.SC_PLAYER_INFO]             = 'rpc.PlayerInfo',
    [MSGID.SC_PLAYER_RESOURCENOTIFY]   = 'rpc.ResourceNotify',
    [MSGID.CS_PLAYER_READ_EMAIL]       = "rpc.ReqReadOneMail",
    [MSGID.CS_PLAYER_GET_ATTACH_EMAIL] = "rpc.ReqReadOneMail",
    [MSGID.CS_PLAYER_REQINVITEFRIEND]  = "rpc.InviteFirendsJionCustomRoomREQ",
    [MSGID.CS_PLAYER_SEND_NOTICE]      = "rpc.ReqBroadCast",
    [MSGID.CS_PLAYER_REQINSURENCEMONEY]= "rpc.ReqInsurenceMoney",
    [MSGID.CS_PLAYER_REQFIGHTCHAT]     = "rpc.FightRoomChatNotify",
    [MSGID.SC_PLYAER_INIT_EMAIL]       = "rpc.PlayerMailInfo",
    [MSGID.SC_PLAYER_ADD_EMAIL]        = "rpc.AddMailNotify",
    [MSGID.SC_PLAYER_REMOVE_EMAIL]     = "rpc.RemoveMailNotify",
    [MSGID.SC_PLAYER_SYS_NOTICE]       = "rpc.BroadCastNotify",
    [MSGID.SC_PLAYER_FIGHT_CHAT]       = "rpc.FightRoomChatNotify",
    [MSGID.SC_PLAYER_INVITEJIONFIGHTNOTIFY] = "rpc.InviteFirendsJionCustomRoomNotify",

    [MSGID.CS_ROOM_ENTERROOMREQ]       = 'rpc.EnterRoomREQ', 
    [MSGID.CS_ROOM_ROOMINFO]           = 'rpc.OnlinePlayerReq', 
    [MSGID.CS_DAER_LEAVEROOMREQ]       = 'rpc.LeaveRoomREQ',
    [MSGID.CS_DAER_ACTIONREQ]          = 'rpc.ActionREQ',
    [MSGID.SC_DAER_ENTERROOMACK]       = 'rpc.EnterRoomACK',
    [MSGID.CS_ROOM_QUICKENTERROOMREQ]  = 'rpc.QuickEnterRoomREQ',
    [MSGID.SC_DAER_LEAVEROOMACK]       = 'rpc.LeaveRoomACK',
    [MSGID.SC_DAER_GAMESTARTACK]       = 'rpc.GameStartACK',
    [MSGID.SC_DAER_ACTIONACK]          = 'rpc.ActionACK',
    [MSGID.SC_DAER_ACTIONNOTIFYACK]    = 'rpc.ActionNotifyACK',
    [MSGID.SC_DAER_COUNTDOWNNOTIFYACK] = 'rpc.CountdownNotifyACK',
    [MSGID.SC_DAER_JIESUANNOTIFYACK]   = 'rpc.JieSuanNotifyACK',
    [MSGID.SC_DAER_PASSCARDNOTIFYACK]  = 'rpc.PassCardNotifyACK',
    [MSGID.SC_DAER_PASSEDNOTIFYACK]    = 'rpc.PassedNotifyACK',
    [MSGID.SC_ROOM_GAMEROOMINFO]       = 'rpc.OnlinePlayerMsg',
    [MSGID.CS_GAME_HEARTBEATREQ]       = 'rpc.HeartBeat',
    [MSGID.SC_GAME_HEARTBEATEACK]      = 'rpc.HeartBeatRst',
    [MSGID.SC_REENTER_FIGHT_NOTIFY]    = 'rpc.PlayerInRoomNotify',

    [MSGID.CS_PLAYER_ENTERCUSTOMROOMREQ] = "rpc.EnterCustomRoomREQ",
    [MSGID.CS_PLAYER_LEAVECUSTOMROOMREQ] = "rpc.LeaveCustomRoomREQ",
    [MSGID.CS_PLAYER_FINDROOMREQ]        = "rpc.FindRoomREQ",
    [MSGID.CS_PLAYER_ROOMLISTREQ]        = "rpc.RoomListREQ",
    [MSGID.CS_PLAYER_CREATEROOMREQ]      = "rpc.CreateRoomREQ",
    [MSGID.CS_PLAYER_KICK_PLAYER]        = "rpc.ForceLeaveRoomREQ",
    [MSGID.CS_PLAYER_REQSIGNIN]          = "rpc.ReqInt",
    [MSGID.CS_PLAYER_REREPLENISHQSIGNIN] = "rpc.ReqInt",
    [MSGID.CS_PLAYER_REQGETTASKAWRD]     = "rpc.ReqInt",
    [MSGID.CS_ACCOUNT_BIND_REQ]          = "rpc.Login",

    [MSGID.SC_PLAYER_CREATEROOMACK]      = "rpc.CreateRoomACK",
    [MSGID.SC_PLAYER_ROOMLISTACK]        = "rpc.RoomListACK",
    [MSGID.SC_PLAYER_ENTERCUSTOMROOMACK] = "rpc.EnterCustomRoomACK",
    [MSGID.SC_PLAYER_LEAVECUSTOMROOMACK] = "rpc.LeaveCustomRoomACK",
    [MSGID.SC_PLAYER_FINDROOMACK]        = "rpc.FindRoomACK",
    [MSGID.SC_PLAYER_CUSTOMROOM_FINALJIESUANNOTIFYACK]  = "rpc.FinalJieSuanNotifyACK",
    [MSGID.SC_PLAYER_SIGNINUPDATE]       = "rpc.Signature",
    [MSGID.SC_PLAYER_TASKUPDATE]         = "rpc.DailyTask",


    [MSGID.CS_FRIEND_REQFRIENDACTION]       = "rpc.ReqResponseAddFriend",               
    [MSGID.CS_FRIEND_REQADDFRIEND]          = "rpc.ReqString",               
    [MSGID.CS_FRIEND_REQREMOVEFRIEND ]      = "rpc.ReqString", 
    [MSGID.CS_FRIEND_REQAPPLYFRIEND]        = "rpc.ReqString", 
    [MSGID.CS_FRIEND_REQSEARCHFRIEND]       = "rpc.ReqInt",           
    [MSGID.CS_FRIEND_REQFIRENDCHAT ]        = "rpc.SendFriendChat",             
    [MSGID.SC_FRIEND_RESALLFRIENDINFO]      = "rpc.FriendsList",          
    [MSGID.SC_FRIEND_RESALLAPPLYFRIENDLIST] = "rpc.RequestFriendsList",      
    [MSGID.SC_FRIEND_RESADDFRIEND]          = "rpc.AddFriendNofify",               
    [MSGID.SC_FRIEND_RESREMOVEFRIEND]       = "rpc.DelFriendNofity",          
    [MSGID.SC_FRIEND_NOTIFYFRIENDONOFFLINE] = "rpc.FriendStatusNofify",     
    [MSGID.SC_FRIEND_RESSEARCHFRIEND]       = "rpc.SearchFriendNofify",           
    [MSGID.SC_FRIEND_RESFIRENDCHAT]         = "rpc.SendFriendChat",        
    [MSGID.SC_FRIEND_OFFLINEMSGNOFITY]      = "rpc.OfflineMsgNofity",     
}

-- 消息对应服务器处理方法
MSGMETHOD = 
{
    [MSGID.CS_LOGINREQ]                     = 'CNServer.Login',
    [MSGID.CS_ROOM_ENTERROOMREQ]            = 'CNServer.EnterRoomREQ',
    [MSGID.CS_DAER_LEAVEROOMREQ]            = 'CNServer.LeaveRoomREQ',
    [MSGID.CS_ROOM_ROOMINFO]                = 'CNServer.GetOnlineInfo',
    [MSGID.CS_DAER_ACTIONREQ]               = 'CNServer.ActionREQ',
    [MSGID.CS_GAME_HEARTBEATREQ]            = 'CNServer.HeartBeatCall',
    [MSGID.CS_ROOM_QUICKENTERROOMREQ]       = 'CNServer.QuickEnterRoomREQ',
    [MSGID.CS_PLAYER_REQINSURENCEMONEY]     = "CNServer.OperateInsurence",
    [MSGID.CS_PLAYER_SEND_NOTICE]           = "CNServer.SendBraodCast",
    [MSGID.CS_PLAYER_READ_EMAIL]            = "CNServer.PlayerReadMail",
    [MSGID.CS_PLAYER_GET_ATTACH_EMAIL]      = "CNServer.GetMailAttach",
    [MSGID.CS_PLAYER_REQFIGHTCHAT]          = "CNServer.SendDeskChat",
    [MSGID.CS_PLAYER_ENTERCUSTOMROOMREQ]    = "CNServer.EnterCustomRoom",
    [MSGID.CS_PLAYER_LEAVECUSTOMROOMREQ]    = "CNServer.LeaveCustomRoom",
    [MSGID.CS_PLAYER_CREATEROOMREQ]         = "CNServer.CreateCustomRoom",
    [MSGID.CS_PLAYER_ROOMLISTREQ]           = "CNServer.ObtainRoomList",
    [MSGID.CS_PLAYER_FINDROOMREQ]           = "CNServer.FindRoom",
    [MSGID.CS_ACCOUNT_BIND_REQ]             = "CNServer.Bind3rdAccount",
    [MSGID.CS_PLAYER_KICK_PLAYER]           = "CNServer.ForceLeaveRoom",
    [MSGID.CS_FRIEND_REQFRIENDACTION]       = "CNServer.ResponseAddFriend",
    [MSGID.CS_FRIEND_REQADDFRIEND]          = "CNServer.AddFriend",
    [MSGID.CS_FRIEND_REQREMOVEFRIEND]       = "CNServer.DelFriend",
    [MSGID.CS_FRIEND_REQSEARCHFRIEND]       = "CNServer.SearchPlayer",
    [MSGID.CS_FRIEND_REQFIRENDCHAT]         = "CNServer.SendFriendChat",
    [MSGID.CS_FRIEND_REQAPPLYFRIEND]        = "CNServer.AddFriend",
    [MSGID.CS_PLAYER_REQINVITEFRIEND]       = "CNServer.InvateFriends",
    [MSGID.CS_PLAYER_REQSIGNIN]             = "CNServer.Signitures",
    [MSGID.CS_PLAYER_REREPLENISHQSIGNIN]    = "CNServer.SignatureBefore",
    [MSGID.CS_PLAYER_REQGETTASKAWRD]        = "CNServer.GetTaskRewards",

}

-- 注册pb
--protobuf.register_file("pb/msg.pb")

-- 发送本地消息
function SendLocalMsg(msgId, content, length, high)
    if not msgId or not content or not length  then
        log_error(LOG_FILE_NAME, " send msg error params msgID:%s, content:%s, len:%d", msgId, content, length)
        return
    end
    high = high or false
    if CCommunicationAgent then
        if type(CCommunicationAgent:GetInstance().SendMsgPriority) == "function" then
            CCommunicationAgent:GetInstance():SendMsgPriority(msgId, content, length, high)
        else
            CCommunicationAgent:GetInstance():SendLocalMsg(msgId, content, length)
        end
    end
end

-- 发往服务器的消息容器
local serverMsgList         = {}            -- 消息队列
local reConnect             = false         -- 是否重连
CMsgRegister.HasSendSuccess = true          -- 消息是否发送成功
CMsgRegister.ServerMsgList  = serverMsgList -- 消息队列


-- 发送服务器消息
-- bHigh:高优先级消息标识（登录消息使用）,否则ActSend()时才真正发送
function SendMsgToServer(msgId, sendData, bHigh)
    local buffer = protobuf.encode(MSGTYPE[msgId], sendData)
    local send_content = {}
    send_content.method             = MSGMETHOD[msgId]
    send_content.serialized_request = buffer
    local pData = protobuf.encode("rpc.Request", send_content)
    local length = #pData

    if msgId ~= MSGID.CS_GAME_HEARTBEATREQ then
        dump(sendData, '===========发送数据:'..MSGTYPE[msgId].."===========", 10)
    end

    if bHigh then

        local _result = CCommunicationAgent:GetInstance():SendMsgToServer(msgId, pData, length)     --msgId在c++层已经弃用
        if msgId ~= 200201 then
            if _result == 0 then
                log_info(LOG_FILE_NAME, "发送消息:%d,消息类型:%s,发送结果:%s", msgId,  MSGTYPE[msgId],  MSG_SED_RSSULT_TYPE[_result])
            else
                log_error(LOG_FILE_NAME, "发送消息:%d,消息类型:%s,发送结果:%s", msgId,  MSGTYPE[msgId],  MSG_SED_RSSULT_TYPE[_result])
            end
        end
    else
        table.insert(serverMsgList, {id = msgId, data = pData, len = length, hasSend = false})
    end
end

-- LuaLogic中每帧调用
function CMsgRegister.SendToServer()
    local lastMsg = serverMsgList[1]
    if not lastMsg then
        return
    end

    CLuaLogic.ConnectServer()

    if CLuaLogic.LoginState == 0 or CLuaLogic.ConnectState == 0 then
        return
    end
    
    -- 每帧发n个包
    for i, msgSend in ipairs(serverMsgList) do
        if msgSend then
            local _result = CCommunicationAgent:GetInstance():SendMsgToServer(msgSend.id, msgSend.data, msgSend.len)
            if msgId ~= 200201 then
                if _result == 0 then
                    log_info(LOG_FILE_NAME, "发送消息:%d,消息类型:%s,发送结果:%s", msgSend.id,  MSGTYPE[msgSend.id],  MSG_SED_RSSULT_TYPE[_result])
                else
                    log_error(LOG_FILE_NAME, "发送消息:%d,消息类型:%s,发送结果:%s", msgSend.id,  MSGTYPE[msgSend.id],  MSG_SED_RSSULT_TYPE[_result])
                end
            end
        end
    end
    serverMsgList = {}

end

CMsgRegister.MsgHandlerList = {}

--注册消息监听函数
function CMsgRegister:RegMsgListenerHandler( msg_id, handler, key)
    key = key or "default"
    local msg_name = MSGTYPE[msg_id]
    if msg_name == nil then
        log_error(LOG_FILE_NAME, "找不到消息号为:%d 对应的消息！", msg_id)
        return
    end
    if self.MsgHandlerList[msg_name] == nil then
        self.MsgHandlerList[msg_name] = {}
    end
    local handler_list = self.MsgHandlerList[msg_name]
    handler_list[key] = handler
end

--注销消息监听函数
function CMsgRegister:UnRegListenerHandler( msg_id, key )
    local msg_name = MSGTYPE[msg_id]
    if msg_name == nil then
        log_error(LOG_FILE_NAME, "找不到消息号为:%d 对应的消息！", msg_id)
        return
    end
    if self.MsgHandlerList[msg_name] == nil then
        return
    end
    key = key or "default"
    local handler_list = self.MsgHandlerList[msg_name]
    handler_list[key] = nil
end

--清空消息注册的所有监听函数
function CMsgRegister:ClearRegListenerHandler( msg_id )
    local msg_name = MSGTYPE[msg_id]
    if msg_name == nil then
        log_error(LOG_FILE_NAME, "找不到消息号为:%d 对应的消息！", msg_id)
        return
    end
    if self.MsgHandlerList[msg_name] == nil then
        return
    end
    self.MsgHandlerList[msg_name] = nil
end


--解析消息并调用注册的监听函数
function ParseMsgAndCallRegFunc(data, len)
    local request = ParseMsgType("rpc.Request", data, len)
    if not request then
        return nil
    end
    local msg_content = ParseMsgType(request.method, request.serialized_request, #request.serialized_request)
    if request.method ~= "rpc.HeartBeatRst" then
        dump(msg_content, '===========接收消息:'..request.method.."===========", 10)
    end

    local handler_list = CMsgRegister.MsgHandlerList[request.method]
    if handler_list ~= nil then
        for k,call_back in pairs(handler_list) do
            call_back(msg_content)
        end
    end
    
    return msg_content
end


function CMsgRegister.ClearMsgList()
    serverMsgList = {}
end

-- 大功能编号 
function MsgFunc(msgId)
    return math.floor(msgId / 1000)
end

-- 消息来源
function MsgScource(msgId)
    return math.floor(msgId / 100) % 10
end

-- 具体处理逻辑
function MsgDetail(msgId)
    return msgId % 100
end


-- 根据消息Id解析消息
function ParseMsgId(msgId, data, len)
    if not MSGTYPE[msgId] then
        log_info(LOG_FILE_NAME, "msgId not find: "..tostring(msgId))
        return nil
    end
    return ParseMsgType(MSGTYPE[msgId], data, len)
end

-- 根据消息类型解析消息解析
function ParseMsgType(msgType, data, len)
    if not msgType or 
       not data or
       type(msgType) ~= "string" or
       type(data) ~= "string" or
       not protobuf.check(msgType)
    then
        log_error(LOG_FILE_NAME, "MsgParser() param error")
        return nil
    end

    local decode, _= protobuf.decode(msgType, data, len)
    local ret = {}

    if not decode then
        log_error(LOG_FILE_NAME, "%s decode failed!", msgType)
        return ret
    end
    
    for k, v in pairs(decode) do
        --嵌套
        if type(v) == "table" and 
            #v == 2 and 
            type(v[1]) == "string" and 
            protobuf.check(v[1]) 
        then
            ret[k] = ParseMsgType(v[1], v[2])
        --repeated
        elseif type(v) == "table" then
            local ret2 = {}
            for k1, v1 in pairs(v) do
                --嵌套
                if type(v1) == "table" and 
                    #v1 == 2 and 
                    type(v1[1]) == "string" and 
                    protobuf.check(v1[1]) 
                then
                    ret2[k1] = ParseMsgType(v1[1], v1[2])
                else
                    ret2[k1] = v1
                end
            end
            ret[k] = ret2
        else
            ret[k] = v
        end
    end
    return ret
end