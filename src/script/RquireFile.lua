-- 垃圾回收 
collectgarbage("setpause", 100)  
collectgarbage("setstepmul", 5000) 

-- 游戏核心类
require "script.Utility"
require "script.Core.Import"
require "script.Core.Registry"
Component  = require "script.Core.Component"
GameObject = require "script.Core.GameObject"

-- 游戏SDK
require "script.SDK.IDMaker"
require "script.SDK.Log"
require "script.SDK.MusicPlayer"
require "script.SDK.EventDispatcher"
require "script.SDK.MsgEventDispatcher"
require "script.SDK.PlistCache"
require "script.SDK.Event"
require "script.SDK.json"
require "script.SDK.TimerBase"
require "script.SDK.TimerManager"
require "script.SDK.TimerEvent"
require "script.SDK.TimerUtility"
require "script.SDK.SimpleQueue"
require "script.SDK.utf8"
require "script.SDK.UIOpenStack"

-- 功能模块
require "script.ENUM"
require "script.MsgRegister"
require "script.LuaLogic"
require "script.Animation.AnimationCreateManager"
require "script.Entity.TemplateFactory"
require "script.Entity.EntityManager"
require "script.Entity.Player"
require "script.Manager.SystemSetting"
require "script.Manager.LocalNotice"
require "script.Manager.UIManager"
require "script.Manager.WidgetManager"
require "script.Manager.SceneManager"
require "script.Manager.ResLoadManager"
require "script.Manager.UILoadingManager"
require "script.Manager.ResCachePoolManager"
require "script.Manager.SignInManager"
require "script.Manager.UINoticeForCenterManager"
require "script.Manager.FuntionManager"
require "script.Manager.FightDaerManager"
require "script.Manager.LobbyManager"
require "script.Manager.MarqueeManager"
require "script.Manager.FriendManager"
dirtywords = require "script.DirtyWord.dirtywords"
require "script.DirtyWord.dirtyword"    
require "script.ResConfig" 
--utils = require "script.Utils.init" 

-- 配置表加载
-- TODO:直接加载的配置表

require "script.ConfigData.q_exp"
require "script.ConfigData.q_global"
require "script.ConfigData.q_language"
require "script.ConfigData.q_room"
require "script.ConfigData.q_music"
require "script.ConfigData.q_fixword"
require "script.ConfigData.q_chatface"
require "script.ConfigData.q_zj_room"
require "script.ConfigData.q_item"
require "script.ConfigData.q_task"
require "script.ConfigData.q_animationeffect"


-- AddRequire:先加入加载队列,每帧加载几个,防止一次加载过多卡顿
-- AddRequire("data.Q_Res")
