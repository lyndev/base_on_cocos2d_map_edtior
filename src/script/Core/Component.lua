-- [[
-- Copyright (C), 2015, 
-- 文 件 名: Component.lua
-- 作    者: lyn
-- 版    本: V1.0.0
-- 创建日期: 2016-01-08
-- 完成日期: 
-- 功能描述: 组件基类 ---- from cocos2d quick3.5
-- 其它相关: 
-- 修改记录: 
-- ]]

local GameObject = Import(".GameObject")
local Component = class("Component", GameObject)

function Component:ctor(name, depends)
    self.name_ = name
    self.depends_ = checktable(depends)
end

function Component:getName()
    return self.name_
end

function Component:getDepends()
    return self.depends_
end

function Component:getTarget()
    return self.target_
end

function Component:exportMethods_(methods)
    self.exportedMethods_ = methods
    local target = self.target_
    local com = self
    for _, key in ipairs(methods) do
        if not target[key] then
            local m = com[key]
            target[key] = function(__, ...)
                return m(com, ...)
            end
        end
    end
    return self
end

function Component:bind_(target)
    self.target_ = target
    for _, name in ipairs(self.depends_) do
        if not target:CheckComponent(name) then
            target:AddComponent(name)
        end
    end
    self:onBind_(target)
end

function Component:unbind_()
    if self.exportedMethods_ then
        local target = self.target_
        for _, key in ipairs(self.exportedMethods_) do
            target[key] = nil
        end
    end
    self:onUnbind_()
end

function Component:onBind_()
end

function Component:onUnbind_()
end

return Component
