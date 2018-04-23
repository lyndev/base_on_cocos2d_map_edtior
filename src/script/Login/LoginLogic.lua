-- [[
-- Copyright (C), 2015, 
-- 文 件 名: LoginLogic.lua
-- 作    者: lyn
-- 版    本: V1.0.0
-- 创建日期: 2015-12-28 
-- 完成日期: 
-- 功能描述: 
-- 其它相关: 
-- 修改记录: 
-- ]]

-- 日志文件名
local LOG_FILE_NAME = 'CLoginLogic.log'

CLoginLogic = {} 
CLoginLogic.__index = CLoginLogic
 
--登录失败原因枚举
local ELoginFailedReason = 
{
    EACCOUNTCHECKFAILED = 1,   -- 账号验证未通过
    EDONTHAVEROLE       = 2,   -- 没有角色
    NEED_ACTIVE_CODE    = 3,   -- 需要激活码
    APP_VERSION_ERROR   = 4,   -- 客户端版本错误
}

CLoginLogic.LoginType = 
{
    Tourist     = 0,    --游客登录
    WeChat      = 1,    --微信登录
}

--[[
-- 函数功能: 创建登录逻辑
-- 参    数: 需要增加的变量以及函数table
-- 返 回 值: 登录逻辑对象
-- 备    注: 无
--]]
function CLoginLogic:New(o)
    o = o or {}
    setmetatable(o, CLoginLogic)
    o.m_LoginUI         = nil                  -- 登录UI
    o.m_bIsRegister     = false                -- 是否是注册界面进入
    o.m_loginInfo        = {}                   -- 储存一些数据的表
    o.m_bIsCreateUser   = false                -- 是否是创建玩家
    return o
end

function CLoginLogic:GetInstance()
    if not CLoginLogic._instance then
        CLoginLogic._instance = self:New()
    end
    return  CLoginLogic._instance
end

function CLoginLogic:GetIsConnect()
    return CLuaLogic.ConnectState
end

--[[
-- 函数功能: 登录逻辑初始化
-- 参    数: 无
-- 返 回 值: 无
-- 备    注: 无
--]]
function CLoginLogic:Init() 
    CMsgRegister:RegMsgListenerHandler(MSGID.SC_LOGINACK, function ( msgData )
        self:OnLoginAck(msgData)
    end, "LoginLogic_LoginAck")

    CMsgRegister:RegMsgListenerHandler(MSGID.SC_PLAYER_INFO, function ( msgData )
        self:SetPlayerInfo(msgData)
    end, "LoginLogic_PlayerInfo")   

    -- 打开登录UI
    local msg = {name = "CUIEditorMain", FolderName = "UILogic"}
    local buf = SerializeToStr(msg)
    SendLocalMsg(MSGID.CC_OPEN_UI, buf, #buf)

    --CLuaLogic.ConnectServer(true, CLuaLogic.ServerIp, CLuaLogic.ServerPort)
end

-- 函数功能: 处理登录回复
-- 参    数: 无
-- 返 回 值: 无
-- 备    注:
function CLoginLogic:OnLoginAck( msgData )
    if msgData.result == "ok" then
        if self.m_bIsCreateUser then
            -- 设置角色UID
            CSystemSetting:GetInstance():SetSetting(CSystemSetting.KEY_TYPE.PLAYERUID, LocalStringEncrypt(msgData.uid), "string")
            CSystemSetting:GetInstance():SetSetting(CSystemSetting.KEY_TYPE.ROLEID, LocalStringEncrypt(msgData.roleId), "string")
            print("========================================")   
            print("\t\t用户创建成功                ")
            print("========================================")
        else
            print("========================================")     
            print("\t\t用户登录成功                ")     
            print("========================================") 
        end
        CPlayer:GetInstance():SetLoginTime(msgData.server_time)
        -- 设置为登录状态:登录
        CLuaLogic.LoginState = 1
        self.m_bIsCreateUser = false
    end
end

-- 函数功能: 设置玩家信息
-- 参    数: 无
-- 返 回 值: 无
-- 备    注:
function CLoginLogic:SetPlayerInfo( msgData )
    CPlayer:GetInstance():Init(msgData)
    CLuaLogic:ChangeWorld(CWorld.EWorld.E_GAME_WORLD)
end

function CLoginLogic:Update(dt)

end

--[[
-- 函数功能: 登录逻辑消息处理函数
-- 参    数: 
--     [IN] nMsgId: 消息ID
--     [IN] pData: 消息数据
--     [IN] nLen: 消息数据长度
-- 返 回 值: 登录逻辑对象
-- 备    注: 无
--]]
function CLoginLogic:MessageProc(nMsgId, pData, nLen)    
    local funcId = MsgFunc(nMsgId)

    -- 连接服务器成功
    if (nMsgId == MSGID.CC_CONNECT_SUCCESS) then        
        print("========================================")     
        print("\t\t连接服务器成功                ")     
        print("========================================")  

        -- 设置为连接状态:已连接
        CLuaLogic.ConnectState = 1

        -- 设置分分包分包对象类型：1 = 代理服务器 2 = 游戏服务器
        CCommunicationAgent:GetInstance():SetAnalyticPacketEx(2)
        
        --self:StartLogin()

        --Notice("连接服务器成功")
        CloseUI("CUICommonTips")
    -- 连接服务器失败
    elseif (nMsgId == MSGID.CC_CONNECT_FAILED) then          
        
        CLuaLogic.ConnectFailed()

        --TODO:弹出重新连接的对话框
        --OpenUI("CUICommonTips", "UILogic", {title = "网络异常", content = "连接服务器失败, 请检查你的网络！"})
    -- 服务器连接断开
    elseif nMsgId == MSGID.CC_CONNECT_BREAK then           
        
        log_info(LOG_FILE_NAME, "与连接服务器断开!")

        -- 设置连接状态:未连接
        CLuaLogic.ConnectState = 0 

        -- 设置登录状态:未登录
        CLuaLogic.LoginState   = 0

        --Notice("与连接服务器断开!")
        OpenUI("CUICommonTips", "UILogic", {title = "登录超时", content = "登录超时，请大侠重新登录！"})
        --CLuaLogic.ConnectFailed()

    -- 服务器主动关闭连接消息
    elseif nMsgId == MSGID.SC_LOGIN_RESCLOSESOCKET then    
        
        log_info(LOG_FILE_NAME, "服务器主动断开!")

        -- 设置连接状态:未连接
        CLuaLogic.ConnectState = 0

        -- 设置登录状态:未登录
        CLuaLogic.LoginState   = 0

        --Notice("服务器主动断开!")

        --CLuaLogic.ConnectFailed()
        OpenUI("CUICommonTips", "UILogic", {title = "掉线通知", content = "当前网络超时，与服务器断开连接！"})

      -- 系统提示
    elseif MSGID.SC_PLAYER_TIPSNOTIFY == nMsgId then
        local msgData = ParseMsgId(nMsgId, pData, nLen)
        Notice(Language(msgData.tipsId or 0))
        if msgData.tipsMsg then
            Notice(msgData.tipsMsg)
        end
    --微信获取access_token后返回
    elseif nMsgId == 1601 then
        local resp_data = WX.WeChatSDKAPIDelegate:GetHttpResponseData()
        local json_data = json.decode(resp_data)
        if json_data.errcode then
            --TODO：弹出错误提示
            print("登录失败!")
        else
            --access_token是调用授权关系接口的调用凭证，由于access_token有效期（目前为2个小时）较短，所以登录后，立即刷新
            WX.WeChatSDKAPIDelegate:RefreshAccessToken(json_data.refresh_token)
        end
    --刷新access_token后返回
    elseif nMsgId == 1602 then
        local resp_data = WX.WeChatSDKAPIDelegate:GetHttpResponseData()
        --print("--------refresh_data=" .. resp_data)
        local refresh_data = json.decode(resp_data)
        if refresh_data.errcode then
                --刷新超时后，则重新授权
                WX.WeChatSDKAPIDelegate:SendAuthRequest("snsapi_userinfo", "luzhouqipai_wechat_login_req")
        else
            --refresh_token拥有较长的有效期（30天），当refresh_token失效的后，需要用户重新授权，
            --所以，请开发者在refresh_token即将过期时（如第29天时），进行定时的自动刷新并保存好它。
            --记录下app_id, access_token, refresh_token
            --CSystemSetting:GetInstance():SetSetting(CSystemSetting.KEY_TYPE.OPENID, LocalStringEncrypt(refresh_data.openid), "string")
            --CSystemSetting:GetInstance():SetSetting(CSystemSetting.KEY_TYPE.ACCESS_TOKEN, LocalStringEncrypt(refresh_data.access_token), "string")
            CSystemSetting:GetInstance():SetSetting(CSystemSetting.KEY_TYPE.REFRESH_TOKEN, LocalStringEncrypt(refresh_data.refresh_token), "string")
            WX.WeChatSDKAPIDelegate:GetUserInfo(refresh_data.access_token, refresh_data.openid)
        end
    --获取用户信息后返回
    elseif nMsgId == 1603 then
        local resp_data = WX.WeChatSDKAPIDelegate:GetHttpResponseData()
        resp_data = string.gsub(resp_data,"\\","")
        local user_info_data = json.decode(resp_data)
        --微信登录只需要向服务器发送openid即可，服务器会根据当前的情况来登录或者创建账号
        local login_data = {}
        login_data.openid = user_info_data.openid
        login_data.headerUrl = user_info_data.headimgurl
        login_data.nickName  = user_info_data.nickname
        login_data.sex       = user_info_data.sex - 1
        SendMsgToServer(MSGID.CS_LOGINREQ, login_data, true)
        --WX.WeChatSDKAPIDelegate:ReqestHeadImg(user_info_data.headimgurl,"user_head")
    --获取通过url创建的头像
    elseif nMsgId == 1604 then
        local head_sprite = WX.WeChatSDKAPIDelegate:GetHeadImage()
        if head_sprite then
            local login_ui = CUIManager:GetInstance():GetUIByName("CUILogin")
            
            local clip_head = GetCircleHeadImg(head_sprite)
            clip_head:setPosition(640, 360)
            login_ui.m_pRootForm:addChild(clip_head)

        end

    elseif nMsgId == 1701 then
        print("---分享聊天成功--")
        
    elseif nMsgId == 1702 then
        print("---分享朋友圈成功--")
    -- UI消息
    elseif MSGFUNC.UI == funcId then 
        CUIManager:GetInstance():MessageProc(nMsgId, pData, nLen)
    end
end

-- 函数功能: 微信登录
-- 参    数: 无
-- 返 回 值: 无
-- 备    注:
function CLoginLogic:WeChatLogin( )
    local is_installed = WX.WeChatSDKAPIDelegate:CheckWXInstalled()
    if not is_installed then
        Notice("请安装微信客户端后登录！")
        return
    end
    -- local openid = CSystemSetting:GetInstance():GetSetting(CSystemSetting.KEY_TYPE.OPENID, "string")
    -- local access_token = CSystemSetting:GetInstance():GetSetting(CSystemSetting.KEY_TYPE.ACCESS_TOKEN, "string")
    local refresh_token = CSystemSetting:GetInstance():GetSetting(CSystemSetting.KEY_TYPE.REFRESH_TOKEN, "string")
    if refresh_token == "" then
        --微信认证
        --注：不要随意更改参数，会导致验证不通过
        WX.WeChatSDKAPIDelegate:SendAuthRequest("snsapi_userinfo", "luzhouqipai_wechat_login_req")
    else
        --刷新token
        WX.WeChatSDKAPIDelegate:RefreshAccessToken(LocalStringEncrypt(refresh_token))
    end
end
-- 函数功能: 游客登录
-- 参    数: 无
-- 返 回 值: 无
-- 备    注:
function CLoginLogic:TouristLogin(  )
    local roleId = CSystemSetting:GetInstance():GetSetting(CSystemSetting.KEY_TYPE.ROLEID, "string")
    local uid = CSystemSetting:GetInstance():GetSetting(CSystemSetting.KEY_TYPE.PLAYERUID, "string")
    self.m_bIsCreateUser = true
    local login_data = {}
    if roleId ~= "" and uid ~= "" then
        login_data.uid = LocalStringEncrypt(uid)
        login_data.roleId = LocalStringEncrypt(roleId)
        self.m_bIsCreateUser = false
    end
    SendMsgToServer(MSGID.CS_LOGINREQ, login_data, true)
end

-- 函数功能: 开始登录
-- 参    数: 无
-- 返 回 值: 无
-- 备    注:
function CLoginLogic:StartLogin( login_type )
    if login_type == CLoginLogic.LoginType.Tourist then
        self:TouristLogin()
    elseif login_type == CLoginLogic.LoginType.WeChat then
        self:WeChatLogin()
    end
end

-- 函数功能: 重置登录信息
-- 参    数: 无
-- 返 回 值: 无
-- 备    注:
function CLoginLogic:ResetLoginInfo(  )
    CSystemSetting:GetInstance():SetSetting(CSystemSetting.KEY_TYPE.REFRESH_TOKEN, "", "string")
end

--[[
-- 函数类型: public
-- 函数功能: 保存玩家信息
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CLoginLogic:SavePlayerInfo(roleId, roleName, roleHeadId)
    if not roleId or not roleName or not roleHeadId then
        log_error(LOG_FILE_NAME, '保存玩家的信息失败!')
        return
    end
    self.m_userInfo.roleId  =  roleId
    self.m_userInfo.roleName = roleName
    self.m_userInfo.imgUrl  = roleHeadId

    -- 设置角色ID
    CPlayer:GetInstance():SetRoleID(roleId)

    -- 角色名字
    CPlayer:GetInstance():SetUserName(roleName)

    -- 设置角色头像ID
    CPlayer:GetInstance():SetHeadID(roleHeadId)
end

--[[
-- 函数功能: 登录逻辑销毁
-- 参    数: 无
-- 返 回 值: 无
-- 备    注: 无
--]]      
function CLoginLogic:Destroy()
    gPublicDispatcher:RemoveEventListenerObj(self)
    CMsgRegister:ClearRegListenerHandler(MSGID.SC_LOGINACK)
    CMsgRegister:ClearRegListenerHandler(MSGID.SC_PLAYER_INFO)
end