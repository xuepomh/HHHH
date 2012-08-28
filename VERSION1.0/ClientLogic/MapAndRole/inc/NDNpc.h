//
//  NDNpc.h
//  DragonDrive
//
//  Created by xiezhenghai on 10-12-15.
//  Copyright 2010 (网龙)DeNA. All rights reserved.
//

#ifndef __NDNpc_H
#define __NDNpc_H

#include "NDBaseRole.h"
#include <string>
#include "EnumDef.h"
#include "NDUILabel.h"
#include "NDPicture.h"
#include "globaldef.h"

namespace NDEngine 
{
	/** btState为1时灰色叹号,2彩色叹号,3灰色问号,4彩色问号 */
	enum 
	{
		QUEST_NONE = 0x01,// 没有任务
		QUEST_CANNOT_ACCEPT = 0x02,// 有任务但是级别不对
		QUEST_CAN_ACCEPT = 0x04, // 有任务可接
		QUEST_NOT_FINISH = 0x08, // 有任务未完成
		QUEST_FINISH = 0x10, // 有任务已完成(优先级最高)
	};
	
	class NDNpc : public NDBaseRole 
	{
		DECLARE_CLASS(NDNpc)
	public:
		NDNpc();
		~NDNpc();
		void Init();				
		bool OnDrawBegin(bool bDraw);
		void OnDrawEnd(bool bDraw);
		bool IsActionOnRing();
		
	public:
		//以下方法供逻辑层使用－－－begin
		//......	
		void Initialization(int nLookface);
		
		void WalkToPosition(CGPoint toPos);
		//－－－end
		//void SetHairImage(int hair, int hairColor);
		void SetExpresstionImage(int nExpresstion);
		
		// 设置npc任务提示
		void SetNpcState(NPC_STATE state);
		
		NPC_STATE GetNpcState() const
		{
			return this->m_eNPCState;
		}
		
		void SetStatus(int status);
		
		// 勿用,如需获取请直接访问ridePet
		//NDRidePet* GetRidePet();
		
		void SetType(int iType);
		int GetType();
		
		enum  LableType{ eLableName, eLabelDataStr, };
		void SetLable(LableType eLableType, int x, int y, std::string text,
			cocos2d::ccColor4B color1, cocos2d::ccColor4B color2);
		
		bool IsRoleNpc()
		{
			return this->m_bRoleNpc;
		}
		
		bool IsPointInside(CGPoint point);
		
		bool getNearestPoint(CGPoint srcPoint, CGPoint& dstPoint);
		
		void ShowHightLight(bool bShow);
	public:

		bool m_bActionOnRing;
		bool m_bDirectOnTalk;
		bool m_bFarmNpc;
		bool m_bUnpassTurn;

		NDSprite* m_pkUpdate;
		
	private:
		 NPC_STATE m_eNPCState;
	public:
		// 骑宠相关
		//NDRidePet	*ridepet;
		std::string m_strData;
		std::string m_strTalk;

	private:

		NDUILabel *m_pkNameLabel[2];
		NDUILabel *m_pkDataStrLebel[2];
		NDPicture *m_pkPicBattle;
		NDPicture *m_pkPicState;
		int m_iStatus;
		// role型 npc
		bool m_bRoleNpc;
		int m_iType;
		CGRect m_rectState;

	private:
		
		void RefreshTaskState();
		bool GetTaskList(ID_VEC& idVec);
		int GetDataBaseData(int nIndex);
		bool GetPlayerCanAcceptList(ID_VEC& idVec);
	};
}

#endif