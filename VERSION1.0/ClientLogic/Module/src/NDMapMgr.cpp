#include "NDMapMgr.h"
#include "NDPlayer.h"
#include "NDConstant.h"
#include "NDDirector.h"
#include "NDMapLayer.h"
#include "GameScene.h"
#include "NDItemType.h"
#include "Battle.h"
#include "define.h"
#include "NDUISynLayer.h"
#include "SMGameScene.h"
#include "GameDataBase.h"
#include "ItemMgr.h"
#include "ScriptGlobalEvent.h"
#include "NDNetMsg.h"
#include "TutorUILayer.h"
#include "ScriptMgr.h"
#include "TaskListener.h"
#include "BattleMgr.h"

namespace NDEngine
{

IMPLEMENT_CLASS(NDMapMgr,NDObject);

bool NDMapMgr::m_bVerifyVersion = true;
bool NDMapMgr::m_bFirstCreate = false;

bool GetIntData(int& t,string strValue,string strType)
{
	int nPos = strValue.find(strType);

	if (-1 == nPos || strValue.length() < strType.length())
	{
		return false;
	}

	string strNumber = strValue.substr(strType.length() + 1,strValue.length());

	t = (int)atoi(strNumber.c_str());

	return true;
}

bool GetShortData(short& t,string strValue,string strType)
{
	int nPos = strValue.find(strType);

	if (-1 == nPos || strValue.length() < strType.length())
	{
		return false;
	}

	string strNumber = strValue.substr(strType.length() + 1,strValue.length());

	t = (short)atoi(strNumber.c_str());

	return true;
}

bool GetCharData(char& t,string strValue,string strType)
{
	int nPos = strValue.find(strType);

	if (-1 == nPos || strValue.length() < strType.length())
	{
		return false;
	}

	string strNumber = strValue.substr(strType.length() + 1,strValue.length());

	t = (char)atoi(strNumber.c_str());

	return true;
}

NDMapMgr::NDMapMgr():
m_nCurrentMonsterBound(0),
m_nRoadBlockX(0),
m_nRoadBlockY(0),
m_nSaveMapID(0),
m_nMapID(0),
m_nMapDocID(0),
m_nCurrentMonsterRound(0)
{
	NDNetMsgPool& kNetPool = NDNetMsgPoolObj;
	kNetPool.RegMsg(_MSG_NPCINFO_LIST,this);
	kNetPool.RegMsg(_MSG_ROOM,this);

	NDConsole::GetSingletonPtr()->RegisterConsoleHandler(this,"sim ");

	m_kTimer.SetTimer(this,1,0.1);
}

NDMapMgr::~NDMapMgr()
{
	m_vNPC.clear();
	m_mapManualRole.clear();
}

bool NDMapMgr::process(MSGID usMsgID, NDEngine::NDTransData* pkData,
		int nLength)
{
	switch (usMsgID)
	{
	case MB_MSG_DISAPPEAR:
	{
		processDisappear(pkData, nLength);
	}
		break;
	case _MSG_REPUTE:
	{
		NDPlayer& kRole = NDPlayer::defaultHero();
		kRole.m_nSWCountry = pkData->ReadInt();
		kRole.m_nSWCamp = pkData->ReadInt();
		kRole.m_nHonour = pkData->ReadInt();
		kRole.m_nExpendHonour = pkData->ReadInt();
		kRole.m_strRank = pkData->ReadUnicodeString();

		updateTaskRepData(kRole.m_nSWCamp, false);
		updateTaskHrData(kRole.m_nHonour, false);
	}
		break;
	case _MSG_NPC_STATUS:
	{
		processNpcStatus(pkData, nLength);
	}
		break;
	case _MSG_MONSTER_INFO_LIST:
	{
		processMonsterInfo(pkData,nLength);
	}
		break;
	case _MSG_COMMON_LIST:
	{
		processMsgCommonList(*pkData);
	}
		break;
	case _MSG_COMMON_LIST_RECORD:
	{
		processMsgCommonListRecord(*pkData);
	}
		break;
	case _MSG_CHG_PET_POINT:
	{
		int nBtAnswer = pkData->ReadByte();
	}
		break;
	case _MSG_PLAYER:
	{
		processPlayer(pkData, nLength);
	}
		break;
	case _MSG_USER_POS:
	{
		///< 依赖张迪的TutorUILayer 郭浩
		//TutorUILayer::processTutorList(*pkData);
	}
		break;
	case _MSG_TIP:
	{
		///< 依赖汤自勤哥的GameSceneLoading 郭浩
// 		GameSceneLoading* gsl = (GameSceneLoading*)scene;
// 		gsl->UpdateTitle(kData->ReadUnicodeString());
	}
	case _MSG_LOGIN_SUC:
	{
		ProcessLoginSuc(*pkData);
	}
		break;
	case _MSG_PLAYER_EXT:
	{
		processPlayerExt(pkData, nLength);
	}
		break;
	case _MSG_NPC_TALK:
	{
		processNpcTalk(*pkData);
	}
		break;
	case _MSG_WALK_TO:
	{
		processWalkTo(*pkData);
	}
		break;
	case _MSG_NPCINFO_LIST:
	{
		processNPCInfoList(pkData, nLength);
	}
		break;
	case _MSG_ROOM:
	{
		processChangeRoom(pkData, nLength);
	}
		break;
	case _MSG_WALK:
	{
		processWalk(pkData, nLength);
	}
		break;
	default:
		break;
	}

	return true;
}

void NDMapMgr::processPlayer(NDTransData* pkData, int nLength)
{
	if (!pkData || nLength == 0)
		return;

	int nUserID = 0;
	(*pkData) >> nUserID; // 用户id 4个字节
	int nLife = 0;
	(*pkData) >> nLife; // 生命值4个字节
	int nMaxLife = 0;
	(*pkData) >> nMaxLife; // 生命值4个字节
	int nMana = 0;
	(*pkData) >> nMana; // 魔法值
	int nMoney = 0;
	(*pkData) >> nMoney; // 银币 4个字节
	int dwLookFace = 0;
	(*pkData) >> dwLookFace; // 创建人物的时候有6种外观可供选择外观 脸型 4个字节
	unsigned short usRecordX = 0;
	(*pkData) >> usRecordX; // 记录点信息X
	unsigned short usRecordY = 0;
	(*pkData) >> usRecordY; // 记录点信息Y
	unsigned char btDir = 0;
	(*pkData) >> btDir; // 玩家面部朝向，左右两个方向 1个字节
	unsigned char btProfession = 0;
	(*pkData) >> btProfession; // 玩家的职业 1个字节
	unsigned char btLevel = 0;
	(*pkData) >> btLevel; // 用户等级
	int dwState = 0;
	(*pkData) >> dwState; // 状态位
	// System.out.println(" 状态 " + dwState);
	int synRank = 0;
	(*pkData) >> synRank; // 帮派等级
	int dwArmorType = 0;
	(*pkData) >> dwArmorType; // 盔甲id 4个字节
	int dwPkPoint = 0;
	(*pkData) >> dwPkPoint; // pk值
	//int weaponTypeID=0; (*pkData) >> weaponTypeID;
	//int armorTypeID=0; (*pkData) >> armorTypeID;
	unsigned char btCamp = 0;
	(*pkData) >> btCamp; // 阵营
	std::string name = "";
	std::string strRank = "";
	std::string synName = ""; // 帮派名字

	unsigned char uiNum = 0;
	(*pkData) >> uiNum; // TQMB 个数 1字节
	for (int i = 0; i < uiNum; i++)
	{
		std::string strString = pkData->ReadUnicodeString();
		if (i == 0)
		{
			name = strString;
		}
		else if (i == 1 && strString.length() > 2)
		{
			strRank = strString;
		}
		else if (i == 2)
		{
			synName = strString;
		}
	}

	if (synName.empty())
	{
		synRank = SYNRANK_NONE;
	}

	NDPlayer& kPlayer = NDPlayer::defaultHero();
	if (nUserID == kPlayer.m_nID)
	{
		if (dwState & USERSTATE_SHAPESHIFT)
		{
			kPlayer.updateTransform(pkData->ReadInt());
		}
		else
		{
			kPlayer.updateTransform(0);
		}

		// 光效
		int effectAmount = pkData->ReadByte();
		std::vector<int> vEffect;
		for (int i = 0; i < effectAmount; i++)
		{
			vEffect.push_back(pkData->ReadInt());
		}

		kPlayer.SetPosition(
				ccp(usRecordX * MAP_UNITSIZE + DISPLAY_POS_X_OFFSET,
						usRecordY * MAP_UNITSIZE + DISPLAY_POS_Y_OFFSET));
		kPlayer.SetState(dwState);
		kPlayer.SetServerPositon(usRecordX, usRecordY);
		kPlayer.SetAction(false);
		return;
	}

	NDManualRole *pkRole = NULL;
	bool bAdd = true;
	pkRole = NDMapMgrObj.GetManualRole(nUserID);
	if (!pkRole)
	{
		pkRole = new NDManualRole;
		pkRole->m_nID = nUserID;
		pkRole->Initialization(dwLookFace, true);
		bAdd = false;
	}

	if (dwState & USERSTATE_SHAPESHIFT)
	{
		pkRole->updateTransform(pkData->ReadInt());
	}
	else
	{
		pkRole->updateTransform(0);
	}

	// 光效
	int nEffectAmount = pkData->ReadByte();
	std::vector<int> vEffect;
	for (int i = 0; i < nEffectAmount; i++)
	{
		vEffect.push_back(pkData->ReadInt());
	}
	//++Guosen 2012.7.15
	int tRank = pkData->ReadByte();
	int nRideStatus = pkData->ReadInt();
	int nMountType = pkData->ReadInt();
	int nQuality = pkData->ReadByte();
	//unsigned int nMountlookface = ScriptDBObj.GetN( "mount_model_config", nMountType, DB_MOUNT_MODEL_LOOKFACE );
	pkRole->ChangeModelWithMount(nRideStatus, nMountType);
	//++

	pkRole->m_nQuality = nQuality;

	pkRole->m_nLife = nLife;
	pkRole->m_nMaxLife = nMaxLife;
	pkRole->m_nMana = nMana;
	pkRole->m_nMoney = nMoney;
	pkRole->m_dwLookFace = dwLookFace;
	pkRole->m_nProfesstion = btProfession;
	pkRole->m_nLevel = btLevel;
	pkRole->SetState(dwState);
	pkRole->setSynRank(synRank);
	pkRole->m_nPKPoint = dwPkPoint;
	pkRole->SetCamp((CAMP_TYPE) btCamp);
	pkRole->m_strName = name;
	pkRole->m_strRank = strRank;
	pkRole->m_strSynName = synName;
	pkRole->m_nTeamID = dwArmorType;
	pkRole->SetPosition(
			ccp(usRecordX * MAP_UNITSIZE + DISPLAY_POS_X_OFFSET,
					usRecordY * MAP_UNITSIZE + DISPLAY_POS_Y_OFFSET));
	pkRole->SetSpriteDir(btDir);
	pkRole->SetServerPositon(usRecordX, usRecordY);

	if (!bAdd)
	{
		NDMapMgrObj.AddManualRole(nUserID, pkRole);
	}

	pkRole->SetAction(false);
	pkRole->SetServerEffect(vEffect);

	if (dwState & USERSTATE_PRACTISE)
	{
		// todo设置玩家打坐状态
		pkRole->SetCurrentAnimation(7, pkRole->IsReverse());
	}
	else
	{
		// todo取消打坐状态
		if (pkRole->AssuredRidePet())
		{
// 			pkRole->SetCurrentAnimation(pkRole->GetPetStandAction(),
// 					pkRole->IsReverse());
		}
		else
		{
			pkRole->SetCurrentAnimation(0, pkRole->IsReverse());
		}
	}
}

void NDMapMgr::AddManualRole(int nID, NDManualRole* pkRole)
{
	if (0 == pkRole || -1 == nID)
	{
		return;
	}

	m_mapManualRole.insert(make_pair(nID, pkRole));

	NDLayer* pkLayer = (NDLayer*) getMapLayerOfScene(
			NDDirector::DefaultDirector()->GetSceneByTag(SMGAMESCENE_TAG));

	if (0 == pkLayer)
	{
		return;
	}

	pkLayer->AddChild((NDNode*) pkRole);

	if (pkRole->m_nID == NDPlayer::defaultHero().m_iFocusManuRoleID)
	{
		GameScene* pkGameScene = GameScene::GetCurGameScene();

		if (0 != pkGameScene)
		{
			pkGameScene->SetTargetHead(pkRole);
		}

		pkRole->SetFocus(true);
	}
}

NDManualRole* NDMapMgr::GetManualRole(int nID)
{
	NDPlayer& kRole = NDPlayer::defaultHero();

	if (nID == kRole.m_nID)
	{
		return &kRole;
	}

	if (m_mapManualRole.empty())
	{
		return 0;
	}

	map_manualrole::iterator it = m_mapManualRole.find(nID);

	if (m_mapManualRole.end() != it)
	{
		return it->second;
	}

	return 0;
}

NDManualRole* NDMapMgr::GetManualRole(const char* pszName)
{
	NDManualRole* pkResult = 0;

	for (map_manualrole::iterator it = m_mapManualRole.begin();
			m_mapManualRole.end() != it; it++)
	{
		NDManualRole* pkRole = it->second;

		if (0 == strcmp(pkRole->m_strName.c_str(), pszName))
		{
			pkResult = it->second;
			break;
		}
	}

	return pkResult;
}

void NDMapMgr::Update(unsigned long ulDiff)
{
	NDPlayer& player = NDPlayer::defaultHero();
	player.Update(ulDiff);

	// 所有其它玩家
	do 
	{
		map_manualrole::iterator it = m_mapManualRole.begin();
		while (it != m_mapManualRole.end()) 
		{
			NDManualRole *role = it->second;
			if (role->m_bClear) 
			{
			//	updateTeamListDelPlayer(*role);			///< No team 郭浩
				SAFE_DELETE_NODE(role->GetRidePet());
				SAFE_DELETE_NODE(role);
				m_mapManualRole.erase(it++);
			}
			else
			{
				it++;
			}
		};

		it = m_mapManualRole.begin();
		for(;it != m_mapManualRole.end();it++)
		{
			NDManualRole* role = it->second;

			if (role == &player) continue;

			if (role) 
			{
				NDNode* parent = role->GetParent();
				if (parent && !parent->IsKindOfClass(RUNTIME_CLASS(Battle))) {
					role->Update(ulDiff);
				}
			}
		}
	} while (0);	


	// 所有地图上的怪
	do 
	{
		if (NDPlayer::defaultHero().IsInState(USERSTATE_FIGHTING)
			|| NDPlayer::defaultHero().IsGathering() 
			|| NDUISynLayer::IsShown())
		{
			break;
		}

		NDScene *scene = NDDirector::DefaultDirector()->GetRunningScene();
		if (scene && scene->IsKindOfClass(RUNTIME_CLASS(GameScene)))
		{
			GameScene *gamescene = (GameScene*)scene;
			if (gamescene->IsUIShow())
			{
				break;
			}
		}

		VEC_MONSTER::iterator it = m_vMonster.begin();
		while (it != m_vMonster.end()) 
		{
			NDMonster* tmp = *it;
			if (!tmp->m_bClear) 
			{
				it++;
				continue;
			}

			if (GetBattleMonster() == tmp) 
			{
				tmp = NULL;
			}

			SAFE_DELETE_NODE(tmp);
			it = m_vMonster.erase(it);
		}


		it = m_vMonster.begin();
		for (; it != m_vMonster.end(); it++) 
		{
			NDMonster* monster = *it;
			if (monster && it == m_vMonster.begin()) 
			{
				monster->Update(ulDiff);
			}
		}	
	} while (0);
}

NDMapLayer* NDMapMgr::getMapLayerOfScene(NDScene* pkScene)
{
	if (0 == pkScene)
	{
		return 0;
	}

	NDNode* pkNode = pkScene->GetChild(MAPLAYER_TAG);

	if (0 == pkNode || 0 == pkNode->IsKindOfClass(RUNTIME_CLASS(NDMapLayer)))
	{
		return 0;
	}

	return (NDMapLayer*) pkNode;
}

void NDMapMgr::DelManualRole(int nID)
{
	if (-1 == nID)
	{
		return;
	}

	map_manualrole::iterator it = m_mapManualRole.find(nID);

	if (m_mapManualRole.end() != it)
	{
		NDManualRole* pkRole = it->second;

		if (pkRole)
		{
			SAFE_DELETE_NODE(pkRole);
		}

		m_mapManualRole.erase(it);
	}
}

void NDMapMgr::processPlayerExt(NDTransData* pkData, int nLength)
{
	if (0 == pkData || 0 == nLength)
	{
		return;
	}

	int nUserID = 0;
	(*pkData) >> nUserID;
	int dwStatus = 0;
	(*pkData) >> dwStatus;

	NDManualRole* pkRole = 0;
	pkRole = NDMapMgrObj.GetManualRole(nUserID);

	if (0 == pkRole)
	{
		return;
	}

	pkRole->SetState(dwStatus);
	pkRole->unpakcAllEquip();

	unsigned char btAmount = 0;
	(*pkData) >> btAmount;

	for (int i = 0; i < btAmount; i++)
	{
		int nEquipTypeID = 0;
		(*pkData) >> nEquipTypeID;
		NDItemType* pkItem = ItemMgrObj.QueryItemType(nEquipTypeID);

		if (0 == pkItem)
		{
			continue;
		}

		pkRole->m_vEquipsID.push_back(nEquipTypeID);
		int nID = pkItem->m_data.m_lookface;
		int nQuality = nEquipTypeID % 10;

		if (0 == nID)
		{
			continue;
		}

		int nAnimationID = 0;

		if (10000 < nID)
		{
			nAnimationID = (nID % 100000) / 10;
		}

		if (nAnimationID >= 1900 && nAnimationID < 2000
				|| nID >= 19000 && nID < 20000)
		{
			ShowPetInfo kShowPetInfo(nEquipTypeID, nID, nQuality);
			pkRole->SetShowPet(kShowPetInfo);
		}
		else
		{
			pkRole->SetEquipment(nID, nQuality);
		}
	}

	if (pkRole->IsInState(USERSTATE_SHAPESHIFT))
	{
		pkRole->updateTransform(pkData->ReadInt());
	}
	else
	{
		pkRole->updateTransform(0);
	}

	if (pkRole->GetParent() != 0
			&& !pkRole->GetParent()->IsKindOfClass(RUNTIME_CLASS(Battle)))
	{
		pkRole->SetAction(pkRole->isMoving(), true);
	}
}

void NDMapMgr::processWalk(NDTransData* pkData, int nLength)
{
	if (0 == pkData || 0 == nLength)
	{
		return;
	}

	int nID = 0;
	(*pkData) >> nID;
	unsigned char ucDir = 0;
	(*pkData) >> ucDir;

	if (NDPlayer::defaultHero().m_nID != nID)
	{
		NDManualRole* pkRole = 0;
		pkRole = NDMapMgrObj.GetManualRole(nID);

		if (pkRole->isTeamLeader())
		{
			pkRole->teamSetServerDir(ucDir);
		}
	}
}

void NDMapMgr::processWalkTo(NDTransData& kData)
{
	int nPlayerID = kData.ReadInt();
	int nAmount = kData.ReadByte();
	NDPlayer& kPlayer = NDPlayer::defaultHero();

	for (int i = 0; i < nAmount; i++)
	{
		int nPosX = kData.ReadShort();
		int nPosY = kData.ReadShort();
		int nNPCID = kData.ReadInt();

		if (kPlayer.m_nID == nPlayerID)
		{
			CloseProgressBar;

			if (0 != nNPCID)
			{
				NDNpc* pkNPC = 0;
			}
		}
	}
}

NDNpc* NDMapMgr::GetNPC(int nID)
{
	for (VEC_NPC::iterator it = m_vNPC.begin(); m_vNPC.end() != it; it++)
	{
		NDNpc* pkTemp = *it;

		if (nID != pkTemp->m_nID)
		{
			continue;
		}

		return pkTemp;
	}

	return 0;
}

void NDMapMgr::processChangeRoom(NDTransData* pkData, int nLength)
{
 	if (0 == pkData || 0 == nLength)
 	{
 		return;
 	}

	m_nCurrentMonsterBound = 0;

	if (m_bVerifyVersion)
	{
		m_bVerifyVersion = false;
		//NDBeforeGameMgrObj.VerifyVersion();
	}

	m_nRoadBlockX = -1;
	m_nRoadBlockY = -1;

	BattleMgrObj.quitBattle(false);

 	pkData->ReadShort();
 	pkData->ReadInt();
 
 	int nMapID = pkData->ReadInt();
 	int nMapDocID = pkData->ReadInt();

 	int dwPortalX = pkData->ReadShort();
 	int dwPortalY = pkData->ReadShort();

	pkData->ReadShort();
	pkData->ReadShort();
	pkData->ReadShort();
	pkData->ReadShort();

 	m_nMapType = pkData->ReadInt();

 	m_strMapName = pkData->ReadUnicodeString();
 
 	NDPlayer& kPlayer = NDPlayer::defaultHero(1);
// 
// 	if (kPlayer.IsInState(USERSTATE_DEAD))
// 	{
// 		NDUISynLayer::Close (SYN_RELIEVE);
// 	}
// 
// 	NDUISynLayer::Close (SYN_CREATE_ROLE);
 
 	NDMapMgrObj.ClearManualRole();
 
 	m_nMapID = nMapID;
 
 	if (1 == m_nMapID || 2 == m_nMapID)
 	{
 		m_nSaveMapID = m_nMapID;
 	}
 
  	kPlayer.m_nCurMapID = nMapDocID;
   
   	ShowPetInfo kPetInfoRerserve;
  // 	kPlayer.GetShowPetInfo(kPetInfoRerserve);
  	kPlayer.m_strName = string("efawfawe");
   //	kPlayer.ResetShowPet();
  
//   	if (kPlayer.GetParent() != 0)
//   	{
//   		NDRidePet* pkRidePet = NDPlayer::defaultHero().GetRidePet();
//   
//   		if (0 != pkRidePet && 0 != pkRidePet->GetParent())
//   		{
//   			pkRidePet->RemoveFromParent(false);
//   		}
//   
//   		kPlayer.RemoveFromParent(false);
//   	}
 
 	while (NDDirector::DefaultDirector()->PopScene())
 	{
 	}
 
 	NDMapMgrObj.ClearNPC();
 	NDMapMgrObj.ClearMonster();
 	NDMapMgrObj.ClearGP();
 	NDMapMgrObj.loadSceneByMapDocID(nMapDocID);
 
  	NDMapLayer* pkLayer = NDMapMgrObj.getMapLayerOfScene(
  			NDDirector::DefaultDirector()->GetRunningScene());
  
  	int nTheID = GetMotherMapID();
 // 	int nTitleID = ScriptDBObj.GetN("map", nTheID, DB_MAP_TITLE);
  	//pkLayer->ShowTitle(nTitleID, 0);
  
  	if (0 == pkLayer)
  	{
  		return;
  	}
  
	kPlayer.SetPosition(ccp(dwPortalX * MAP_UNITSIZE + DISPLAY_POS_X_OFFSET,
		dwPortalY * MAP_UNITSIZE + DISPLAY_POS_Y_OFFSET));
	kPlayer.SetServerPositon(dwPortalX, dwPortalY);
	kPlayer.SetShowPet(kPetInfoRerserve);
  	kPlayer.stopMoving();
  
//   	NDRidePet* pkRidePet = kPlayer.GetRidePet();
//   
//   	if (0 != pkRidePet)
//   	{
//   		pkRidePet->stopMoving();
//   		pkRidePet->SetPositionEx(
//   				ccp(dwPortalX * MAP_UNITSIZE + DISPLAY_POS_X_OFFSET,
//   						dwPortalY * MAP_UNITSIZE + DISPLAY_POS_Y_OFFSET));
//   	}
  
  	pkLayer->SetScreenCenter(ccp(dwPortalX * MAP_UNITSIZE + DISPLAY_POS_X_OFFSET,
		dwPortalY * MAP_UNITSIZE + DISPLAY_POS_Y_OFFSET));

  	kPlayer.SetAction(false);
  	kPlayer.SetLoadMapComplete();
  
  //	ItemMgrObj.SortBag();
  
  	ScriptGlobalEvent::OnEvent (GE_GENERATE_GAMESCENE);
  
  	if (nTheID / 100000000 > 0)
  	{
  		//	ScriptMgrObj.excuteLuaFunc("SetUIVisible","",0);
  	}
  	else
  	{
  		pkLayer->AddChild(&kPlayer, 111, 1000);
  		//	ScriptMgrObj.executeLuaFunc("SetUIVisible","",1);
  	}

//	CloseProgressBar;

//	NDMapMgrObj.LoadSceneMonster();
}

void NDMapMgr::processNPCInfoList(NDTransData* pkData, int nLength)
{
	const int LIST_ACTION_END = 1;
	//NDLog(@"处理NPC消息-----------");
	unsigned char btAction = 0;
	(*pkData) >> btAction;
	unsigned char btCount = 0;
	(*pkData) >> btCount;

	for (int i = 0; i < btCount; i++)
	{
		int nID = 0;
		(*pkData) >> nID; // 4个字节 npc id
		unsigned char uitype = 0;
		(*pkData) >> uitype; // 该字段用于过滤寻路的npc列表
		int usLook = 0;
		(*pkData) >> usLook; // 4个字节
		unsigned char btSort = 0;
		(*pkData) >> btSort;
		unsigned short usCellX = 0;
		(*pkData) >> usCellX; // 2个字节
		unsigned short usCellY = 0;
		(*pkData) >> usCellY; // 2个字节
		unsigned char btState = 0;
		(*pkData) >> btState; // 1个字节表状态
		unsigned char btCamp = 0;
		(*pkData) >> btCamp;
		CCString* pstrTemp = CCString::stringWithUTF8String(pkData->ReadUnicodeString().c_str());
		std::string strName = pstrTemp->toStdString();
		SAFE_DELETE(pstrTemp);

		pstrTemp = CCString::stringWithUTF8String(pkData->ReadUnicodeString().c_str());
		std::string dataStr = pstrTemp->toStdString();
		SAFE_DELETE(pstrTemp);
		pstrTemp = CCString::stringWithUTF8String(pkData->ReadUnicodeString().c_str());
		std::string talkStr = pstrTemp->toStdString();
		SAFE_DELETE(pstrTemp);

		NDNpc *pkNPC = new NDNpc;
		pkNPC->m_nID = nID;
		pkNPC->m_nCol = usCellX;
		pkNPC->m_nRow = usCellY;
		pkNPC->m_nLook = usLook;
		pkNPC->SetCamp(CAMP_TYPE(btCamp));

		if (uitype == 6)
		{
			pkNPC->m_strName = "";
		}
		else
		{
			pkNPC->m_strName = strName;
		}

		pkNPC->SetPosition(
			ccp(usCellX * MAP_UNITSIZE + DISPLAY_POS_X_OFFSET,
			usCellY * MAP_UNITSIZE + DISPLAY_POS_Y_OFFSET));
		pkNPC->m_strData = dataStr;
		pkNPC->m_strTalk = talkStr;
		pkNPC->SetType(uitype);
		pkNPC->Initialization(usLook);

		if (btSort != 0)
		{
			pkNPC->SetActionOnRing(false);
			pkNPC->SetDirectOnTalk(false);
		}

		pkNPC->initUnpassPoint();
		NDMapMgrObj.m_vNPC.push_back(pkNPC);
	}

	if (btAction == LIST_ACTION_END)
	{ // 收发结束
		NDMapMgrObj.AddAllNPCToMap();
	}

	NDMapMgrObj.AddAllNPCToMap();
}

void NDMapMgr::AddAllNPCToMap()
{
	NDMapLayer* pkLayer = (NDMapLayer*) getMapLayerOfScene(
			NDDirector::DefaultDirector()->GetRunningScene());

	if (0 == pkLayer)
	{
		return;
	}

	for (VEC_NPC::iterator it = m_vNPC.begin(); m_vNPC.end() != it; it++)
	{
		NDNpc* pkNPC = *it;

		if (pkLayer->ContainChild(pkNPC))
		{
			continue;
		}

		pkLayer->AddChild((NDNode*) pkNPC,2,100);

// 		if (0 != pkNPC->GetRidePet())
// 		{
// 			pkNPC->GetRidePet()->stopMoving();
// 			pkNPC->GetRidePet()->SetPositionEx(pkNPC->GetPosition());
// 			pkNPC->GetRidePet()->SetCurrentAnimation(RIDEPET_STAND,
// 					pkNPC->m_bFaceRight);
// 		}

		pkNPC->HandleNPCMask(true);
	}

	NDPlayer::defaultHero().UpdateFocus();
}

void NDMapMgr::OnCustomViewRadioButtonSelected(NDUICustomView* customView,
		unsigned int radioButtonIndex, int ortherButtonTag)
{
	throw std::exception("The method or operation is not implemented.");
}

void NDMapMgr::ClearManualRole()
{
	if (m_mapManualRole.empty())
	{
		return;
	}

	for (map_manualrole::iterator it = m_mapManualRole.begin();
			m_mapManualRole.end() != it; it++)
	{
		NDManualRole* pkRole = it->second;
		SAFE_DELETE_NODE(pkRole);
	}
}

void NDMapMgr::ClearNPC()
{
	if (m_vNPC.empty())
	{
		return;
	}

	for (VEC_NPC::iterator it = m_vNPC.begin(); m_vNPC.end() != it; it++)
	{
		NDNpc* pkRole = *it;
		SAFE_DELETE_NODE(pkRole);
	}
}

void NDMapMgr::ClearMonster()
{
	if (m_vMonster.empty())
	{
		return;
	}

	for (VEC_MONSTER::iterator it = m_vMonster.begin(); m_vMonster.end() != it;
			it++)
	{
		NDMonster* pkRole = *it;
		SAFE_DELETE_NODE(pkRole);
	}
}

void NDMapMgr::ClearGP()
{

}

bool NDMapMgr::loadSceneByMapDocID(int nMapID)
{
	m_nMapDocID = nMapID;

	NDDirector::DefaultDirector()->PurgeCachedData();
	NDDirector::DefaultDirector()->ReplaceScene(NDScene::Scene());

	CSMGameScene* pkScene = CSMGameScene::Scene();
	NDDirector::DefaultDirector()->ReplaceScene(pkScene);
	pkScene->Initialization(nMapID);
	pkScene->SetTag(SMGAMESCENE_TAG);

	NDMapLayer* pkMapLayer = getMapLayerOfScene(pkScene);

	if (0 != pkMapLayer)
	{
		m_kMapSize = pkMapLayer->GetContentSize();
	}
	else
	{
		m_kMapSize = CCSizeZero;
	}

	AddSwitch();

	return true;
}

void NDMapMgr::AddSwitch()
{
	NDScene* pkScene = NDDirector::DefaultDirector()->GetScene(
			RUNTIME_CLASS(CSMGameScene));
	NDMapLayer* pkLayer = 0;
	NDMapData* pkMapData = 0;

	if (0 != pkScene || 0 == (pkLayer = getMapLayerOfScene(pkScene))
			|| 0 == (pkMapData = pkLayer->GetMapData()))
	{
		return;
	}

	ScriptDB& kScriptDB = ScriptDBObj;
	ID_VEC kIDList;
	kScriptDB.GetIdList("portal", kIDList);

	for (ID_VEC::iterator it = kIDList.begin(); kIDList.end() != it; it++)
	{
		int nMapID = GetMapID();

		if (kScriptDB.GetN("portal", *it, DB_PORTAL_MAPID) == nMapID)
		{
			int nIndex = kScriptDB.GetN("portal", *it, DB_PORTAL_PORTAL_INDEX);
			int nX = kScriptDB.GetN("portal", *it, DB_PORTAL_PORTALX);
			int nY = kScriptDB.GetN("portal", *it, DB_PORTAL_PORTALY);

			string strDesc = "城門";

			pkMapData->addMapSwitch(nX, nY, nIndex, nMapID,
				strDesc.c_str(), "");
		}
	}

	pkLayer->MapSwitchRefresh();
}

int NDMapMgr::GetMapID()
{
	return m_nMapID;
}

int NDMapMgr::GetMotherMapID()
{
	int nTheID = m_nMapID;

	if (m_nMapID / 10000000 > 0)
	{
		nTheID = m_nMapID / 100000 * 100000;
	}

	return nTheID;
}

void NDMapMgr::LoadSceneMonster()
{
	int nTheID = GetMotherMapID();
	ID_VEC kIDList;
	ScriptDBObj.GetIdList("mapzone", kIDList);

	for (unsigned int i = 0; i < kIDList.size(); i++)
	{
		int m_nID = ScriptDBObj.GetN("mapzone", kIDList.at(i),
				DB_MAPZONE_MAPID);
		if (m_nID == nTheID)
		{

			NDMapLayer* pkLayer = NDMapMgrObj.getMapLayerOfScene(
					NDDirector::DefaultDirector()->GetRunningScene());
			if (!pkLayer)
			{
				return;
			}
			NDMonster* pkMonster = new NDMonster();
			int elite_flag = ScriptDBObj.GetN("mapzone", kIDList.at(i),
					DB_MAPZONE_ELITE_FLAG);

			pkMonster->m_nID = ScriptDBObj.GetN("mapzone", kIDList.at(i),
					DB_MAPZONE_ID);
			int col = ScriptDBObj.GetN("mapzone", kIDList.at(i),
					DB_MAPZONE_POS_X);
			int row = ScriptDBObj.GetN("mapzone", kIDList.at(i),
					DB_MAPZONE_POS_Y);
			int idType = ScriptDBObj.GetN("mapzone", kIDList.at(i),
					DB_MAPZONE_MONSTER_TYPE);
			int atk_area = ScriptDBObj.GetN("mapzone", kIDList.at(i),
					DB_MAPZONE_ATK_AREA);
			int rule_id = ScriptDBObj.GetN("mapzone", kIDList.at(i),
					DB_MAPZONE_GENERATE_RULE_ID);
			pkMonster->Initialization(idType);
			NDMapMgrObj.m_vMonster.push_back(pkMonster);
		}
	}
	NDMapMgrObj.AddAllMonsterToMap();
}

void NDMapMgr::AddAllMonsterToMap()
{
	NDMapLayer* pkLayer = getMapLayerOfScene(
			NDDirector::DefaultDirector()->GetRunningScene());

	if (0 == pkLayer)
	{
		return;
	}

	for (VEC_MONSTER::iterator it = m_vMonster.begin(); m_vMonster.end() != it;
			it++)
	{
		NDMonster* pkMonster = *it;

		if (0 != pkMonster && pkMonster->m_nID > 0
				&& pkMonster->getState() == MONSTER_STATE_DEAD)
		{
			continue;
		}

		if (pkMonster->GetParent() == 0)
		{
			pkLayer->AddChild((NDNode*) pkMonster, 0, 0);
		}

		///< 这里添加gather... 郭浩
	}
}

bool NDMapMgr::processConsole( const char* pszInput )
{
	if (true)
	{
		return false;
	}

	string strInput = pszInput;

	printf("開始分析要模擬的包……\n");

	NDTransData kTransData;

	vector<string> kStringVector;
	int nPos = 0;
	int nStartPos = 0;
	int nOmegaPos = 0;
	short usMsgID = 0;
	unsigned char szBuffer[1024] = {0};
	unsigned int pPos = 0;

	nOmegaPos = strInput.find(';');
	unsigned int nLength = strInput.length();

	if (strInput.length() - 3 != nOmegaPos)
	{
		printf("语法错误\n");
		return false;
	}

	while(true)
	{
		nPos = strInput.find(',');
		int nKeywordPos = 0;

		string strNum;

		if (-1 == nPos)
		{
			strNum = strInput.substr(0,strInput.length() - 3);
			break;
		}
		else
		{
			strNum = strInput.substr(nStartPos,nPos);
		}

		if (0 == strNum.length())
		{
			printf("出错\n");
			break;
		}

		int uiData = 0;
		short usData = 0;
		char ucData = 0;
		strInput = strInput.substr(nPos + 1,strInput.length());

		if (GetShortData(usMsgID,strNum,string("id")))
		{
			if (0 == usMsgID)
			{
				return false;
			}
		}
		else if (GetIntData(uiData,strNum,string("int")))
		{
			kTransData.WriteInt(uiData);
		}
		else if (GetShortData(usData,strNum,string("short")))
		{
			kTransData.WriteShort(usData);
		}
		else if (GetCharData(ucData,strNum,string("char")))
		{
			kTransData.WriteByte(ucData);
		}
	}
	
	process(usMsgID,&kTransData,0);
	
	printf("分析完畢!\n");

	return true;
}

void NDMapMgr::OnTimer( OBJID tag )
{
	const char* pszCommand = NDConsole::GetSingletonPtr()->GetSpecialCommand("sim ");

	if (0 != pszCommand && *pszCommand)
	{
		string strInput = pszCommand;

		printf("開始分析要模擬的包……\n");

		NDTransData kTransData;

		vector<string> kStringVector;
		int nPos = 0;
		int nStartPos = 0;
		int nOmegaPos = 0;
		short usMsgID = 0;
		unsigned char szBuffer[1024] = {0};
		unsigned int pPos = 0;

		nOmegaPos = strInput.find(';');
		unsigned int nLength = strInput.length();

		if (strInput.length() - 3 != nOmegaPos)
		{
			printf("语法错误\n");
			return;
		}

		while(true)
		{
			nPos = strInput.find(',');
			int nKeywordPos = 0;

			string strNum;

			if (-1 == nPos)
			{
				strNum = strInput.substr(0,strInput.length() - 3);
				break;
			}
			else
			{
				strNum = strInput.substr(nStartPos,nPos);
			}

			if (0 == strNum.length())
			{
				printf("出错\n");
				break;
			}

			int uiData = 0;
			short usData = 0;
			char ucData = 0;
			strInput = strInput.substr(nPos + 1,strInput.length());

			if (GetShortData(usMsgID,strNum,string("id")))
			{
				if (0 == usMsgID)
				{
					return;
				}
			}
			else if (GetIntData(uiData,strNum,string("int")))
			{
				kTransData.WriteInt(uiData);
			}
			else if (GetShortData(usData,strNum,string("short")))
			{
				kTransData.WriteShort(usData);
			}
			else if (GetCharData(ucData,strNum,string("char")))
			{
				kTransData.WriteByte(ucData);
			}
		}

		process(usMsgID,&kTransData,0);

		printf("分析完畢!\n");
	}
}

NDMonster* NDMapMgr::GetBattleMonster()
{
	return m_apWaitBattleMonster;
}

void NDMapMgr::SetBattleMonster( NDMonster* pkMonster )
{
	if (0 == pkMonster)
	{
		m_apWaitBattleMonster.Clear();
	}
	else
	{
		m_apWaitBattleMonster = pkMonster->QueryLink();
	}
}

void NDMapMgr::ProcessLoginSuc( NDTransData& kData )
{
	ScriptMgrObj.excuteLuaFunc("ProcessLoginSuc", "MsgLoginSuc",0);
}

void NDMapMgr::processNpcTalk( NDTransData& kData )
{
	int nAction = kData.ReadByte();
	int nID = kData.ReadInt();
	int nTime = kData.ReadInt();
	std::string strMessage = kData.ReadUnicodeString2();
	switch(nAction)
	{
	case 0:
		{
			NDManualRole* pkPlayer=GetManualRole(nID);
			if(pkPlayer!=NULL){
				pkPlayer->addTalkMsg(strMessage,nTime);
			}
			break;
		}
	case 1:
		{
			CloseProgressBar;
			NDNpc *pkNPC = GetNPC(nID);
			if (pkNPC != NULL) {
				pkNPC->addTalkMsg(strMessage,nTime);
			}
			break;
		}
	case 2:
		{
			NDMonster *pkMonster=GetMonster(nID);
			if (pkMonster != NULL) {
				pkMonster->addTalkMsg(strMessage,nTime);
			}
		}
		break;
	}
}

NDMonster* NDMapMgr::GetMonster( int nID )
{
	for (VEC_MONSTER::iterator it = m_vMonster.begin();
		it != m_vMonster.end(); it++)
	{
		NDMonster *pkTempMonster = *it;

		if (pkTempMonster->m_nID == nID) 
		{
			return pkTempMonster;
		}
	}

	return NULL;
}

void NDMapMgr::processMsgCommonList( NDTransData& kData )
{
	///< 依赖汤自勤的NewPaiHangScene 郭浩

// 	int iID = kData.ReadInt();
// 	int field_count = kData.ReadInt();
// 	int button_count = kData.ReadInt();
// 	string title = kData.ReadUnicodeString();
// 
// 	NewPaiHangScene::curPaiHangType = iID;
// 
// 	std::vector<int>& fildTypes = NewPaiHangScene::s_PaiHangTitle[iID].fildTypes;
// 	std::vector<std::string>& fildNames = NewPaiHangScene::s_PaiHangTitle[iID].fildNames;
// 
// 	fildTypes.clear();
// 	fildNames.clear();
// 
// 	for (int i = 0; i < field_count; i++) {
// 		fildTypes.push_back(kData.ReadByte());
// 		fildNames.push_back(kData.ReadUnicodeString());
// 	}
// 
// 	for (int i = 0; i < button_count; i++) {
// 		kData.ReadUnicodeString();
// 	}
}

void NDMapMgr::processMsgCommonListRecord( NDTransData& kData )
{
	///< 依赖汤自勤的NewPaiHangScene 郭浩

// 	int packageFlag = kData.ReadByte();
// 	int curCount = kData.ReadByte();
// 	kData.ReadShort();
// 
// 
// 	std::vector<int>& fildTypes = NewPaiHangScene::s_PaiHangTitle[NewPaiHangScene::curPaiHangType].fildTypes;
// 	std::vector<std::string>& values = NewPaiHangScene::values[NewPaiHangScene::curPaiHangType];
// 	values.clear();
// 	for (int i = 0; i < curCount; i++) {
// 		kData.ReadInt(); // button id
// 		for (int j = 0; j < int(fildTypes.size()); j++) {
// 			if (fildTypes[j] == 0) {
// 				std::stringstream ss; ss << (kData.ReadInt());
// 				values.push_back(ss.str());
// 			} else if (fildTypes[j] == 1) {
// 				values.push_back(kData.ReadUnicodeString());				
// 			}
// 		}
// 	}
// 
// 	if ((packageFlag & 2) > 0) {
// 		NewPaiHangScene::refresh();
// 		CloseProgressBar;
// 	}
}

void NDMapMgr::processMonsterInfo(NDTransData* pkData, int nLength)
{
	///< 此函数所有注释都依赖汤自勤的GatherPoint 郭浩

	unsigned char btAction = 0; (*pkData) >> btAction;
	unsigned char count = 0;  (*pkData) >> count;

	switch(btAction)
	{
		case MONSTER_INFO_ACT_INFO:
			for (int i = 0; i < count; i++)
			{
				
				int idType = 0; (*pkData) >> idType;
				int lookFace = 0; (*pkData) >> lookFace;
				unsigned char lev = 0; (*pkData) >> lev;
				unsigned char  btAiType = 0; (*pkData) >> btAiType;
				unsigned char  btCamp = 0; (*pkData) >> btCamp;
				unsigned char  btAtkArea = 0; (*pkData) >> btAtkArea;
				std::string name = pkData->ReadUnicodeString(); //这个字符串可能需要做修改
				
				monster_type_info info;
				info.idType = idType;
				info.lookFace = lookFace;
				info.lev = lev;
				info.btAiType = btAiType;
				info.btCamp = btCamp;
				info.btAtkArea = btAtkArea;
				info.name = name;
				//if (lookFace == 19070 || lookFace == 206) continue;
				
				NDMapMgrObj.m_mapMonsterInfo.insert(monster_info_pair(idType, info));
			}
			break;
		case MONSTER_INFO_ACT_POS:
			for (int i = 0; i < count; i++)
			{
				int idMonster  = 0; (*pkData) >> idMonster;
				int idType = 0; (*pkData) >> idType;
				unsigned short col = 0; (*pkData) >> col;
				unsigned short row = 0; (*pkData) >> row;
				unsigned char  btState = 0; (*pkData) >> btState;
				
				NDLayer *layer = NDMapMgrObj.getMapLayerOfScene( NDDirector::DefaultDirector()->GetRunningScene());
				if (!layer)
				{
					return;
				}

				if (idType / 1000000 == 6)
				{ // 采集
					//GatherPoint *gp = NULL;
// 					if (idMonster > 0)
// 					{
// 						//map_gather_point_it it = m_mapGP.find(idMonster);
// 						if (it != m_mapGP.end())
// 						{
// 							gp = it->second;
// 						}
// 					}
					
					//if (gp == NULL) 
					//{
						//gp = new GatherPoint(idMonster, idType, col*MAP_UNITSIZE,
						//					 row *MAP_UNITSIZE, idMonster > 0, "");
						//m_mapGP.insert(map_gather_point_pair(idMonster, gp));
					//}
					
					//gp->setState(btState);
					
					continue;
				}
				
				monster_type_info info;
				if ( !NDMapMgrObj.GetMonsterInfo(info, idType) ) continue;

				NDMonster* monster = new NDMonster;
				monster->m_nID = idMonster;
				monster->SetPosition(ccp(col*MAP_UNITSIZE, row*MAP_UNITSIZE));
				monster->Initialization(idType);
				monster->SetType(MONSTER_ELITE);
				if (idMonster > 0)
				{
					monster->setState(btState);
				}
				
				NDMapMgrObj.m_vMonster.push_back(monster);
				
			}
			NDMapMgrObj.AddAllMonsterToMap();
			break;
		case MONSTER_INFO_ACT_STATE:
			for (int i = 0; i < count; i++)
			{
				int idMonster = 0; (*pkData) >> idMonster;
				unsigned char btState = 0; (*pkData) >> btState;
				if (idMonster > 0)
				{
// 					GatherPoint *gp = NULL;
// 					if (idMonster > 0)
// 					{
// 						map_gather_point_it it = m_mapGP.find(idMonster);
// 						if (it != m_mapGP.end())
// 						{
// 							gp = it->second;
// 						}
// 					}
// 					
// 					if (gp == NULL) 
// 					{
// 						for_vec(m_vMonster, vec_monster_it)
// 						{
// 							if ((*it)->m_nID == idMonster)
// 							{
// 								(*it)->setState(btState);
// 							}
// 						}
// 					}
// 					else
// 					{
// 						gp->setState(btState);
// 					}
				}
			}
			break;
		case MONSTER_INFO_ACT_BOSS_POS:
			for (int i = 0; i < count; i++)
			{
				int idMonster  = 0; (*pkData) >> idMonster;
				int idType = 0; (*pkData) >> idType;
				unsigned short col = 0; (*pkData) >> col;
				unsigned short row = 0; (*pkData) >> row;
				unsigned char  btState = 0; (*pkData) >> btState;
				
				NDLayer *layer = NDMapMgrObj.getMapLayerOfScene( NDDirector::DefaultDirector()->GetRunningScene());
				if (!layer)
				{
					return;
				}
				
				if (idType / 1000000 == 6)
				{ // 采集
// 					GatherPoint *gp = NULL;
// 					if (idMonster > 0)
// 					{
// 						map_gather_point_it it = m_mapGP.find(idMonster);
// 						if (it != m_mapGP.end())
// 						{
// 							gp = it->second;
// 						}
// 					}
// 					
// 					if (gp == NULL) 
// 					{
// 						gp = new GatherPoint(idMonster, idType, col*MAP_UNITSIZE,
// 											 row *MAP_UNITSIZE, idMonster > 0, "");
// 						m_mapGP.insert(map_gather_point_pair(idMonster, gp));
// 					}
// 					
// 					gp->setState(btState);
					
					continue;
				}
				
				monster_type_info info;
				NDMonster *monster = new NDMonster;
				monster->m_nID = idMonster;
				monster->SetPosition(ccp(col*MAP_UNITSIZE, row*MAP_UNITSIZE));
				monster->Initialization(idType);
				monster->SetType(MONSTER_BOSS);
				if (idMonster > 0)
				{
					monster->setState(btState);
				}
				
				
				NDMapMgrObj.m_vMonster.push_back(monster);
				
			}
			NDMapMgrObj.AddAllMonsterToMap();
			break;
		case MONSTER_INFO_ACT_BOSS_STATE:
			for (int i = 0; i < count; i++)
			{
				int idMonster = 0; (*pkData) >> idMonster;
				unsigned char btState = 0; (*pkData) >> btState;
				if (idMonster > 0)
				{
					for_vec(m_vMonster, vec_monster_it)
					{
						if ((*it)->m_nID == idMonster&&(*it)->GetType() == MONSTER_BOSS)
						{
							(*it)->setState(btState);
						}
					}
				}
			}
			break;
	}
}

bool NDMapMgr::GetMonsterInfo( monster_type_info& kInfo, int nType )
{
	monster_info_it it = m_mapMonsterInfo.find(nType);

	if (it == m_mapMonsterInfo.end())
	{
		return false;
	}

	kInfo = it->second;
	return true;
}

void NDMapMgr::BattleEnd( int iResult )
{
	NDMonster* monster = GetBattleMonster();
	if (monster&&monster->getState()!=MONSTER_STATE_DEAD) 
	{
		monster->endBattle();
		monster->setMonsterStateFromBattle(iResult);
		SetBattleMonster(0);
	}

	if (BATTLE_COMPLETE_WIN==iResult)
	{
		m_nCurrentMonsterRound++;
	}else{
		if(BattleMgrObj.GetBattle()->GetBattleType()==BATTLE_TYPE_MONSTER)
		{
			if(monster)
			{
				monster->restorePosition();

				NDPlayer& player = NDPlayer::defaultHero();

				player.SetPosition(ccp(monster->m_nSelfMoveRectX-64, monster->GetPosition().y));
				player.SetServerPositon((monster->m_nSelfMoveRectX-64)/MAP_UNITSIZE, (monster->GetPosition().y)/MAP_UNITSIZE);

				Battle* battle = BattleMgrObj.GetBattle();
				if (battle)
				{
					battle->setSceneCetner(monster->m_nSelfMoveRectX-64, monster->GetPosition().y);
					player.stopMoving();
				}else{
					NDMapLayer *layer = NDMapMgrObj.getMapLayerOfScene( NDDirector::DefaultDirector()->GetRunningScene());

					if (layer) 
					{
						layer->SetScreenCenter(ccp(monster->m_nSelfMoveRectX-64, monster->GetPosition().y));
					}
					player.stopMoving();
				}
			}
		}
	}

	NDPlayer::defaultHero().BattleEnd(iResult);
}

void NDMapMgr::processNpcStatus( NDTransData* pkData, int nLength )
{
	unsigned char ucCount = 0;
	(*pkData) >> ucCount;

	for (int i = 0; i < ucCount; i++)
	{
		int nNPCID = 0; nNPCID = pkData->ReadInt();
		unsigned char ucState = 0; (*pkData) >> ucState;
		NDNpc *pkNPC = NULL;
		for_vec(m_vNPC, VEC_NPC::iterator)
		{
			if ((*it) && (*it)->m_nID == nNPCID)
			{
				pkNPC = *it;
			}
		}
		if (pkNPC)
		{
			pkNPC->SetNpcState(NPC_STATE(ucState));
		}
	}
}

void NDMapMgr::processDisappear( NDTransData* pkData, int nLength )
{
	if (!pkData || nLength == 0) return ;

	int nUserID = 0;
	(*pkData) >> nUserID;

	NDManualRole *pkRole = GetManualRole(nUserID);
	if (pkRole)
	{
		pkRole->m_bClear = true;

		BattleMgr& kBattleMgr = BattleMgrObj;

		if (kBattleMgr.GetBattle()
			&& kBattleMgr.GetBattle()->OnRoleDisapper(pkRole->m_nID)) 
		{
			pkRole->RemoveFromParent(false);
		}

		NDPlayer::defaultHero().UpdateFocusPlayer();
	}
}

}