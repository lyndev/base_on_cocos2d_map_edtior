-- [[
-- Copyright (C), 2015, 
-- 文 件 名: GameObject.lua
-- 作    者: lyn
-- 版    本: V1.0.0
-- 创建日期: 2016-01-08
-- 完成日期: 
-- 功能描述: 游戏对象基类 ---- from cocos2d quick3.5
-- 其它相关: 
-- 修改记录: 
-- ]]

local Registry = Import(".Registry")

local GameObject = {}

function GameObject.Extend(target)
    if not target.components_ then
        target.components_ = {}
    end

    function target:CheckComponent(name)
        return self.components_[name] ~= nil
    end

    function target:AddComponent(name)
        local component = Registry.newObject(name)
        self.components_[name] = component
        component:bind_(self)
        return component
    end

    function target:RemoveComponent(name)
        local component = self.components_[name]
        if component then component:unbind_() end
        self.components_[name] = nil
    end

    function target:GetComponent(name)
        return self.components_[name]
    end

    return target
end

return GameObject
