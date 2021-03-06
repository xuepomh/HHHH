---------------------------------------------------
--描述: 网络消息处理()消息处理及其逻辑
--时间: 2012.5.16
--作者: chh
---------------------------------------------------

MsgShop = {};
local p = MsgShop;
local _G = _G;

p.GroupType = {
    MYSTERIOUS      = 1,        --商人
    SMITH           = 2,        --铁匠
}


p.mUIListener = nil;

p.mGoodsList = {};

function p.getGoodsList()
    return p.mGoodsList;
end

function p.GetMySteriousGoodsList()
    local m = {};
    for i,v in ipairs(p.mGoodsList) do
        if(v.GROUP == p.GroupType.MYSTERIOUS) then
            table.insert(m,v);
        end
    end
    return m;
end

function p.GetSmithGoodsList()
    local m = {};
    for i,v in ipairs(p.mGoodsList) do
        if(v.GROUP == p.GroupType.SMITH) then
            table.insert(m,v);
        end
    end
    return m;
end

function p.processRefreshShop(netdata)
    LogInfo("process7001");
	LogInfo("process %d" , NMSG_Type._MSG_CONFIG_MYSTERIOUS_GOODS);
	
	local count		= netdata:ReadByte();
	LogInfo(" count:" .. count);
	
	local lst = {};
	for i = 1, count do
		local item = {};
		item.TYPE = netdata:ReadInt();
		item.ID = netdata:ReadInt();
        item.BUY_TYPE = netdata:ReadByte();  --够买类型（0.银币 1.金币）
        item.GROUP = netdata:ReadByte();    --购买类型
        table.insert(lst,item);
	end
	
	p.mGoodsList = lst;
	if(p.mUIListener) then
		p.mUIListener(NMSG_Type._MSG_CONFIG_MYSTERIOUS_GOODS,p.mGoodsList);
	end
	return 1;
end

function p.sendBuy(nItemType, nNum)
	
	local netdata = createNDTransData(NMSG_Type._MSG_SHOP);
	if not CheckP(netdata) then
		return false;
	end
	
	netdata:WriteInt(nItemType);
	netdata:WriteInt(-2);       --购买地方 -1铁匠 -2神秘商人
	netdata:WriteInt(1);
	nNum = nNum or 1;
	netdata:WriteInt(nNum);
	SendMsg(netdata);
	netdata:Free();
	
	return true;
end


function p.sendBuyResult(netdata)
    LogInfo("p.sendBuyResult");
    local nItemType = netdata:ReadInt();
    local nIdGood = netdata:ReadInt();
    local nNpc = netdata:ReadInt();
    local nBuy = netdata:ReadInt();
    local nCount = netdata:ReadInt();
    LogInfo("nItemType:[%d],nIdGood:[%d],nNpc:[%d],nBuy:[%d],nCount:[%d]",nItemType,nIdGood,nNpc,nBuy,nCount);
    
    nCount = nBuy;
    
    local m = {};
    m.nItemType = nItemType;
    m.nBuy = nBuy;
    m.nCount = nCount;
    
    
    
    if(p.mUIListener) then
		p.mUIListener(NMSG_Type._MSG_SHOP,m);
	end
	
    
	--引导任务事件触发
	GlobalEvent.OnEvent(GLOBALEVENT.GE_GUIDETASK_ACTION,TASK_GUIDE_PARAM.BUY_ITEM,nItemType);

end

RegisterNetMsgHandler(NMSG_Type._MSG_CONFIG_MYSTERIOUS_GOODS, "p.processRefreshShop", p.processRefreshShop);	
RegisterNetMsgHandler(NMSG_Type._MSG_SHOP, "p.sendBuyResult", p.sendBuyResult);