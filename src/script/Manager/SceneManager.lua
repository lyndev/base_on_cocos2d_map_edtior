--[[
-- Copyright (C), 2015, 
-- 文 件 名: SceneManager.lua
-- 作    者: lyn
-- 版    本: V1.0.0
-- 创建日期: 2016-02-24
-- 完成日期: 
-- 功能描述: 
-- 其它相关: 
-- 修改记录: 
--]]

-- 日志文件名
local LOG_FILE_NAME = 'CSceneManager.log'

CSceneManager = {}
CSceneManager.__index = CSceneManager
CSceneManager._instance = nil

function CSceneManager:New()
    local o = {}
    o.m_curShowScene = nil
    setmetatable( o, CSceneManager )
    return o
end

function CSceneManager:GetInstance( msg )
    if not CSceneManager._instance then
        CSceneManager._instance = self:New()
    end
    return  CSceneManager._instance
end

function CSceneManager:Init( param )
end

-- 场景创建
function CSceneManager:CreateSceneByID( sceneID )
    local _path = Q_Scene.GetTempData(sceneID, "q_path")
    if _path and type(_path) == 'string' then
        local _nodeScene = cc.CSLoader:createNode(_path)
        if _nodeScene then
            self.m_curShowScene = _nodeScene
            return _nodeScene
        else
            log_error(LOG_FILE_NAME, "场景文件创建失败")
        end
    else
        log_error(LOG_FILE_NAME, "场景文件创建失败, 配置表数据配置错误")
    end
end

-- 获取当前显示的场景
function CSceneManager:GetShowScene()
    return self.m_curShowScene
end

-- 异步加载场景资源
function CSceneManager:LoadResourceAsync()

end

-- 加载完成回调
function CSceneManager:LoadResourceAsyncCallBack()
	
end

function CSceneManager:Destroy()
    CSceneManager._instance = nil
end
