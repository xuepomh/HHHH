-----------------------------------------------------描述: 玩家登陆成功后逻辑处理--时间: 2012.7.27--作者: cq---------------------------------------------------MsgLoginSuc = {}local p = MsgLoginSuc;p.sTokenDevice = nil;p.sDeviceVersionInfo = nil;function p.setMobileKey(sTokenDevice)    p.sTokenDevice = sTokenDevice;endfunction p.setDeviceVersionInfo(sDeviceInfo)    p.sDeviceVersionInfo = sDeviceInfo;endlocal ACTION_PHONE_KEY     = 0;--苹果系统tokendevice更新local MOBILE_TYPE = 
{
	MOBILE_TYPE_NONE = 0,
	MOBILE_TYPE_IPHONE_APPSTORE_CH = 1,		--IOS简体
	MOBILE_TYPE_IPHONE_APPSTORE_CHS = 2,	--IOS繁体
	MOBILE_TYPE_ANDROID_MOBAGE_CH = 3,		--android简体
	MOBILE_TYPE_ANDROID_MOBAGE_CHS = 4,		--android繁体
	MOBILE_TYPE_IPHONE_91_CH = 5,			--IOS简体91版
};--登陆下发相关数据到服务端function p.ProcessLoginSuc(nData)    local netdata = createNDTransData(NMSG_Type._MSG_LOGIN_SUC);	if nil == netdata then		return false;	end    if p.sTokenDevice == nil then        return    end        LogInfo("tzq %s########################%d", p.sTokenDevice, MOBILE_TYPE.MOBILE_TYPE_ANDROID_MOBAGE_CHS);	netdata:WriteStr(p.sTokenDevice);	netdata:WriteByte(MOBILE_TYPE.MOBILE_TYPE_ANDROID_MOBAGE_CHS);	netdata:WriteStr(p.sDeviceVersionInfo);				SendMsg(netdata);	netdata:Free();end--注册本地通知,暂时屏蔽新功能function p.ProecssLocalNotification()   local nTime = os.time();   local nNotify = os.date("*t");         nNotify['year'] = 2012;         nNotify['month'] = 10;         nNotify['day'] = 31;         nNotify['hour'] = 18;         nNotify['min'] = 35;         nNotify['sec'] = 50;    local nNotifyTime = os.time(nNotify);    local sNotifyContent = "服务器正式开启，一起来吧!GO!GO!GO!";    --LogInfo("########################%d,%d",nNotifyTime,nTime);    if  nTime < nNotifyTime  then        --p.sNotifyDate = "2012-09-14 11:16:30";        --把时间转换成字符串格式        local sNotifyTime = os.date("%Y%m%d%H%M%S", nNotifyTime);        RegisterLocalNotification(sNotifyTime,sNotifyContent);   endend--[[function p.ProecssLocalNotification()  --LogInfo("########################");  p.sNotifyDate = "2012-10-18 13:55:00";  p.sNotifyContent = "最后5分钟！高清Q版RPG穿越三国巨作「91大话龙将」新版新服10月18日14时火爆来袭！一起玩吧！";  RegisterLocalNotification(p.sNotifyDate,p.sNotifyContent);end]]