---------------------------------------------------
--描述: 登陆消息处理
--时间: 2012.3.27
--作者: HJQ
---------------------------------------------------

MsgLogin = {}
local p = MsgLogin;

local ID_ACTION_LOGIN_GAME_SERVER = 60002;
local ID_CHILED_ACTION_LOGIN_GAME_CREATE_ROLE = 9;
local ID_CHILED_ACTION_LOGIN_SUCC = 1;-- 登录<游戏>服务器成功
local    ID_CHILED_ACTION_LOGIN_GAME_FAILED =2;-- 登录<游戏>服务器失败
local   ID_CHILED_ACTION_LOGIN_ACTSRV_FAILED=3;--连接<帐号>服务器失败
local  ID_CHILED_ACTION_CONNECT_SERVER_FAILED=4;-- 连接<游戏>服务器失败
local  ID_CHILED_ACTION_LOGIN_ACTSRV_OVER_TIME=5;--登录<帐号>服务器超时
local ID_CHILED_ACTION_LOGIN_SERVER_OVER_TIME=6;--// 登录<游戏>服务器超时
local ID_CHILED_ACTION_LOGIN_GATE_OVER_TIME=7;--// <代理服务器>繁忙
local  ID_CHILED_ACTION_LOGIN_SERVER_FULL= 8; -- <代理服务器>已达到人数上限

function p.ProcessServerNotify(netdata)
    local action				= netdata:ReadShort();
    local code                  = netdata:ReadShort();
    local count                 = netdata:ReadShort();
LogInfo("Notify[%d][%d][%d]", action, code, count);
    if ID_ACTION_LOGIN_GAME_SERVER ~= action then
        return true;
    end
    
    if ID_CHILED_ACTION_LOGIN_GAME_CREATE_ROLE == code then
        Login_RegRoleUI.LoadUI();
--[[
        g_Create_Role_Reason = 1;
LogInfo("RoleName[%s]",g_Select_Name);
        if g_Select_Name == nil then
            Login_RegRoleUI.LoadUI();
            return true;
        end
        --直接发送消息创建人物
        p.SendCreateRoleReq();
        LoginGame.FreeRoleData();
--]]
LogInfo("未创建角色，需要创建角色!");
        return true;
    elseif ID_CHILED_ACTION_LOGIN_SUCC ==code then-- 登录<游戏>服务器成功
        --LoginGame.FreeLoginData();
        --LoginGame.FreeRoleData();
        --Login_ActAndServerUI.LoadUI();
    LogInfo("登录<游戏>服务器成功!");
    elseif ID_CHILED_ACTION_LOGIN_GAME_FAILED ==code then-- 登录<游戏>服务器失败
        CommonDlgNew.ShowTipDlg(GetTxtPri("ML_T1"));
        --Login_ServerUI.LoadUI();
    elseif ID_CHILED_ACTION_LOGIN_ACTSRV_FAILED==code then--连接<帐号>服务器失败
        CommonDlgNew.ShowTipDlg(GetTxtPri("ML_T2"));
        --Login_ServerUI.LoadUI();
    elseif ID_CHILED_ACTION_CONNECT_SERVER_FAILED==code then-- 连接<游戏>服务器失败
        --Login_ActAndServerUI.LoadUI();
        CommonDlgNew.ShowTipDlg(GetTxtPri("ML_T1"));
        --Login_ServerUI.LoadUI();
    elseif ID_CHILED_ACTION_LOGIN_ACTSRV_OVER_TIME==code then--登录<帐号>服务器超时
        --Login_ActAndServerUI.LoadUI();
        CommonDlgNew.ShowTipDlg(GetTxtPri("ML_T4"));
        --Login_ServerUI.LoadUI();
    elseif ID_CHILED_ACTION_LOGIN_SERVER_OVER_TIME==code then--// 登录<游戏>服务器超时
        --Login_ActAndServerUI.LoadUI();
        CommonDlgNew.ShowTipDlg(GetTxtPri("ML_T3"));
        --Login_ServerUI.LoadUI();
        
    elseif ID_CHILED_ACTION_LOGIN_GATE_OVER_TIME==code then--// <代理服务器>繁忙
        --Login_ActAndServerUI.LoadUI();
        CommonDlgNew.ShowTipDlg(GetTxtPri("ML_T5"));
        --Login_ServerUI.LoadUI();
    elseif ID_CHILED_ACTION_LOGIN_SERVER_FULL==code then-- <代理服务器>已达到人数上限
        --Login_ActAndServerUI.LoadUI();
        CommonDlgNew.ShowTipDlg(GetTxtPri("ML_T6"));
        --Login_ServerUI.LoadUI();
    else
        --系统错误
        --Login_ActAndServerUI.LoadUI();
        CommonDlgNew.ShowTipDlg(GetTxtPri("ML_T7"));
        --Login_ServerUI.LoadUI();
    end
    

end
--缺少提示
p.mTimerTaskTag = nil;

function p.PlayVideoIntro()
	if (p.mTimerTaskTag) then
		UnRegisterTimer(p.mTimerTaskTag);
		p.mTimerTaskTag = nil;
	end	

	PlayVideo("480_0.mp4",false);
end

function p.ProcessNotifyClient(netdata)
	PrintLog("function p.ProcessNotifyClient(netdata)");
    CloseLoadBar();
    local ret = netdata:ReadByte();
    if ret == 0 then
        ---0：创建失败 1：创建成功 2：人物名已存在 3：人物名不合法
        --g_Create_Role_Reason = 1;
        LogInfo(GetTxtPri("ML_T8"));
        --Login_RegRoleUI.LoadUI();
        
        CommonDlgNew.ShowTipDlg(GetTxtPri("ML_T8"),2);
    elseif ret == 1 then
        --NDLog(@"创建成功");
        LogInfo("创建成功!");
        --CommonDlgNew.ShowTipDlg("创建成功!",2);
        
        
        local scene = GetRunningScene();
        local layer = GetUiLayer(scene,NMAINSCENECHILDTAG.Login_RegRoleUI);
        layer:SetVisible(false);
        
        --播放视频
        p.mTimerTaskTag = RegisterTimer(p.PlayVideoIntro, 0.01);
        
    elseif ret == 2 then
        --重名
        --g_Create_Role_Reason = 1;
        --Login_RegRoleUI.LoadUI();
        LogInfo("重名!");
        CommonDlgNew.ShowTipDlg(GetTxtPri("ML_T9"),2);
    elseif ret == 3 then
        --名字非法
        --g_Create_Role_Reason = 1;
        --Login_RegRoleUI.LoadUI();
        LogInfo("名字非法!");
        CommonDlgNew.ShowTipDlg(GetTxtPri("ML_T10"),2);
    end
    return true
end

function p.SendCreateRoleReq(strName,nProfession,nLookFace)
    ShowLoadBar();
    LogInfo("SendCreateRoleReq[%d],strName:[%s],nProfession:[%d],nLookFace:[%d]", NMSG_Type.MB_LOGINSYSTEM_CREATE_NEWBIE,strName,nProfession,nLookFace);
    local netdata = createNDTransData(NMSG_Type.MB_LOGINSYSTEM_CREATE_NEWBIE);
    if nil == netdata then
        return false;
    end
    netdata:WriteInt(nLookFace);--外观
    netdata:WriteByte(nProfession);--职业
    netdata:WriteByte(0);--阵营
    netdata:WriteStr(strName);--名字
    netdata:WriteStr("无");--帐号
    netdata:WriteStr('IPHONE4');--机型
    netdata:WriteStr('BYWX'); --渠道号
    SendMsg(netdata);
    netdata:Free();
    return true;
end

RegisterNetMsgHandler(NMSG_Type._MSG_NOTIFY_CLIENT, "p.ProcessNotifyClient", p.ProcessNotifyClient);
RegisterNetMsgHandler(NMSG_Type.MB_LOGINSYSTEM_MOBILE_SERVER_NOTIFY, "p.ProcessServerNotify", p.ProcessServerNotify);

