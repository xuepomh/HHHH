/*
 *  ScriptCommon.mm
 *  DragonDrive
 *
 *  Created by jhzheng on 12-1-9.
 *  Copyright 2012 (����)DeNA. All rights reserved.
 *
 */

#include "ScriptCommon.h"
#include "ScriptInc.h"
#include "NDPath.h"
#include "NDUtility.h"
#include <sstream>
#include <map>
#include "NDPicture.h"
#include "CCTextureCacheExt.h"

using namespace LuaPlus;
namespace NDEngine {

int LuaLogInfo(LuaState* state)
{
	LuaStack args(state);
	LuaObject str = args[1];
	
	if (str.IsString())
	{
		ScriptMgrObj.DebugOutPut("%s", str.GetString());
	}
	
	return 0;
}

int LuaLogError(LuaState* state)
{
	LuaStack args(state);
	LuaObject str = args[1];
	
	if (str.IsString())
	{
		ScriptMgrObj.DebugOutPut("Error:%s", str.GetString());
	}
	
	return 0;
}

int DoFile(LuaState* state)
{
	int nRet = -1;
	LuaStack args(state);
	LuaObject str = args[1];
	
	if (str.IsString())
	{
#ifndef UPDATE_RES
		nRet = state->DoFile(NDPath::GetScriptPath(str.GetString()).c_str());
#else
        nRet = ScriptMgrObj.LoadLuaFile(NDPath::GetScriptPath(str.GetString()));
#endif
	}
	
	return nRet;
}

int LeftShift(int x, int y)
{
	return x << y;
}	

int RightShift(int x, int y)
{
	return x >> y;
}

int BitwiseAnd(int x, int y)
{
	int nRes = x&y;
	return nRes;
}

int PicMemoryUsingLogOut(bool bNotPrintLog)
{
	int nSize = 0;
	if (!bNotPrintLog)
	{
		NDLog("\n============NDPicturePool Memory Report==============\n");
	}
	//nSize += NDPicturePool::DefaultPool()->Statistics(bNotPrintLog);
	if (!bNotPrintLog)
	{
		NDLog("\n============CCTextureCache Memory Report==============\n");
	}
	//nSize += [[CCTextureCache sharedTextureCache] Statistics:bNotPrintLog];
	return nSize;
}

////////////////////////////////////////////////////////////
//std::string g_strTmpWords;
////////////////////////////////////////////////////////////

void ScriptCommonLoad()
{
	ETLUAFUNC("LuaLogInfo", LuaLogInfo);
	ETLUAFUNC("LuaLogError", LuaLogError);
	ETLUAFUNC("DoFile", DoFile);
	ETCFUNC("LeftShift", LeftShift);
	ETCFUNC("RightShift", RightShift);
	ETCFUNC("BitwiseAnd", BitwiseAnd);
	ETCFUNC("PicMemoryUsingLogOut", PicMemoryUsingLogOut);
}

}
