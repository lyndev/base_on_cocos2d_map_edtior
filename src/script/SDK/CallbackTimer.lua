require "script/SDK/TimerEvent"

CCallbackTimer = class("CCallbackTimer", CTimerEvent)
CCallbackTimer.type = "CCallbackTimer"

function CCallbackTimer:New(obj,param, func, times, interval)
    local o = {}
    setmetatable(o, CCallbackTimer)
    o:Init(obj, param, func, times, interval)
    return o
end

function CCallbackTimer:Init(obj, param, func, times, interval)
    self.m_Obj = obj
    self.m_Func = func
    self.m_Param = param
    self:TimerEventByDelay(times, interval)
end

function CCallbackTimer:Action()
    CTimerEvent.Action(self)
    self.m_Func(self.m_Obj, self.m_Param)
end