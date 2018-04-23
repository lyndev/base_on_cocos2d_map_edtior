--[[
-- Copyright (C), 2015, 
-- 文 件 名: EquipManager.lua
-- 作    者: lyn
-- 版    本: V1.0.0
-- 创建日期: 2016-03-15
-- 完成日期: 
-- 功能描述: 坦克的装备，道具管理器
-- 其它相关: 
-- 修改记录: 
--]]

-- 日志文件名
local LOG_FILE_NAME = 'CEquipManager.log'

require "script.Item.Goods"

CEquipManager = {}
CEquipManager.__index = CEquipManager
CEquipManager._instance = nil

-- 装备和道具的操作枚举
local EEQUIP_OPERATOR_TYPE = 
{
    UNLOAD_LOAD          = 1,     -- 卸下并装配装备  
    DESTORY_LOAD         = 2,     -- 销毁并装配装备
    LOAD                 = 3,     -- 直接装配装备 
    BUY_LOAD             = 4,     -- 购买并穿戴
    BUY_DESTORYLAST_LOAD = 5,     -- 购买并摧毁并穿戴
    BUY_UNLOADLAST_LOAD  = 6,     -- 购买并卸载并穿戴
}

local EEQUIP_DIRECTION_OPERATOR_TYPE = 
{
    DESTORY         = 1,       -- 销毁  
    UNLOAD          = 2,       -- 卸下
}

local Equip_Struct = 
{
    [1]     = {type = CGoods.EGoodsSubType.ESUBTYPE_EQUIPMENT,          number = 0, templateID = 0 },   -- 副装甲位
    [2]     = {type = CGoods.EGoodsSubType.ESUBTYPE_ITEM,               number = 0, templateID = 0 },   -- 道具位1
    [3]     = {type = CGoods.EGoodsSubType.ESUBTYPE_ITEM,               number = 0, templateID = 0 },   -- 道具位2
    [4]     = {type = CGoods.EGoodsSubType.ESUBTYPE_MOUNT_EQUIPMENT,    number = 0, templateID = 0 },   -- 挂件位1
    [5]     = {type = CGoods.EGoodsSubType.ESUBTYPE_MOUNT_EQUIPMENT,    number = 0, templateID = 0 },   -- 挂件位2 
}

--[[
-- 函数类型: public
-- 函数功能: 构造一个装备管理器对象
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CEquipManager:New()
    local o = {}
    setmetatable( o, CEquipManager )
    o.tTankEquipMap = {}                -- key = 坦克模版ID, 当前装备列表结构(Equip_Struct)

    return o
end

--[[
-- 函数类型: public
-- 函数功能: 单例获取
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CEquipManager:GetInstance( msg )
    if not CEquipManager._instance then
        CEquipManager._instance = self:New()
    end
    return  CEquipManager._instance
end

--[[
-- 函数类型: public
-- 函数功能: 初始化
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CEquipManager:Init(param)
end

--[[
-- 函数类型: public
-- 函数功能: 获取坦克当前装配的道具和装备
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CEquipManager:GetEquipConfigMap( nTankTemplateID )
	return self.tTankEquipMap[nTankTemplateID] or {}
end

--[[
-- 函数类型: public
-- 函数功能: 获取可装配的装备
-- 参数[IN]: 坦克模版ID
-- 返 回 值: 无
-- 备    注:
--]]
function CEquipManager:GetCanUseEquip( nTankTemplateID )
    local _tankInfo = CTankPackage:GetInstance():GetTankByTemplateID(nTankTemplateID)
    if _tankInfo then
        local _strCanUseEquip = _tankInfo:GetCanUseEquip()
        local _tCanUserEquip = StrSplit(_strCanUseEquip, '_')
        for i,v in ipairs(_tCanUserEquip) do
            _tCanUserEquip[i] = tonumber(v)
            return _tCanUserEquip
        end
    end
end

--[[
-- 函数类型: public
-- 函数功能: 获取可装配的挂件
-- 参数[IN]: 坦克模版ID
-- 返 回 值: 无
-- 备    注:
--]]
function CEquipManager:GetCanUseMountEquip( nTankTemplateID )
    local _tankInfo = CTankPackage:GetInstance():GetTankByTemplateID(nTankTemplateID)
    if _tankInfo then
        local _strCanUseMountEquip = _tankInfo:GetCanUseMountEquip()
        local _tCanUseMountEquip = StrSplit(_strCanUseMountEquip, '_')
        for i,v in ipairs(_tCanUseMountEquip) do
            _tCanUseMountEquip[tonumber(v)] = tonumber(v)
        end
        return _tCanUseMountEquip
    end
end

--[[
-- 函数类型: public
-- 函数功能: 获取可装备的皮肤 
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CEquipManager:GetCanUseSkin(nTankTemplateID)
    local _tankInfo = CTankPackage:GetInstance():GetTankByTemplateID(nTankTemplateID)
    if _tankInfo then
        local _strCanUseSkin = _tankInfo:GetTankCanChangeSkin()
        local _tCanUseSkin = StrSplit(_strCanUseSkin, '_')
        for i,v in ipairs(_tCanUseSkin) do
            _tCanUseSkin[i] = tonumber(v)
        end
        return _tCanUseSkin
    end
end

--[[
-- 函数类型: public
-- 函数功能: 设置配置当前携带的道具
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CEquipManager:SetCurrentConfigProp( nItemID, pos, number )
    self:SetTemplateForEquipPos_(nItemID, pos, number)
end

--[[
-- 函数类型: public
-- 函数功能: 设置配置当前使用的副装甲
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CEquipManager:SetCurrentConfigEquip( nEquipID, pos )
    self:SetTemplateForEquipPos_(nEquipID, pos)
end

--[[
-- 函数类型: public
-- 函数功能: 设置配置当前使用的挂件
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CEquipManager:SetCurrentConfigMountEquip( nMountEquipID, pos )
    self:SetTemplateForEquipPos_(nMountEquipID, pos)
end

--[[
-- 函数类型: public
-- 函数功能: 设置装备位置的道具或者装备信息
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CEquipManager:SetTemplateForEquipPos_( nGoodsTemplateID, pos, number)
    local _tankEquipInfo = self.tTankEquipMap[nGoodsTemplateID]
    if _tankEquipInfo then
        _tankEquipInfo[pos].templateID = nGoodsTemplateID
        _tankEquipInfo[pos].number = number
    else
        log_error(LOG_FILE_NAME, '没找找到该模版id的坦克的装备列表数据templateID:[%d]', nGoodsTemplateID)
    end
end

--[[
-- 函数类型: public
-- 函数功能: 直接装配装备
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CEquipManager:ReqDirectionEquipLoad(pos, templateID)
    self:SendEquipOperator(pos, templateID, EEQUIP_OPERATOR_TYPE.LOAD)
end

--[[
-- 函数类型: public
-- 函数功能: 请求摧毁以前的装备并穿戴当前选择的装备
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CEquipManager:ReqBreakOldAndLoad( pos, templateID )
    --local _pBackpackage = CPlayer:GetInstance():GetBackPackage()
    --local _bHave = _pBackpackage:GetPackage():IsHaveItem(templateID)

    -- 仅摧毁并穿戴
    --if _bHave then
        self:SendEquipOperator(pos, templateID, EEQUIP_OPERATOR_TYPE.DESTORY_LOAD)

    -- -- 购买并摧毁并穿戴
    -- else
    --     self:SendEquipOperator(pos, templateID, EEQUIP_OPERATOR_TYPE.BUY_DESTORYLAST_LOAD)
    -- end
end

--[[
-- 函数类型: public
-- 函数功能: 直接销毁装备
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CEquipManager:ReqDirectionBreak( templateID )
    self:SendDirectionBreakOrUnloadEquip(templateID, EEQUIP_DIRECTION_OPERATOR_TYPE.DESTORY)
end

--[[
-- 函数类型: public
-- 函数功能: 直接卸载装备
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CEquipManager:ReqDirectionUnload( templateID )
    self:SendDirectionBreakOrUnloadEquip(templateID, EEQUIP_DIRECTION_OPERATOR_TYPE.UNLOAD)
end

--[[
-- 函数类型: public
-- 函数功能: 发送对装备的直接操作消息
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CEquipManager:SendDirectionBreakOrUnloadEquip(templaetID, operatorType )
    local _curUseTankTemplateID = CTankPackage:GetInstance():GetCurrentUseTankTemplateID()
    local _curUseTankID = CTankPackage:GetInstance():GetTankIDByTemplateID(_curUseTankTemplateID)
    local sendData = 
    {
        roleID          = CPlayer:GetInstance():GetRoleID(),
        tankId          = _curUseTankID,
        operatorType    = operatorType,
        itemConfingId   = templaetID,
    }
    local buffer = protobuf.encode(MSGTYPE[MSGID.CS_TANK_REQBERAKORUNLOAD], sendData)
    SendMsgToServer(MSGID.CS_TANK_REQBERAKORUNLOAD, buffer, #buffer)
end

--[[
-- 函数类型: public
-- 函数功能: 请求卸载以前的并穿戴当前的装备或者副装甲
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CEquipManager:ReqUnloadOldAndLoad(pos, templateID)
    --local _pBackpackage = CPlayer:GetInstance():GetBackPackage()
    --local _bHave = _pBackpackage:GetPackage():IsHaveItem(templateID)

    ---- 仅卸载并穿戴
    --if _bHave then
        self:SendEquipOperator(pos, templateID, EEQUIP_OPERATOR_TYPE.UNLOAD_LOAD)

    ---- 购买并卸载并穿戴
    --else
    --    self:SendEquipOperator(pos, templateID, EEQUIP_OPERATOR_TYPE.BUY_UNLOADLAST_LOAD)
    --end
end

--[[
-- 函数类型: public
-- 函数功能: 发送装备的操作
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CEquipManager:SendEquipOperator(pos, templateID, operatorType)
    local _curUseTankTemplateID = CTankPackage:GetInstance():GetCurrentUseTankTemplateID()
    local _tankInfo = CTankPackage:GetInstance():GetTankByTemplateID(_curUseTankTemplateID)
    local _tEuqipInfo = _tankInfo:GetEquipList()
    local _oldTemplateID = 0
    if _tEuqipInfo[pos] then
        _oldTemplateID = _tEuqipInfo[pos].configId
    end
     self:ReqOperatorEquipAndItem(pos, operatorType, _oldTemplateID, templateID, 1,  Equip_Struct[pos].type )
end

--[[
-- 函数类型: public
-- 函数功能: 请求携带道具
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注: 如果数量超出库存需要进行购买(proto定义的时候需要注意)
--]]
function CEquipManager:ReqAssembleProp( pos, templateID, number )
    local _curUseTankTemplateID = CTankPackage:GetInstance():GetCurrentUseTankTemplateID()
    local _tankInfo = CTankPackage:GetInstance():GetTankByTemplateID(_curUseTankTemplateID)
    local _tEuqipInfo = _tankInfo:GetEquipList()
    local _oldTemplateID = 0
    if _tEuqipInfo[pos] then
        _oldTemplateID = _tEuqipInfo[pos].configId
    end
    if _tEuqipInfo then
        self:ReqOperatorEquipAndItem(pos,
            EEQUIP_OPERATOR_TYPE.LOAD, 
            _oldTemplateID, 
            templateID, 
            number, 
            Equip_Struct[pos].type )
    else
        log_error(LOG_FILE_NAME, '当前坦克的装备数据错误!')
    end
end

--[[
-- 函数类型: public
-- 函数功能: 请求购买并穿戴此装备
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CEquipManager:ReqBuyEquip(pos, templateID)
    self:SendEquipOperator(pos, templateID, EEQUIP_OPERATOR_TYPE.BUY_LOAD)
end

--[[
-- 函数类型: public
-- 函数功能: 请求处理装备和道具的装配,购买,卸载
-- 参数[IN]: operatorType = 操作类型, curTemplateID = 当前装备的模版ID,
            replaceTemplateID = 即将替换的模版ID, replaceNum = 即将替换的数量, replacePos = 替换的位置, itemType = 物品的类型
-- 返 回 值: 无
-- 备    注:
--]]
function CEquipManager:ReqOperatorEquipAndItem( replacePos, operatorType, curTemplateID, replaceTemplateID, replaceNum, itemType )
    local _curUseTankTemplateID = CTankPackage:GetInstance():GetCurrentUseTankTemplateID()
    local _curUseTankID = CTankPackage:GetInstance():GetTankIDByTemplateID(_curUseTankTemplateID)

    -- 即将替换的物品信息
    local _itemInfo = 
    {
        configId  = replaceTemplateID,
        num       = replaceNum,
        itemType  = itemType,
        index     = replacePos,
    }

    local _tankItemInfo = 
    {
        itemIndex = replacePos,
        itemInfo = _itemInfo
    }

    local sendData = 
    {
        roleId                  = CPlayer:GetInstance():GetRoleID(),
        tankId                  = _curUseTankID,
        changeType              = operatorType,
        currentItemCofigId      = curTemplateID,
        item                    = _tankItemInfo
    }
    dump(sendData, '购买装备或道具的数据', 10)
    local buffer = protobuf.encode(MSGTYPE[MSGID.CS_TANK_REQCHANGEITEM], sendData)
    SendMsgToServer(MSGID.CS_TANK_REQCHANGEITEM, buffer, #buffer)        
end

--[[
-- 函数类型: public
-- 函数功能: 销毁(析构)
-- 参数[IN]: 无
-- 返 回 值: 无
-- 备    注:
--]]
function CEquipManager:Destroy()
    CEquipManager._instance = nil
end