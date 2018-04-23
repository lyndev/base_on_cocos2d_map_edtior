--******************************************************************************
-- Copyright (C), 2016, 
-- 文 件 名: EditorConfig.lua
-- 作    者: lyn
-- 创建日期: 2017-01-13
-- 完成日期: 
-- 功能描述: 
-- 其它相关: 
-- 修改记录: 
--******************************************************************************

-- 日志文件名
local LOG_FILE_NAME = 'EditorConfig.lua.log'

require "res.config.Q_MapElement"


EditorConfig = {}
EditorConfig.ElSubType = 
{	
	-- #########################################################
	-- ############ 这部分需要使用者自行配置元素分类项，格式如下：
	-- ############ 配置元素的分类
	-- ############ [类型编号] = "类型名字"
	-- #########################################################
	[1] = "小镇",
	[2] = "工厂",
	[3] = "沙漠",
	[4] = "城市",
	[5] = "海岛",
	[6] = "其他",
}

-- #########################################################
-- ############ 如果配置表名字变化了需要修改这里的2个值
-- #########################################################
EditorConfig.ConfigData      = Q_MapElement
EditorConfig.ConfigDataIndex = Q_MapElement_index


-- #########################################################
-- ############ 自动保存地图文件的时间 分钟
-- #########################################################
EditorConfig.SaveTimeInterval = 1

ImageType = 
{
	BG = 1, -- 背景
	EL = 2,	-- 元素
}

EditorConfig.MapBG = {}

EditorConfig.MapEL = {}

for k,v in pairs(EditorConfig.ElSubType) do
	EditorConfig.MapEL[k] = {}
end

function ReadConfig()
	local _config = EditorConfig.ConfigData or {}
	for i,v in pairs(_config) do
		if type(v) == "table" then
			local _type = v[EditorConfig.ConfigDataIndex.q_image_type]
			local _image = v[EditorConfig.ConfigDataIndex.q_picture_id]
			if _type == ImageType.BG then
				table.insert(EditorConfig.MapBG, v)
			elseif _type == ImageType.EL then
				local _subImageType = v[EditorConfig.ConfigDataIndex.q_image_sub_type]
				if not EditorConfig.MapEL[_subImageType] then
					EditorConfig.MapEL[_subImageType] = {}
				end
				table.insert(EditorConfig.MapEL[_subImageType], v)
			end
		end
	end
end

ReadConfig()