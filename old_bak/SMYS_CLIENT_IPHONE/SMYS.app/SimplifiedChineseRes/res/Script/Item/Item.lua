---------------------------------------------------
--描述: 统一物品信息保存与获取
--时间: 2012.3.1
--作者: jhzheng
---------------------------------------------------
local p = Item;

-- 物品信息数据
p.ITEM_BEGIN						= 0;
p.ITEM_ID							= 0;	-- Id
p.ITEM_TYPE							= 1;	-- 类型
p.ITEM_OWNERTYPE					= 2;	-- 所有者类型
p.ITEM_OWNER_ID						= 3;	-- 所有者id	
p.ITEM_USER_ID						= 4;	-- 玩家id
p.ITEM_AMOUNT						= 5;	-- 数量
p.ITEM_POSITION						= 6;	-- 位置
p.ITEM_ADDITION						= 7;	-- 强化等级
p.ITEM_EXP							= 8;	-- 道法经验
p.ITEM_ATTR_NUM						= 9;	-- 属性数量
p.ITEM_ATTR_BEGIN					= 10;	-- 属性定义开始()
-- type
-- val
-- ...
p.ITEM_END							= 16;	-- 物品数据结束

function p.IsExistItem(nItemId)
	local nItemId = Item.GetItemInfoN(nItemId, p.ITEM_ID);
	if nItemId <= 0 then
		return false;
	end
	return true;
end

function p.SetItemInfoN(nItemId, nIndex, val)
	if	not CheckN(nItemId) or
		not CheckN(nIndex) or 
		not CheckN(val) then
		return;
	end
	_G.SetGameDataN(NScriptData.eItemInfo, nItemId, NRoleData.eBasic, 0, nIndex, val);
end

function p.SetItemInfoS(nItemId, nIndex, val)
	if	not CheckN(nItemId) or
		not CheckN(nIndex) or 
		not CheckS(val) then
		return;
	end
	_G.SetGameDataS(NScriptData.eItemInfo, nItemId, NRoleData.eBasic, 0, nIndex, val);
end

function p.GetItemInfoN(nItemId, nIndex)
	if	not CheckN(nItemId) or
		not CheckN(nIndex) then
		return 0;
	end
	return _G.GetGameDataN(NScriptData.eItemInfo, nItemId, NRoleData.eBasic, 0, nIndex);
end

function p.GetItemInfoS(nItemId, nIndex)
	if	not CheckN(nItemId) or
		not CheckN(nIndex) then
		return "";
	end
	return _G.GetGameDataS(NScriptData.eItemInfo, nItemId, NRoleData.eBasic, 0, nIndex);
end

function p.DelItemInfo(nItemId)
	if	not CheckN(nItemId) then
		return;
	end
	
	_G.DelRoleGameDataById(NScriptData.eItemInfo, nItemId);
end

function p.LogOutItem(nItemId)
	if not CheckN(nItemId) then
		return;
	end
	_G.DumpGameData(NScriptData.eItemInfo, nItemId, NRoleData.eBasic, 0);
end