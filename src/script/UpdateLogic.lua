--[[
-- Copyright (C), 2015, 
-- 文 件 名: UpdateLogic.lua
-- 作    者: lyn
-- 版    本: V1.0.0
-- 创建日期: 2016-07-28
-- 完成日期: 
-- 功能描述:热更新主逻辑
-- 其它相关: 
-- 修改记录: 
--]]

-- 日志文件名
local LOG_FILE_NAME = 'CUpdateLogic.log'
CUpdateLogic = {}
CUpdateLogic.__index = CUpdateLogic

--[[
-- 函数类型: public
-- 函数功能: 初始化热更新逻辑
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CUpdateLogic.Init()
    -- if GAME_HOT_UPDATE then
    --    local targetPlatform = cc.Application:getInstance():getTargetPlatform()
    --     if cc.PLATFORM_OS_MAC == targetPlatform or cc.PLATFORM_OS_IPHONE == targetPlatform  or cc.PLATFORM_OS_IPAD == targetPlatform or cc.PLATFORM_OS_ANDROID == targetPlatform then
    --         CUpdateLogic.OpenUpdateUI_()
    --         CUpdateLogic.StartUpdate_()
    --     else
    --         CUpdateLogic.UpdaterSuccess_()
    --     end
    -- else
        CUpdateLogic.UpdaterSuccess_()
    --end
end

--[[
-- 函数类型: public
-- 函数功能: 打开热更新界面的UI
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CUpdateLogic.OpenUpdateUI_()

    -- 打开更新资源UI
    if not CUpdateLogic.m_pUpdateUI then   
        CUpdateLogic.m_pUpdateUI = cc.CSLoader:createNode("update/ui_update_loading.csb")
        local _updateUI = CUpdateLogic.m_pUpdateUI
        if _updateUI then
            _updateUI:addTo(GameScene)

            -- 悲剧缩放
            function BackGroundImg(img)
                if img then
                    local size = img:getParent():getContentSize()
                    local point = img:getAnchorPoint();
                    img:setAnchorPoint(cc.p(0, 0))
                    img:setContentSize(cc.size(display.width+1,display.height))
                    if point.x == 0 and point.y == 0 then
                        img:setPosition(0, 0)
                    end
                end
            end

            -- 背景适配
            local _bgImg = _updateUI:getChildByName("login_bg_1")
            BackGroundImg(_bgImg)

            -- 显示更新百分比
            CUpdateLogic.m_textPercent = _updateUI:getChildByName("text_loading_progress")
            -- 更新进度条
            CUpdateLogic.m_barPercent = _updateUI:getChildByName("loading_bar")
            -- 更新提示
            CUpdateLogic.m_textNotice = _updateUI:getChildByName("text_notice")
            -- APK更新提示
            CUpdateLogic.m_nodeNotice = _updateUI:getChildByName("node_apk_notice")
            -- 引擎版本号
            CUpdateLogic.m_nodeNotice = _updateUI:getChildByName("node_apk_notice")
            -- 资源版本号
            CUpdateLogic.m_curTestEngineVersion = _updateUI:getChildByName("text_engine_version")
            CUpdateLogic.m_curTextResVersion = _updateUI:getChildByName("text_res_version")
            CUpdateLogic.m_curTextTargetVersion = _updateUI:getChildByName("text_target_res_version")
            CUpdateLogic.m_textNotice:setString("正在努力更新补丁...")

            -- 重试按钮
            local _noticeNode = _updateUI:getChildByName("node_apk_notice")
            local _retryBtn = _noticeNode:getChildByName("btn_end_game")
            if _retryBtn then
                _retryBtn:addTouchEventListener(function(sender, eventType)
                    if eventType == ccui.TouchEventType.ended then
                        CUpdateLogic.__AssetsManager:update()
                        _noticeNode:hide()
                    end
                end)
            end
                
            
        end
    end
end

function CUpdateLogic.ShowRetryButton()
    local _noticeNode = CUpdateLogic.m_pUpdateUI:getChildByName("node_apk_notice")
    _noticeNode:show()
end

--[[
-- 函数类型: public
-- 函数功能: 关闭更新界面的UI
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CUpdateLogic.CloseUpdateUI()
    if CUpdateLogic.m_pUpdateUI then
        CUpdateLogic.m_pUpdateUI:removeFromParent()
    end
end

--[[
-- 函数类型: public
-- 函数功能: 设置当前版本号
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CUpdateLogic.SetCurResVersion(curVersion)
    CUpdateLogic.m_curTextResVersion:setString('当前资源版本号:'..curVersion)
    print("curVersion:", curVersion)
end

--[[
-- 函数类型: public
-- 函数功能: 设置目标版本号
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CUpdateLogic.SetTargetResVersion(tarVersion)
    CUpdateLogic.m_curTextTargetVersion:setString('最新资源版本号:'..tarVersion)
    print("tarVersion:", tarVersion)    
end

--[[
-- 函数类型: public
-- 函数功能: 设置更新进度
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CUpdateLogic.SetUpdatePercent(percent)
    if CUpdateLogic.m_textPercent then
        CUpdateLogic.m_textPercent:setString(math.ceil(percent).."%")
    end

    if CUpdateLogic.m_barPercent then
        CUpdateLogic.m_barPercent:setPercent(math.ceil(percent))
    end
end

--[[
-- 函数类型: public
-- 函数功能: 开始热更新
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CUpdateLogic.StartUpdate_()

    local MAIN_FESTS_FILE = "version/project.manifest"
    local DOWN_LOAD_PATH = cc.FileUtils:getInstance():getWritablePath()
    
    if CUpdateLogic.__AssetsManager then       
        cc.Director:getInstance():getEventDispatcher():removeEventListener(CUpdateLogic._listenerAssetsManagerEx)
        CUpdateLogic.__AssetsManager:release()
        CUpdateLogic._listenerAssetsManagerEx = nil
        CUpdateLogic.__AssetsManager = nil
    end

    CUpdateLogic.__AssetsManager = cc.AssetsManagerEx:create(MAIN_FESTS_FILE, DOWN_LOAD_PATH)
    CUpdateLogic.__AssetsManager:retain()

    CUpdateLogic._failCount = 0

    if not CUpdateLogic.__AssetsManager:getLocalManifest():isLoaded() then
        print("AssetsManager:getLocalManifest Error")
    else
        CUpdateLogic._listenerAssetsManagerEx = cc.EventListenerAssetsManagerEx:create(CUpdateLogic.__AssetsManager,  CUpdateLogic.OnUpdateEvent_)
        cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(CUpdateLogic._listenerAssetsManagerEx, 1)
        CUpdateLogic.__AssetsManager:update()
    end
end

--[[
-- 函数类型: public
-- 函数功能: 热更新中事件
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CUpdateLogic.OnUpdateEvent_(event)
    local eventCode = event:getEventCode()

    if eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_NO_LOCAL_MANIFEST then
        print("[AssetsManager Error]: No local manifest file found")
        
        if CUpdateLogic.m_textNotice then
            CUpdateLogic.m_textNotice:setString("配置文件错误，请清空缓存数据重新下载。")
        end
    
    elseif eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_DOWNLOAD_MANIFEST then
        print("[AssetsManager Error]: download manifest file fail")
        
        if CUpdateLogic.m_textNotice then
            CUpdateLogic.m_textNotice:setString("配置文件更新失败!") 
        end

    
    elseif eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_PARSE_MANIFEST then
        print("[AssetsManager Error]: parse manifest file fail")
        
        if CUpdateLogic.m_textNotice then
            CUpdateLogic.m_textNotice:setString("配置文件更新失败!")
        end
    
    elseif eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_MUST_UPDATE_APP then
        print("[AssetsManager Error]: must update app")

        if CUpdateLogic.m_nodeNotice then
            CUpdateLogic.m_nodeNotice:show()
            local _btnEndGame = CUpdateLogic.m_nodeNotice:getChildByName("btn_end_game")
            if _btnEndGame then
                _btnEndGame:addTouchEventListener(function(sender, eventType)
                    if eventType == ccui.TouchEventType.ended then
                        cc.Director:getInstance():endToLua()
                        --TODO:前往下载地址
                    end
                end)
            end
        end
    
    elseif eventCode == cc.EventAssetsManagerEx.EventCode.NEW_VERSION_FOUND then

        -- 获取远程更新配置
        local _remoteManifet =  CUpdateLogic.__AssetsManager:getRemoteManifest()
        
        -- 获取本地更新配置
        local _localManifet = CUpdateLogic.__AssetsManager:getLocalManifest()

        -- 设置引擎版本号信息
            --TODO:

        -- 设置当前资源版本号信息
        CUpdateLogic.SetCurResVersion(_localManifet:getVersion() or '0')

        -- 设置目标资源版本号信息
        CUpdateLogic.SetTargetResVersion(_remoteManifet:getVersion())

        print("[AssetsManager Info]: found new version")
    
    elseif eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_PROGRESSION then
        local assetId = event:getAssetId()
        local percent = event:getPercent()
        local percentByFile = event:getPercentByFile()     

        if assetId == cc.AssetsManagerExStatic.VERSION_ID then
            print( string.format("update progression: Version file, percent = %d%%, percentByFile = %d%%", percent, percentByFile) )
        elseif assetId == cc.AssetsManagerExStatic.MANIFEST_ID then
            print( string.format("update progression: Manifest file, percent = %d%%, percentByFile = %d%%", percent, percentByFile) )
        else
            CUpdateLogic.SetUpdatePercent(percentByFile)
            print( string.format("update progression: AssetId = %s, percent = %d%%, percentByFile = %d%%", assetId, percent, percentByFile) )
        end
    
    elseif eventCode == cc.EventAssetsManagerEx.EventCode.ASSET_UPDATED then
        print("[AssetsManager Info]: Asset updated")
    
    elseif eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_UPDATING then
        print("[AssetsManager Error]: error updating, AssetId = " .. event:getAssetId() .. ", Message = " .. event:getMessage())
    
    elseif eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_FAILED then
        CUpdateLogic._failCount = CUpdateLogic._failCount + 1
        if (CUpdateLogic._failCount < 5) then
            CUpdateLogic.__AssetsManager:downloadFailedAssets()
        else
            print("[AssetsManager Error]: Reach maximum fail count, exit update process")
            CUpdateLogic._failCount = 0
        end
    
    elseif eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_DECOMPRESS then
        print("[AssetsManager Error]: error decompress, Message = " .. event:getMessage())
    
    elseif (eventCode == cc.EventAssetsManagerEx.EventCode.ALREADY_UP_TO_DATE) or
            (eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_FINISHED) then
        print("[AssetsManager Info]: updated finished")

        -- 获取本地更新配置
        local _localManifet = CUpdateLogic.__AssetsManager:getLocalManifest()

        -- 设置当前资源版本号信息
        CUpdateLogic.SetTargetResVersion(_localManifet:getVersion() or '0')

        cc.Director:getInstance():getEventDispatcher():removeEventListener(CUpdateLogic._listenerAssetsManagerEx)
        CUpdateLogic.__AssetsManager:release()
        CUpdateLogic._listenerAssetsManagerEx = nil
        CUpdateLogic.__AssetsManager = nil

        CUpdateLogic:UpdaterSuccess_()
    end
end

--[[
-- 函数类型: public
-- 函数功能: 热更新成功
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CUpdateLogic.UpdaterSuccess_()
    if GameScene then
        GameScene:SetAppState(GAME_STATE_TYPE.GAME_STATE)
        CUpdateLogic.Destroy()        
    end
end

--[[
-- 函数类型: public
-- 函数功能: 虚构热更新逻辑
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CUpdateLogic.Destroy()
    CUpdateLogic.CloseUpdateUI()
end