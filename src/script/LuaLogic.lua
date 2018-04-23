-- [[
-- Copyright (C), 2015, 
-- 文 件 名: LuaLogic.lua
-- 作    者: lyn
-- 版    本: V1.0.0
-- 创建日期: 2015-12-25
-- 完成日期: 
-- 功能描述: 游戏主控制类,主要负责游戏流程, 网络消息分发,触摸事件分发等
-- 其它相关: 
-- 修改记录: 
-- ]]

-- 日志文件名
local LOG_FILE_NAME = 'CLuaLogic.log'

require "script.World.LoginWorld"
require "script.World.GameWorld"

CLuaLogic = {}
CLuaLogic.__index = CLuaLogic

local LOG_FILE_NAME = "CLuaLogic.log";

CLuaLogic.m_pWorld              = nil                               -- 世界指针
local m_curWorldState       = CWorld.EWorld.E_NONE_WORLD            -- 当前世界状态
local m_fUpdateSpeed        = 1.0                                   -- 加速倍数
local m_bIntervalEffect     = false                                 -- 是否固定帧更新
local m_fIntervalTime       = 0.016667000000000                     -- 固定帧更新间隔
local m_fightFixTime        = 0.033333                              -- 战斗逻辑固定帧

CLuaLogic.m_LastTime        = -100                                  -- 上一次连接的时间
CLuaLogic.ConnectState      = 0                                     -- 连接状态 1:连接中 0:未连接
CLuaLogic.LoginState        = 0                                     -- 当前登录状态 1:已经登录 0:未登录

CLuaLogic.ServerIp          = "106.14.46.50"
CLuaLogic.ServerPort        = 7900

CLuaLogic.ServerDevIp       = "211.149.151.119"
CLuaLogic.ServerDevPort     = 7900


CLuaLogic.DevMode           = false

--[[
函数原型: DestroyWorld()
功    能: 销毁世界
参    数: 无
返 回 值: 无
--]]
local function DestroyWorld()
    if CLuaLogic.m_pWorld then
        CLuaLogic.m_pWorld:Destroy()
        CLuaLogic.m_pWorld = nil
    end
end

--[[
函数原型: CreateWorld(eWorld)
功    能: 创建游戏世界
参    数: 
    [IN] eWorld: 世界类型
返 回 值: 无
--]]
local function CreateWorld(eWorld)
    
    -- 创建世界
    if eWorld == CWorld.EWorld.E_LOGIN_WORLD then
        CLuaLogic.m_pWorld = CLoginWorld:New()
    elseif eWorld == CWorld.EWorld.E_GAME_WORLD then
        CLuaLogic.m_pWorld = CGameWorld:New()
    end

    -- 世界创建成功
    if CLuaLogic.m_pWorld then
        m_curWorldState = eWorld

        -- 初始化世界
        local _bInit = CLuaLogic.m_pWorld:Init()
        if _bInit then
            log_info(LOG_FILE_NAME, "[%s]游戏世界初始化成功", CLuaLogic.m_pWorld:GetName())
        end

    -- 世界创建失败
    else
        m_curWorldState = CWorld.EWorld.E_NONE_WORLD
        log_error(LOG_FILE_NAME, "游戏世界创建失败,创建参数:%s", tostring(eWorld))
    end
end

--[[
函数原型: SetCurWorld(eWorld)
功    能: 设置当前世界类型并创建世界
参    数: 
    [IN] eWorld: 世界类型
返 回 值: 无
--]]
local function SetCurWorld(eWorld)

    -- 当前游戏世界不为空
    if m_curWorldState ~= CWorld.EWorld.E_NONE_WORLD then

        -- 改变世界和当前世界一样
        if eWorld == m_curWorldState then
            log_error(LOG_FILE_NAME, "当前世界和想改变的世界相同,切换世界失败,当前世界:%s", CLuaLogic.m_pWorld:GetName())
            return
        end
        DestroyWorld()
    end

    -- 创建新的游戏世界
    CreateWorld(eWorld)
end

function CLuaLogic:ChangeWorld(word)
    SetCurWorld(word)
end


function CLuaLogic:SetDevRunMode( is_dev )
    if is_dev then
        self.ServerIp   = "211.149.151.119"
        --self.ServerIp   = "192.168.8.104"
        self.ServerPort = 7900
    else
        self.ServerIp   = "106.14.46.50"
        self.ServerPort = 7900
    end
    CLuaLogic.DevMode = is_dev
end

--[[
函数原型: CLuaLogic.Init
功    能: 初始化 
参    数: 无
返 回 值: 无
--]]
function CLuaLogic.Init()
    xpcall(function ()

        CLuaLogic:SetDevRunMode(true)
        -- 设置LuaLogic更新函数
        cc.Director:getInstance():getScheduler():scheduleScriptFunc(CLuaLogic.Update, 0, false)

        -- 设置中心提示更新函数
        cc.Director:getInstance():getScheduler():scheduleScriptFunc(NoticeOrder, 0, false)

        -- 设置为登录世界
        SetCurWorld(CWorld.EWorld.E_LOGIN_WORLD)

    end, ErrHandler)
end

--[[
函数原型: CLuaLogic.Destroy
功    能: 退出销毁
参    数: 无
返 回 值: 无
--]]
function CLuaLogic.Destroy()
    xpcall(function ()
        DestroyWorld()
    end, ErrHandler)
end

--[[
-- 函数类型: public
-- 函数功能: 连接失败
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CLuaLogic.ConnectFailed()
    log_error( LOG_FILE_NAME,"连接服务器失败, 请检查你的网络！")
    CLuaLogic.ConnectState = 0
    CLuaLogic.LoginState = 0
    OpenUI("CUICommonTips", "UILogic", {title = "断线重连", content = "当前网络超时，与服务器断开连接！"})
end

--[[
函数原型: CLuaLogic.Update
功    能: 帧更新，供C层调用
参    数: 无
返 回 值: 无
--]]
function CLuaLogic.Update(ft)
    if m_bIntervalEffect then
        ft = m_fIntervalTime
    end

    xpcall(function () 
        if CCommunicationAgent then
            CCommunicationAgent:GetInstance():GetMsg()
        end

        -- 消息发送
        CMsgRegister.SendToServer()
        
        -- 游戏世界更新
        if CLuaLogic.m_pWorld then
            CLuaLogic.m_pWorld:Update(ft)
        end
        
        -- 战斗世界
        if gFightMgr then
            gFightMgr:Update(ft)
        end

        -- 全局时间管理器
        CTimerManager:GetInstance():Update(ft)

        -- 特效管理器
        CAnimationCreateManager:GetInstance():Update(ft)

        -- 文件加载
        if not requireOver then
            ActRequire()
        end

        if NoticeOrder then
            NoticeOrder(ft)
        end
       

    end, ErrHandler)
end

function CLuaLogic.GetWorld()
    return CLuaLogic.m_pWorld
end

--[[
-- 函数类型: public
-- 函数功能: 消息处理，供C++层调用
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
local receive = 0
function CLuaLogic.MessageProc(nMsgId, pData, nLen)
    xpcall(function () 
        -- 接收到消息(C++接收成功回调)
        if MSGSOURCE.SC == MsgScource(nMsgId) then
            receive =  receive + 1
            if nMsgId ~= 102129 and nMsgId ~= 200101 then
                log_info(LOG_FILE_NAME, "成功接收到消息:%d,接收数量:%d,消息类型:%s", nMsgId, receive, MSGTYPE[nMsgId] or '')
            end
        end

        -- C++发送的播放按钮音效
        if nMsgId == MSGID.CC_SOUND then
            print("播放音效", pData)
        end

        -- 发送消息成功(C++发送成功回调)
        if nMsgId == MSGID.CC_SEND_SUCCESS then
            --log_info(LOG_FILE_NAME, "消息发送消息成功.")

        -- 服务器返回ACK
        elseif nMsgId == MSGID.SC_LOGIN_ACK then
            
        end

        -- 改变世界
        if nMsgId == MSGID.CC_CHANGE_WORLD then
            CMsgRegister.ServerMsgList = {}
            local parser = DeserializeFromStr(pData)
            SetCurWorld(parser.eWorldType)
        end
        
        if CLuaLogic.m_pWorld then

            if nMsgId == 0 then
                ParseMsgAndCallRegFunc(pData, nLen)
            else
                CLuaLogic.m_pWorld:MessageProc(nMsgId, pData, nLen)
            end
        end

    end, ErrHandler)
end

--[[
-- 函数类型: public
-- 函数功能: 网络延迟测试
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CLuaLogic.LagNetworkPing()
    CPlayer:GetInstance():ReqVerifySystemTime()
end

--[[
-- 函数类型: public
-- 函数功能: 连接指定ip,端口的服务器
-- 参数[IN]: force = 是否强制连接
             IP = 连接ip
             PORT = 连接端口
-- 返 回 值: 无
-- 备    注:
--]]
function CLuaLogic.ConnectServer(force, IP, PORT)

    -- 是否已连接服务器
    if CLuaLogic.ConnectState == 1 then
        return
    end

    -- IP和端口是否设置
    if not IP or IP == '' or not PORT or PORT == 0 then
        return
    end

    -- 连接间隔 and 是否强制
    local curTime = os.time()
    if curTime - CLuaLogic.m_LastTime < 14 and not force then
        return
    end
    CLuaLogic.m_LastTime = curTime

    local targetPlatform = cc.Application:getInstance():getTargetPlatform()
    if not CLuaLogic.DevMode then
        if cc.PLATFORM_OS_IPHONE == targetPlatform or cc.PLATFORM_OS_IPAD == targetPlatform then
            local ip_addr = WX.WeChatSDKAPIDelegate:GetIpAddressByDomain("www.0830qp.cn")
            if ip_addr then
                log_info(LOG_FILE_NAME, "域名解析成功！IP=%s", ip_addr)
                IP = ip_addr
                --CCommunicationAgent:GetInstance():Connect(ip_addr, tonumber(PORT))
            else
                OpenUI("CUICommonTips", "UILogic", {title = "网络异常", content = "当前网络异常，连接服务器失败。\\n\\t\\t请确保网络通畅后重连！"})
                return
            end
        end
    end
    
    CCommunicationAgent:GetInstance():Connect(IP, tonumber(PORT))
    --Notice("连接IP:" .. IP)
    log_info(LOG_FILE_NAME, "正在连接服务器, 连接IP:%s, 连接PORT:%d", IP, PORT)
end

--[[
-- 函数类型: public
-- 函数功能: 断开连接
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CLuaLogic.DisConnect()
    -- 断开连接
    CCommunicationAgent:GetInstance():DisConnect()
end