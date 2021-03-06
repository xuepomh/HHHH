/*
 *  GameUIRequest.mm
 *  DragonDrive
 *
 *  Created by jhzheng on 11-3-11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include "GameUIRequest.h"
#include "NDUIBaseGraphics.h"
#include "NDDirector.h"
#include "NDUIBaseGraphics.h"
#include "NDMapMgr.h"
#include "NDPlayer.h"
#include "NDUtility.h"
#include "GameScene.h"
#include "NDUIButton.h"
#include "EnumDef.h"
#include "NDUILabel.h"
#include "NDUISynLayer.h"
#include "TaskListener.h"
#include <sstream>
#include "NDString.h"
#include "SocialScene.h"
#include "NewChatScene.h"

std::string RequsetInfo::text[ACTION_END] =
{ 
	NDCommonCString("FriendAddGuo"), 
	NDCommonCString("TeamInviteGuo"), 
	NDCommonCString("RefraseReqGuo"), 
	NDCommonCString("MasterReqGuo"), 
	NDCommonCString("TutorReqGuo"), 
	NDCommonCString("JunTuanInviteGuo"), 
	NDCommonCString("NewMailGuo"), 
	NDCommonCString("NewChatGuo"),};

///////////////////////////////////

#define title_height 28
#define bottom_height 42
#define MAIN_TB_X (5)

#define BTN_W (85)
#define BTN_H (23)

#define DIS_COUNT (20)

IMPLEMENT_CLASS(GameUIRequest, NDUIMenuLayer)

GameUIRequest::GameUIRequest()
{
	m_lbTitle = NULL;
	m_tlMain = NULL;
	m_dlgDeal = NULL;
}

GameUIRequest::~GameUIRequest()
{
}

void GameUIRequest::Initialization()
{
	NDUIMenuLayer::Initialization();
	
	if ( this->GetCancelBtn() ) 
	{
		this->GetCancelBtn()->SetDelegate(this);
	}
	
	CGSize winsize = NDDirector::DefaultDirector()->GetWinSize();
	
	CGSize dim = getStringSizeMutiLine("请求列表", 15);
	m_lbTitle = new NDUILabel;
	m_lbTitle->Initialization();
	m_lbTitle->SetFontSize(15);
	m_lbTitle->SetFontColor(ccc4(255, 245, 0, 255));
	m_lbTitle->SetFrameRect(CGRectMake((winsize.width-dim.width)/2, (title_height-dim.height)/2, dim.width, dim.height));
	m_lbTitle->SetText("请求列表");
	this->AddChild(m_lbTitle);
	
	NDUILayer *tmpLayer = new NDUILayer;
	tmpLayer->Initialization();
	tmpLayer->SetFrameRect(CGRectMake(MAIN_TB_X, title_height+2, winsize.width-2*MAIN_TB_X, 20));
	tmpLayer->SetBackgroundColor(ccc4(119,119,119,255));
	this->AddChild(tmpLayer);
	
	NDUILabel *tmpName = new NDUILabel;
	tmpName->Initialization();
	tmpName->SetTextAlignment(LabelTextAlignmentLeft);
	tmpName->SetText("玩家姓名");
	tmpName->SetFontSize(15);
	tmpName->SetFontColor(ccc4(0, 0, 0, 255));
	tmpName->SetFrameRect(CGRectMake(10, (20-15)/2, winsize.width, 15));
	tmpLayer->AddChild(tmpName);
	
	NDUILabel *tmpState = new NDUILabel;
	tmpState->Initialization();
	tmpState->SetTextAlignment(LabelTextAlignmentLeft);
	tmpState->SetText("请求");
	tmpState->SetFontSize(15);
	tmpState->SetFontColor(ccc4(0, 0, 0, 255));
	tmpState->SetFrameRect(CGRectMake(260, (20-15)/2, winsize.width, 15));
	tmpLayer->AddChild(tmpState);
	
	m_tlMain = new NDUITableLayer;
	m_tlMain->Initialization();
	m_tlMain->SetDelegate(this);
	m_tlMain->SetVisible(false);
	m_tlMain->VisibleSectionTitles(false);
	m_tlMain->SetBackgroundColor(ccc4(255, 255, 255, 0));
	this->AddChild(m_tlMain);
	
	UpdateMainUI();
}

void GameUIRequest::OnButtonClick(NDUIButton* button)
{
	if (button == this->GetCancelBtn())
	{
		if (this->GetParent() && this->GetParent()->IsKindOfClass(RUNTIME_CLASS(GameScene))) 
		{
			((GameScene*)(this->GetParent()))->SetUIShow(false);
			this->RemoveFromParent(true);
		}
	}
}

void GameUIRequest::OnTableLayerCellSelected(NDUITableLayer* table, NDUINode* cell, unsigned int cellIndex, NDSection* section)
{
	if (table == m_tlMain)
	{
		if (!cell->IsKindOfClass(RUNTIME_CLASS(NDUIPlayerInfo)))
		{
			return;
		}
		
		int iID = cell->GetTag();
		RequsetInfo request;
		if ( !NDMapMgrObj.GetRequest(iID, request) )
		{
			return;
		}
		
		int action = request.getMAction();
		// final int id = request.getMId();
		std::string tip;
		switch (action) {
			case RequsetInfo::ACTION_FRIEND: {
				tip += " 请求与你结为好友,是否同意?";
				break;
			}
				
			case RequsetInfo::ACTION_TEAM: {
				tip += " 邀请你加入队伍,是否同意?";
				break;
			}
			case RequsetInfo::ACTION_BIWU: {
				tip += " 邀请与你比武,是否同意?";
				break;
			}
			case RequsetInfo::ACTION_BAISHI: {
				tip += " 请求拜您为师,是否同意?";
				break;
			}
			case RequsetInfo::ACTION_SOUTU: {
				tip += " 请求收您为徒,是否同意?";
				break;
			}
		}
		
		if (tip.empty())
		{
			return;
		}
		
		std::stringstream ss; ss << "玩家" << request.name << tip;
		
		m_dlgDeal = new NDUIDialog;
		m_dlgDeal->Initialization();
		m_dlgDeal->SetTag(iID);
		m_dlgDeal->SetDelegate(this);
		m_dlgDeal->Show("温馨提示", ss.str().c_str(), "返回", "同意", "拒绝", "删除", NULL);
	}
	
}

void sendAcceptFriend(string name, int idObj) {
	NDMapMgr& mgr = NDMapMgrObj;
//	if (mgr.isFriendMax()) {
//		GlobalShowDlg("好友上线限制", "您的好友数量已达到上限，无法再添加好友。");
//	} else 
	{
		if (mgr.isFriendAdded(name)) {
			GlobalShowDlg(NDCommonCString("AddFail"), NDCommonCString("NoToFriendTip"));
		} else {
			NDTransData bao(_MSG_GOODFRIEND);
			bao << (Byte)_FRIEND_ACCEPT
			<< (Byte)1
			<< idObj;
			SEND_DATA(bao);
		}
	}
}

void sendRefuseFriend(int idObj) {
	NDTransData bao(_MSG_GOODFRIEND);
	bao << (Byte)_FRIEND_REFUSE
	<< (Byte)1
	<< idObj;
	SEND_DATA(bao);
}

void GameUIRequest::OnDialogButtonClick(NDUIDialog* dialog, unsigned int buttonIndex)
{
	if (dialog == m_dlgDeal)
	{
		int iID = dialog->GetTag();
		RequsetInfo request;
		if ( !NDMapMgrObj.GetRequest(iID, request) )
		{
			dialog->Close();
			return;
		}
		
		if ( buttonIndex == 0 ) // 同意
		{
			//NDLog(@"%d,%d", request.getMAction(), RequsetInfo::ACTION_TEAM);
			int action = request.getMAction();
			switch (action) {
				case RequsetInfo::ACTION_FRIEND: {
					sendAcceptFriend(request.name, request.iRoleID);
					break;
				}
				case RequsetInfo::ACTION_TEAM: {
					checkTeamAndSend(request.iRoleID, MSG_TEAM_INVITEOK);
					break;
				}
				case RequsetInfo::ACTION_BIWU: {
					sendRehearseAction(request.iRoleID, REHEARSE_ACCEPT); // 同意比武
					break;
				}
				case RequsetInfo::ACTION_BAISHI: {
					NDTransData bao(_MSG_TUTOR);
					bao << (unsigned char)2 << int(request.iRoleID);
					SEND_DATA(bao);
					break;
				}
				case RequsetInfo::ACTION_SOUTU: {
					NDTransData bao(_MSG_TUTOR);
					bao << (unsigned char)5 << int(request.iRoleID);
					SEND_DATA(bao);
					break;
				}
			}
		}
		else if ( buttonIndex == 1 ) // 拒绝
		{
//			if (Task::BEGIN_FRESHMAN_TASK && request.iRoleID == -1) {
//				Chat::DefaultChat()->AddMessage(ChatTypeSystem, "任务进行中，不允许进行该操作！");
//				return;
//			}
			
			switch (request.getMAction()) {
				case RequsetInfo::ACTION_FRIEND: {
					sendRefuseFriend(request.iRoleID);
					break;
				}
				case RequsetInfo::ACTION_TEAM: {
					checkTeamAndSend(request.iRoleID, MSG_TEAM_INVITEFAILE);
					break;
				}
				case RequsetInfo::ACTION_BIWU: { // 拒绝不反应
					//PlayerListScreen.sendRehearseAction(request.getMId(), BattleListener.REHEARSE_REFUSE); // 拒绝比武
					break;
				}
				case RequsetInfo::ACTION_BAISHI: {
					NDTransData bao(_MSG_TUTOR);
					bao << (unsigned char)3 << int(request.iRoleID);
					SEND_DATA(bao);
					break;
				}
				case RequsetInfo::ACTION_SOUTU: {
					NDTransData bao(_MSG_TUTOR);
					bao << (unsigned char)6 << int(request.iRoleID);
					SEND_DATA(bao);
					break;
				}
			}
		}
		else if ( buttonIndex == 2 ) // 删除
		{
//			if (Task::BEGIN_FRESHMAN_TASK && request.iRoleID == -1) {
//				Chat::DefaultChat()->AddMessage(ChatTypeSystem, "任务进行中，不允许进行该操作！");
//				return;
//			}
		}		
			

		NDMapMgrObj.DelRequest(iID);
		UpdateMainUI();
		dialog->Close();
	}
}

void GameUIRequest::draw()
{
	NDUIMenuLayer::draw();
}

void GameUIRequest::UpdateMainUI()
{
	if (!m_tlMain)
	{
		return;
	}
	
	std::vector<RequsetInfo>& requestlist = NDMapMgrObj.GetRequestList();
	if ( requestlist.empty() )
	{
		if (m_tlMain->GetDataSource()) 
		{
			NDDataSource *source = m_tlMain->GetDataSource();
			source->Clear();
			m_tlMain->ReflashData();
		}
		return;
	}
	

	CGSize winsize = NDDirector::DefaultDirector()->GetWinSize();
	int iVecSize = int(requestlist.size());
	int iStart = 0;
	int iEnd = DIS_COUNT >= iVecSize ? iVecSize : DIS_COUNT;
	
	NDDataSource *dataSource = new NDDataSource;
	NDSection *section = new NDSection;
	//section->UseCellHeight(true);
	for (int i = iStart; i < iEnd; i++)
	{
		RequsetInfo& requestinfo = requestlist[iVecSize-1-i];
		NDUIPlayerInfo * info = new NDUIPlayerInfo;
		info->Initialization();
		info->SetPlayerName(requestinfo.name);
		info->SetPlayerNameColor(ccc4(119, 48, 0, 255));
		info->SetPlayerInfo(requestinfo.info);
		info->SetPlayerInfoColor(ccc4(119, 48, 0, 255));
		info->SetFrameRect(CGRectMake(0, 0, winsize.width, 28));
		info->SetTag(requestinfo.iID);
		section->AddCell(info);
	}
	
	dataSource->AddSection(section);
	
	int iHeigh = (iEnd - iStart)*30;//+(iEnd - iStart)+1;
	int iHeighMax = winsize.height-title_height-bottom_height-2*2-20;
	iHeigh = iHeigh < iHeighMax ? iHeigh : iHeighMax;
	
	m_tlMain->SetFrameRect(CGRectMake(MAIN_TB_X, title_height+2+20, winsize.width-2*MAIN_TB_X, iHeigh));
	
	m_tlMain->SetVisible(true);
	
	if (m_tlMain->GetDataSource())
	{
		m_tlMain->SetDataSource(dataSource);
		m_tlMain->ReflashData();
	}
	else
	{
		m_tlMain->SetDataSource(dataSource);
	}
}

bool GameUIRequest::checkTeamAndSend(int senderID, int action)
{
	if (senderID == -1) {
		Task* task = NDPlayer::defaultHero().GetPlayerTask(Task::TASK_TEAM);
		if (task) {
			//Chat::DefaultChat()->AddMessage(ChatTypeSystem, "您加入了NPC的队伍");
			sendTaskFinishMsg(Task::TASK_TEAM);
		}
		return false;
	}
	NDManualRole *role = NDMapMgrObj.GetManualRole(senderID);
	
	if (!role) 
	{
		showDialog("操作失败", "该请求已失效！");
		return false;
	}
	
	sendTeamAction(senderID, action);
	
	return true;
}

#pragma mark 新的请求列表
IMPLEMENT_CLASS(NDRequestCell, NDUINode)


NDRequestCell::NDRequestCell()
{
	m_picBg = m_picQuestType = m_picOk = m_picCancel = NULL;
	
	m_request = NULL;
	
	m_lbKey = m_lbValue = NULL;
}

NDRequestCell::~NDRequestCell()
{
}

void NDRequestCell::Initialization()
{
	NDUINode::Initialization();
	
	NDPicturePool& pool = *(NDPicturePool::DefaultPool());
	
	m_picBg = pool.AddPicture(GetImgPathNew("attr_listitem_bg.png"), 436, 28);
	
	this->SetFrameRect(CGRectMake(0, 0, 436, 28));
	
	m_lbKey = new NDUILabel;
	m_lbKey->Initialization();
	m_lbKey->SetTextAlignment(LabelTextAlignmentLeft);
	m_lbKey->SetFontSize(14);
	m_lbKey->SetFontColor(ccc4(136, 42, 42, 255));
	m_lbKey->SetFrameRect(CGRectMake(34, 7, 436, 28));
	this->AddChild(m_lbKey);
	
	m_lbValue = new NDUILabel;
	m_lbValue->Initialization();
	m_lbValue->SetTextAlignment(LabelTextAlignmentLeft);
	m_lbValue->SetFontSize(14);
	m_lbValue->SetFontColor(ccc4(79, 77, 78, 255));
	m_lbValue->SetFrameRect(CGRectMake(0, 7, 436, 28));
	this->AddChild(m_lbValue);
	
	m_picOk = pool.AddPicture(GetImgPathNew("request_ok.png"));
	
	m_picCancel = pool.AddPicture(GetImgPathNew("request_cancel.png"));
}

void NDRequestCell::Change(RequsetInfo* requestInfo)
{
	m_request = requestInfo;
	
	if (!m_request || !m_request->isValid())
	{
		reset();
		
		return;
	}
	
	if (m_lbKey)
		m_lbKey->SetText(RequsetInfo::text[m_request->iAction].c_str());
	
	int keyWidth = getStringSize(RequsetInfo::text[m_request->iAction].c_str(), 14).width;
	
	std::string text;
	NDString strTime;
	uint unTime = TimeConvert(TIME_MINUTE, requestInfo->nTime);
	strTime.Format("  %d:%d", unTime%10000/100, unTime%100);
	
	switch (m_request->iAction) 
	{
		case RequsetInfo::ACTION_FRIEND:
			text += m_request->name + ": " + NDCommonCString("WantAddFriend");
			break;
		case RequsetInfo::ACTION_TEAM:
			text += m_request->name + ": " + NDCommonCString("WantAddTeam");
			break;
		case RequsetInfo::ACTION_BIWU:
			text += m_request->name + ": " + NDCommonCString("WantRefrase");
			break;
		case RequsetInfo::ACTION_BAISHI:
			text += m_request->name + ": " + NDCommonCString("WantMaster");
			break;
		case RequsetInfo::ACTION_SOUTU:
			text += m_request->name + ": " + NDCommonCString("WantTutor");
			break;
		case RequsetInfo::ACTION_SYNDICATE:
			text += m_request->name + ": " + NDCommonCString("WantJoinJunTuan");
			break;
		case RequsetInfo::ACTION_NEWMAIL:
			text += m_request->name;
			break;
		case RequsetInfo::ACTION_NEWCHAT:
			text += m_request->name;
			break;
		default:
			break;
	}
	
	text += strTime.getData();
	
	if (m_lbValue)
	{
		m_lbValue->SetText(text.c_str());
		
		if (m_lbKey)
			keyWidth += m_lbKey->GetFrameRect().origin.x;
			
		CGRect rect = m_lbValue->GetFrameRect();
		
		rect.origin.x = keyWidth;
		
		m_lbValue->SetFrameRect(rect);
	}
	
	SAFE_DELETE(m_picQuestType);
	
	m_picQuestType = GetPicture(m_request->iAction);
}

RequsetInfo* NDRequestCell::GetRequest()
{
	return m_request;
}

void NDRequestCell::draw()
{
	if (!this->IsVisibled()) return;
	
	if (!m_request || !m_request->isValid()) return;
	
	CGRect scrRect = this->GetScreenRect();
	
	if (m_picBg)
		m_picBg->DrawInRect(scrRect);
		
	if (m_picQuestType)
		m_picQuestType->DrawInRect(CGRectMake(scrRect.origin.x+10, scrRect.origin.y+1, 26, 26));
		
	if (m_request->iAction == RequsetInfo::ACTION_NEWMAIL
		|| m_request->iAction == RequsetInfo::ACTION_NEWCHAT)
		return;
		
	if (m_picOk)
		m_picOk->DrawInRect(CGRectMake(scrRect.origin.x+364, scrRect.origin.y+3, 23, 23));
	
	if (m_picCancel)
		m_picCancel->DrawInRect(CGRectMake(scrRect.origin.x+404, scrRect.origin.y+3, 23, 23));
}

CGRect NDRequestCell::GetOkScreenRect()
{
	CGRect rect = this->GetScreenRect();
	
	rect.origin.x += 360;
	rect.size.width = 31;
	
	return rect;
}

CGRect NDRequestCell::GetCancelScreenRect()
{
	CGRect rect = this->GetScreenRect();
	
	rect.origin.x += 400;
	rect.size.width = 31;
	
	return rect;
}

NDPicture* NDRequestCell::GetPicture(int iRequestType)
{
	if (iRequestType < RequsetInfo::ACTION_BEGIN || iRequestType >= RequsetInfo::ACTION_END)
		return NULL;
		
	const char *filename[RequsetInfo::ACTION_END] = 
	{
		"request_friend.png",
		"request_team.png",
		"request_biwu.png",
		"request_baishi.png",
		"request_soutu.png",
		"request_syndicate.png",
		"request_mail.png",
		"request_chat.png",
	};
	
	return NDPicturePool::DefaultPool()->AddPicture(GetImgPathNew(filename[iRequestType]));
}

void NDRequestCell::reset()
{
	SAFE_DELETE(m_picQuestType);
}

IMPLEMENT_CLASS(NewGameUIRequest, NDUILayer)

void NewGameUIRequest::refreshQuestList()
{
	if (s_instance)
		s_instance->refresh();
}

NewGameUIRequest* NewGameUIRequest::s_instance = NULL;

NewGameUIRequest::NewGameUIRequest()
{
	m_tlMain = NULL;
	
	s_instance = this;
}

NewGameUIRequest::~NewGameUIRequest()
{
	s_instance = NULL;
}

void NewGameUIRequest::Initialization()
{
	NDUILayer::Initialization();
	
	CGSize winsize = NDDirector::DefaultDirector()->GetWinSize();
	
	m_tlMain = new NDUITableLayer;
	m_tlMain->Initialization();
	m_tlMain->SetBackgroundColor(ccc4(0, 0, 0, 0));
	m_tlMain->VisibleSectionTitles(false);
	m_tlMain->SetFrameRect(CGRectMake(9, 21, 436, 243));
	m_tlMain->VisibleScrollBar(false);
	m_tlMain->SetCellsInterval(2);
	m_tlMain->SetCellsRightDistance(0);
	m_tlMain->SetCellsLeftDistance(0);
	m_tlMain->SetDelegate(this);
	
	NDDataSource *dataSource = new NDDataSource;
	NDSection *section = new NDSection;
	section->UseCellHeight(true);
	
	dataSource->AddSection(section);
	m_tlMain->SetDataSource(dataSource);
	this->AddChild(m_tlMain);
	
	refresh();
}

void NewGameUIRequest::OnTableLayerCellFocused(NDUITableLayer* table, NDUINode* cell, unsigned int cellIndex, NDSection* section)
{
	
}

void NewGameUIRequest::OnTableLayerCellSelected(NDUITableLayer* table, NDUINode* cell, unsigned int cellIndex, NDSection* section)
{
	if (table != m_tlMain) return;
	
	if (!cell->IsKindOfClass(RUNTIME_CLASS(NDRequestCell))) return;
	
	NDRequestCell* requestCell = ((NDRequestCell*)cell);
	
	RequsetInfo* data = requestCell->GetRequest();
	
	if (!data || !data->isValid()) return;
	
	if (data->iAction == RequsetInfo::ACTION_NEWMAIL)
	{
		NDMapMgrObj.DelRequest(data->iID);
		NDDirector::DefaultDirector()->PopScene();
		SocialScene *scene = SocialScene::Scene();
		NDDirector::DefaultDirector()->PushScene(scene);
		scene->SetTabFocusOnIndex(0);
		RequestTutorAndFriendInfo();
		return;
	}
	else if(data->iAction == RequsetInfo::ACTION_NEWCHAT)
	{
		NDMapMgrObj.DelRequest(data->iID);
		NDDirector::DefaultDirector()->PopScene();
		NewChatScene::DefaultManager()->Show();
		return;
	}
	
	
	if (CGRectContainsPoint(requestCell->GetOkScreenRect(), table->m_beginTouch))
	{ // ok
		DealRequest(*data, 0);
	}
	else if (CGRectContainsPoint(requestCell->GetCancelScreenRect(), table->m_beginTouch))
	{ // cancle
		DealRequest(*data, 1);
	}
}
/*
void sendAcceptFriend(string name, int idObj) {
	NDMapMgr& mgr = NDMapMgrObj;
	if (mgr.isFriendMax()) {
		GlobalShowDlg("好友上线限制", "您的好友数量已达到上限，无法再添加好友。");
	} else {
		if (mgr.isFriendAdded(name)) {
			GlobalShowDlg("添加失败", "该玩家已经是你的好友，无需继续结交。");
		} else {
			NDTransData bao(_MSG_GOODFRIEND);
			bao << (Byte)_FRIEND_ACCEPT
			<< (Byte)1
			<< idObj;
			SEND_DATA(bao);
		}
	}
}

void sendRefuseFriend(int idObj) {
	NDTransData bao(_MSG_GOODFRIEND);
	bao << (Byte)_FRIEND_REFUSE
	<< (Byte)1
	<< idObj;
	SEND_DATA(bao);
}
*/
void NewGameUIRequest::DealRequest(RequsetInfo& request, int operate ) // 0 同意, 1 拒绝, 2清除
{
	if (operate < 0 || operate > 2) return;
					
	if ( operate == 0 ) // 同意
	{
		//NDLog(@"%d,%d", request.getMAction(), RequsetInfo::ACTION_TEAM);
		int action = request.getMAction();
		switch (action) {
			case RequsetInfo::ACTION_FRIEND: {
				sendAcceptFriend(request.name, request.iRoleID);
				break;
			}
			case RequsetInfo::ACTION_TEAM: {
				checkTeamAndSend(request.iRoleID, MSG_TEAM_INVITEOK);
				break;
			}
			case RequsetInfo::ACTION_BIWU: {
				sendRehearseAction(request.iRoleID, REHEARSE_ACCEPT); // 同意比武
				break;
			}
			case RequsetInfo::ACTION_BAISHI: {
				NDTransData bao(_MSG_TUTOR);
				bao << (unsigned char)2 << int(request.iRoleID);
				SEND_DATA(bao);
				break;
			}
			case RequsetInfo::ACTION_SOUTU: {
				NDTransData bao(_MSG_TUTOR);
				bao << (unsigned char)5 << int(request.iRoleID);
				SEND_DATA(bao);
				break;
			}
			case RequsetInfo::ACTION_SYNDICATE: {
				sendInviteResult(INVITE_ACCEPT, request.iRoleID);
				break;
			}
		}
	}
	else if ( operate == 1 )// 拒绝
	{
		//			if (Task::BEGIN_FRESHMAN_TASK && request.iRoleID == -1) {
		//				Chat::DefaultChat()->AddMessage(ChatTypeSystem, "任务进行中，不允许进行该操作！");
		//				return;
		//			}
		
		switch (request.getMAction()) {
			case RequsetInfo::ACTION_FRIEND: {
				sendRefuseFriend(request.iRoleID);
				break;
			}
			case RequsetInfo::ACTION_TEAM: {
				checkTeamAndSend(request.iRoleID, MSG_TEAM_INVITEFAILE);
				break;
			}
			case RequsetInfo::ACTION_BIWU: { // 拒绝不反应
				//PlayerListScreen.sendRehearseAction(request.getMId(), BattleListener.REHEARSE_REFUSE); // 拒绝比武
				break;
			}
			case RequsetInfo::ACTION_BAISHI: {
				NDTransData bao(_MSG_TUTOR);
				bao << (unsigned char)3 << int(request.iRoleID);
				SEND_DATA(bao);
				break;
			}
			case RequsetInfo::ACTION_SOUTU: {
				NDTransData bao(_MSG_TUTOR);
				bao << (unsigned char)6 << int(request.iRoleID);
				SEND_DATA(bao);
				break;
			}
			case RequsetInfo::ACTION_SYNDICATE: {
				sendInviteResult(INVITE_REFUSE, request.iRoleID);
				break;
			}
		}
	}
	else if ( operate == 2 ) // 删除
	{
		//			if (Task::BEGIN_FRESHMAN_TASK && request.iRoleID == -1) {
		//				Chat::DefaultChat()->AddMessage(ChatTypeSystem, "任务进行中，不允许进行该操作！");
		//				return;
		//			}
	}		
		
		
	NDMapMgrObj.DelRequest(request.iID);
	refresh();
}

void NewGameUIRequest::refresh()
{
	if (!m_tlMain
		|| !m_tlMain->GetDataSource()
		|| m_tlMain->GetDataSource()->Count() != 1)
		return;
		
	NDSection *section = m_tlMain->GetDataSource()->Section(0);
	
	std::vector<RequsetInfo>& requestlist = NDMapMgrObj.GetRequestList();
	
	size_t maxCount = section->Count() > requestlist.size() ? section->Count() : requestlist.size();
	
	unsigned int infoCount = 0;
	
	for (size_t i = 0; i < maxCount; i++) 
	{
		RequsetInfo *data = i < requestlist.size() ? &(requestlist[i]) : NULL;
		
		if (data != NULL)
		{
			NDRequestCell *cell = NULL;
			if (infoCount < section->Count())
				cell = (NDRequestCell *)section->Cell(infoCount);
			else
			{
				cell = new NDRequestCell;
				cell->Initialization();
				section->AddCell(cell);
			}
			cell->Change(data);
			
			infoCount++;
		}
		else
		{
			if (infoCount < section->Count() && section->Count() > 0)
			{
				section->RemoveCell(section->Count()-1);
			}
		}
	}
	
	m_tlMain->ReflashData();
}

bool NewGameUIRequest::checkTeamAndSend(int senderID, int action)
{
	if (senderID == -1) {
		Task* task = NDPlayer::defaultHero().GetPlayerTask(Task::TASK_TEAM);
		if (task) {
			//Chat::DefaultChat()->AddMessage(ChatTypeSystem, "您加入了NPC的队伍");
			sendTaskFinishMsg(Task::TASK_TEAM);
		}
		return false;
	}
	NDManualRole *role = NDMapMgrObj.GetManualRole(senderID);
	
	if (!role) 
	{
		showDialog(NDCommonCString("OperateFail"), NDCommonCString("RequestInvalid"));
		return false;
	}
	
	sendTeamAction(senderID, action);
	
	return true;
}

void NewGameUIRequest::clearRequest()
{
	std::vector<RequsetInfo>& requestlist = NDMapMgrObj.GetRequestList();
	
	requestlist.clear();
	
	refresh();
}
