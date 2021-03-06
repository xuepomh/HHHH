---------------------------------------------------
--描述: 玩家伙伴网络消息处理及其逻辑
--时间: 2012.3.8
--作者: cl
---------------------------------------------------

MsgRolePet = {}
local p = MsgRolePet;

local MSG_PET_SHOP_ACT_BUY			=1; --初次招募
local MSG_PET_SHOP_ACT_BUY_BACK		=2;	--归队
local MSG_PET_SHOP_ACT_DROP			=3;	--离队

function p.SendPetLeaveAction(nPetId)
	p.SendShopPetAction(nPetId, MSG_PET_SHOP_ACT_DROP);
end

function p.SendShopPetAction(nPetId, nAction)
	if not CheckN(nPetId) or not CheckN(nAction) then
		return false;
	end
	if nPetId <= 0 then
		return false;
	end
	local netdata = createNDTransData(NMSG_Type._MSG_PET_SHOP_ACTION);
	if nil == netdata then
		return false;
	end
	netdata:WriteByte(nAction);
	netdata:WriteInt(nPetId);
	SendMsg(netdata);
	netdata:Free();
	LogInfo("send pet[%d] action[%d]", nPetId, nAction);
	return true;
end


function p.SendBuyPet(nPetId)
	return p.SendShopPetAction(nPetId, MSG_PET_SHOP_ACT_BUY);
end

function p.SendImpartPet(idPet,idTarget,vip)
	if not CheckN(idPet) or not CheckN(idTarget) or not CheckN(vip) then
		return false;
	end
	if idPet <= 0 then
		return false;
	end
	local netdata = createNDTransData(NMSG_Type._MSG_PET_IMPART);
	if nil == netdata then
		return false;
	end
	LogInfo("send pet[%d] target[%d]", idPet, idTarget);
	netdata:WriteByte(vip);
	netdata:WriteInt(idPet);
	netdata:WriteInt(idTarget);
	SendMsg(netdata);
	netdata:Free();
	return true;
end

function p.SendBuyBackPet(nPetId)
	return p.SendShopPetAction(nPetId, MSG_PET_SHOP_ACT_BUY_BACK);
end

function p.SendDropPet(nPetId)
	return p.SendShopPetAction(nPetId, MSG_PET_SHOP_ACT_DROP);
end

function p.ProcessPetInfo(netdata)
	local btNum					= netdata:ReadByte();
	
	LogInfo("p.ProcessPetInfo btNum[%d]", btNum);
	
	if btNum <= 0 then
		return 1;
	end
	
	for	i=1, btNum do
		local idPet					= netdata:ReadInt();					-- ID
		local idType				= netdata:ReadInt();					-- 类型
		
		local btMain				= netdata:ReadByte();					-- 是否主角
		local idOwner				= netdata:ReadInt();				-- 所有者
		local btPosition			= netdata:ReadByte();				-- 位置
		local usLevel				= netdata:ReadShort();				-- 等级
		local btGradenet			= netdata:ReadByte();				-- 境界
		local unExp					= netdata:ReadInt();					-- 经验
		local unLife				= netdata:ReadInt();					-- 生命
		local unLifeLimit			= netdata:ReadInt();			-- 生命上限
		local unMana				= netdata:ReadInt();			-- 气势
		local unManaLimit			= netdata:ReadInt();			-- 气势上限
		local idSkill				= netdata:ReadInt();				-- 技能
		local usForce				= netdata:ReadShort();				-- 武力
		local usSuperSkill			= netdata:ReadShort();			-- 绝技
		local usMagic				= netdata:ReadShort();				-- 法术
		local usForceFoster			= netdata:ReadShort();			-- 武力培养
		local usSuperSkillFoster	= netdata:ReadShort();		-- 绝技培养
		local usMagicFoster			= netdata:ReadShort();			-- 法术培养
		local btForceElixir1		= netdata:ReadByte();			-- 一品武力丹
		local btForceElixir2		= netdata:ReadByte();			-- 二品武力丹
		local btForceElixir3		= netdata:ReadByte();			-- 三品武力丹
		local btForceElixir4		= netdata:ReadByte();		-- 四品武力丹
		local btForceElixir5		= netdata:ReadByte();			-- 五品武力丹
		local btForceElixir6		= netdata:ReadByte();			-- 六品武力丹
		local btSuperSkillElixir1	= netdata:ReadByte();	-- 一品绝技丹
		local btSuperSkillElixir2	= netdata:ReadByte();	-- 二品绝技丹
		local btSuperSkillElixir3	= netdata:ReadByte();	-- 三品绝技丹
		local btSuperSkillElixir4	= netdata:ReadByte();	-- 四品绝技丹
		local btSuperSkillElixir5	= netdata:ReadByte();	-- 五品绝技丹
		local btSuperSkillElixir6	= netdata:ReadByte();	-- 六品绝技丹
		local btMagicElixir1		= netdata:ReadByte();			-- 一品法术丹
		local btMagicElixir2		= netdata:ReadByte();			-- 二品法术丹
		local btMagicElixir3		= netdata:ReadByte();			-- 三品法术丹
		local btMagicElixir4		= netdata:ReadByte();			-- 四品法术丹
		local btMagicElixir5		= netdata:ReadByte();			-- 五品法术丹
		local btMagicElixir6		= netdata:ReadByte();			-- 六品法术丹
		local btImpart				= netdata:ReadByte();			-- 传承
		local btObtain				= netdata:ReadByte();			-- 被传承
		
		local nPhysicalAtk			= netdata:ReadInt();			--武力攻击
		local nSkillAtk				= netdata:ReadInt();			--绝技攻击
		local nMagicAtk				= netdata:ReadInt();			--法术攻击
		local nPhysicalDef			= netdata:ReadInt();			--武力防御
		local nSkillDef				= netdata:ReadInt();			--绝技防御
		local nMagicDef				= netdata:ReadInt();			--法术防御
		
		local btDritical			= netdata:ReadShort();				-- 暴击
		local btHitrate				= netdata:ReadShort();				-- 命中
		local btWreck				= netdata:ReadShort();				-- 破击
		local btHurtAdd				= netdata:ReadShort();				-- 必杀
		local btTenacity			= netdata:ReadShort();				-- 韧性
		local btDodge				= netdata:ReadShort();				-- 闪避
		local btBlock				= netdata:ReadShort();				-- 格挡

		
		local strName				= netdata:ReadUnicodeString();
		
		LogInfo("%d,%d,%d",usForce,usSuperSkill,usMagic);
		
		RolePet.SetPetInfoN(idPet,PET_ATTR.PET_ATTR_ID, idPet);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_TYPE, idType);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_MAIN, btMain);
		RolePet.SetPetInfoN(idPet,PET_ATTR.PET_ATTR_OWNER_ID, idOwner);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_POSITION, btPosition);
		RolePet.SetPetInfoN(idPet,PET_ATTR.PET_ATTR_LEVEL, usLevel);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_GRADE, btGradenet);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_EXP, unExp);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_LIFE, unLife);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_LIFE_LIMIT, unLifeLimit);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_MANA, unMana);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_MANA_LIMIT, unManaLimit);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_SKILL, idSkill);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_PHYSICAL, usForce);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_SUPER_SKILL, usSuperSkill);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_MAGIC, usMagic);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_PHY_FOSTER, usForceFoster);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_SUPER_SKILL_FOSTER, usSuperSkillFoster);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_MAGIC_FOSTER, usMagicFoster);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_PHY_ELIXIR1, btForceElixir1);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_PHY_ELIXIR2, btForceElixir2);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_PHY_ELIXIR3, btForceElixir3);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_PHY_ELIXIR4, btForceElixir4);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_PHY_ELIXIR5, btForceElixir5);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_PHY_ELIXIR6, btForceElixir6);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_SUPER_SKILL_ELIXIR1, btSuperSkillElixir1);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_SUPER_SKILL_ELIXIR2, btSuperSkillElixir2);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_SUPER_SKILL_ELIXIR3, btSuperSkillElixir3);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_SUPER_SKILL_ELIXIR4, btSuperSkillElixir4);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_SUPER_SKILL_ELIXIR5, btSuperSkillElixir5);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_SUPER_SKILL_ELIXIR6, btSuperSkillElixir6);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_MAGIC_ELIXIR1, btMagicElixir1);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_MAGIC_ELIXIR2, btMagicElixir2);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_MAGIC_ELIXIR3, btMagicElixir3);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_MAGIC_ELIXIR4, btMagicElixir4);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_MAGIC_ELIXIR5, btMagicElixir5);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_MAGIC_ELIXIR6, btMagicElixir6);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_IMPART, btImpart);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_OBTAIN, btObtain);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_PHY_ATK, nPhysicalAtk);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_SKILL_ATK, nSkillAtk);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_MAGIC_ATK, nMagicAtk);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_PHY_DEF, nPhysicalDef);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_SKILL_DEF, nSkillDef);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_MAGIC_DEF, nMagicDef);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_DRITICAL, btDritical);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_HITRATE, btHitrate);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_WRECK, btWreck);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_HURT_ADD, btHurtAdd);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_TENACITY, btTenacity);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_DODGE, btDodge);
		RolePet.SetPetInfoN(idPet, PET_ATTR.PET_ATTR_BLOCK, btBlock);
		RolePet.SetPetInfoS(idPet, PET_ATTR.PET_ATTR_NAME, strName);
		
		if not RolePetUser.IsExistPet(idOwner, idPet) then
			RolePetUser.AddPet(idOwner, idPet);
		end
		LogInfo("宠物信息数据");
		RolePet.LogOutPet(idPet);
		
		--todo刷新跟宠物相关的界面
		GameDataEvent.OnEvent(GAMEDATAEVENT.PETINFO, idPet);
	end
	
	if IsUIShow(NMAINSCENECHILDTAG.RoleInvite) then
		RoleInvite.RefreshContainer();
	end
end


function p.ProcessPetInfoUpdate(netdata)
	local petId					= netdata:ReadInt();
	local btNum					= netdata:ReadByte();
	
	LogInfo("p.ProcessPetInfoUpdate btNum[%d]", btNum);
	
	if btNum <= 0 then
		return 1;
	end
	
	local datalist				= {[1] = petId};
	for	i=1, btNum do
		local usType = netdata:ReadShort();
		local unData = netdata:ReadInt();
		RolePet.SetPetInfoN(petId,usType,unData);
		table.insert(datalist, usType);
		table.insert(datalist, unData);
	end
	
	if 1 < #datalist then
		GameDataEvent.OnEvent(GAMEDATAEVENT.PETATTR, datalist);
	end
	
	if IsUIShow(NMAINSCENECHILDTAG.RoleInvite) then
		RoleInvite.RefreshContainer();
	end
end


RegisterNetMsgHandler(NMSG_Type._MSG_PETINFO_UPDATE, "p.ProcessPetInfoUpdate", p.ProcessPetInfoUpdate);
RegisterNetMsgHandler(NMSG_Type._MSG_PETINFO, "p.ProcessPetInfo", p.ProcessPetInfo);