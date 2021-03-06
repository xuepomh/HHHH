//
//  ObjectTracker.h
//
//  Created by zhangwq on 2012-12-19.
//  Copyright 2010 (����)DeNA. All rights reserved.
//
//	���ٶ���
//

#pragma once

#include <map>
#include <string>
using namespace std;
#include "platform/CCPlatformMacros.h"



///////////////////////////////////////////////////////////
struct TrackerData
{
	TrackerData() { num[0] = num[1] = 0; }
	int num[2];

	int& getPrev() {
		return num[0];
	}

	int& getCur() {
		return num[1];
	}

	void cur2prev() {
		num[0] = num[1];
	}
};

///////////////////////////////////////////////////////////
class CC_DLL ObjectTracker
{
private:
	ObjectTracker() {}

public:
	static ObjectTracker& instance() {
		static ObjectTracker s_obj;
		return s_obj;
	}

	void inc_cc( const char* clsName ) { inc_imp( clsName, mapStatCC ); }
	void dec_cc( const char* clsName ) { dec_imp( clsName, mapStatCC ); }

	void inc_nd( const char* clsName ) { inc_imp( clsName, mapStatND ); }
	void dec_nd( const char* clsName ) { dec_imp( clsName, mapStatND ); }

	void dump( string& info, int param = 0 );
	void reset() { mapStatCC.clear(); mapStatND.clear(); }

private:
	void inc_imp( const char* clsName, map<string,TrackerData>& curMap );
	void dec_imp( const char* clsName, map<string,TrackerData>& curMap );

private:
	void flush();
	void flush_imp( map<string,TrackerData>& curMap );

	void report( string& info, int param = 0 );
	void report_imp( map<string,TrackerData>& data, int param, int& total, string& info );

private:
	map<string,TrackerData>		mapStatCC;
	map<string,TrackerData>		mapStatND;
	typedef map<string,TrackerData>::iterator ITER_MAP_STAT;
};


///////////////////////////////////////////////////////////////////////////////////
#if (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32) //for debug
#define INC_CCOBJ(CLSNAME)		ObjectTracker::instance().inc_cc(CLSNAME);
#define DEC_CCOBJ(CLSNAME)		ObjectTracker::instance().dec_cc(CLSNAME);

#define INC_NDOBJ(CLSNAME)		ObjectTracker::instance().inc_nd(CLSNAME);
#define DEC_NDOBJ(CLSNAME)		ObjectTracker::instance().dec_nd(CLSNAME);

#define INC_NDOBJ_RTCLS			INC_NDOBJ(GetRuntimeClass()->className);
#define DEC_NDOBJ_RTCLS			DEC_NDOBJ(GetRuntimeClass()->className);

#define DUMP_OBJ(info,param)	ObjectTracker::instance().dump(info,param);

#else
#define INC_CCOBJ(CLSNAME)	
#define DEC_CCOBJ(CLSNAME)	
#define INC_NDOBJ(CLSNAME)	
#define DEC_NDOBJ(CLSNAME)	

#define INC_NDOBJ_RTCLS
#define DEC_NDOBJ_RTCLS

#define DUMP_OBJ(info,param)		

#endif