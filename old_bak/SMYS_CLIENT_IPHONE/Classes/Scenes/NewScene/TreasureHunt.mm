/*
 *  TreasureHunt.mm
 *  DragonDrive
 *
 *  Created by jhzheng on 11-10-25.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include "TreasureHunt.h"
#include "NDDirector.h"
#include "ItemMgr.h"
#include "NDTransData.h"
#include "NDMsgDefine.h"
#include "NDDataTransThread.h"
#include "NDUISynLayer.h"
#include "ItemImage.h"
#include "UserStateUILayer.h"
#include <sstream>

#pragma mark 寻宝界面

IMPLEMENT_CLASS(TreasureHuntLayer, NDUILayer)


TreasureHuntLayer::TreasureHuntLayer()
{
	m_bag = NULL;
	
	m_lbHuntLost = m_lbEquipAdd = m_lbDuration = NULL;
	
	m_imageMouse = NULL;
	//m_layerBG = NULL;
}

TreasureHuntLayer::~TreasureHuntLayer()
{
	for (std::map<int, NDPicture*>::iterator it = m_recylePictures.begin(); it != m_recylePictures.end(); it++) 
	{
		delete it->second;
	}
	
	m_recylePictures.clear();
}

void TreasureHuntLayer::Initialization()
{
	NDUILayer::Initialization();
	
	CGSize winsize = NDDirector::DefaultDirector()->GetWinSize();
	
//	m_layerBG = new NDUILayer;
//	m_layerBG->Initialization();
//	m_layerBG->SetFrameRect(CGRectMake(0, 0, winsize.width, winsize.height));
//	this->AddChild(m_layerBG);
	
	InitHuntItem();
	
	std::vector<Item*> itemlist;
	FilterHuntItem(ItemMgrObj.GetPlayerBagItems(), itemlist);
	m_bag = new NewGameItemBag;
	m_bag->Initialization(itemlist, true, false);
	m_bag->SetDelegate(this);
	m_bag->SetPageCount(ItemMgrObj.GetPlayerBagNum());
	m_bag->SetFrameRect(CGRectMake(203, 5, NEW_ITEM_BAG_W, NEW_ITEM_BAG_H));
	this->AddChild(m_bag);
	
	NDUILabel *lb[3]; 
	
	memset(lb, 0, sizeof(lb));

	for (int i = 0; i < 3; i++) 
	{
		lb[i] = new NDUILabel;
		lb[i]->Initialization();
		lb[i]->SetFontSize(14);
		lb[i]->SetFontColor(ccc4(0, 0, 0, 255));
		lb[i]->SetTextAlignment(LabelTextAlignmentLeft);
		lb[i]->SetRenderTimes(3);
		lb[i]->SetFrameRect(CGRectMake(15, 30+i*(18), winsize.width, winsize.height));
		this->AddChild(lb[i]);
	}
	
	m_lbHuntLost = lb[0];
	m_lbEquipAdd = lb[1];
	m_lbDuration = lb[2];
	
	m_imageMouse = new NDUIImage;
	
	m_imageMouse->Initialization();
	
	m_imageMouse->EnableEvent(false);
	
	this->AddChild(m_imageMouse, 1);
}

bool TreasureHuntLayer::OnBagButtonDragIn(NDUIButton* desButton, NDUINode *uiSrcNode, bool longTouch, bool del)
{
	if (!uiSrcNode || !uiSrcNode->IsKindOfClass(RUNTIME_CLASS(NDUIItemButton))) return false;
	
	if (desButton->GetParent() != m_bag || !m_bag) return false;
	
	
	if (!IsHuntItem((NDUIButton*)uiSrcNode)) return false;
	
	NDUIItemButton *itemBtn = (NDUIItemButton*)uiSrcNode;
	Item* item = itemBtn->GetItem();
	if (!item) return false;
	
	HuntItemType hunt = GetHuntItemType(itemBtn);
	
	if (hunt == HuntItemTypeEnd) return false;
	
	if (!m_huntItemUI[hunt].IsEnable()) return false;
	
	m_bag->AddItem(item);
	
	refreshHuntItem(hunt, NULL);
	
	return true;
}

bool TreasureHuntLayer::OnButtonDragIn(NDUIButton* desButton, NDUINode *uiSrcNode, bool longTouch)
{
	if ( !(uiSrcNode && uiSrcNode->IsKindOfClass(RUNTIME_CLASS(NDUIItemButton)) 
		   && desButton != uiSrcNode && uiSrcNode->GetParent() == m_bag)
		)
	{
		return false;
	}
	
	if (!desButton || !desButton->IsKindOfClass(RUNTIME_CLASS(NDUIItemButton)))
		return false;
	
	if (!IsHuntItem(desButton)) return false;
	
	NDUIItemButton *itemBtn = (NDUIItemButton*)uiSrcNode;
	Item* srcItem = itemBtn->GetItem();
	if (!srcItem) return false;
	
	HuntItemType hunt = GetHuntItemType(itemBtn);
	
	if (hunt == HuntItemTypeEnd) return false;
	
	if (!m_huntItemUI[hunt].IsEnable()) return false;
	
	Item* descItem = m_huntItemUI[hunt].GetItem();
	
	refreshHuntItem(hunt, itemBtn);
	
	m_bag->DelItem(srcItem->iID);
	
	if (descItem)
		m_bag->AddItem(descItem);
		
	return true;
}

bool TreasureHuntLayer::OnButtonDragOut(NDUIButton* button, CGPoint beginTouch, CGPoint moveTouch, bool longTouch)
{
	if (!IsHuntItem(button)) return false;
	
	if (button->IsKindOfClass(RUNTIME_CLASS(NDUIItemButton))) 
	{
		Item* item = ((NDUIItemButton*)button)->GetItem();
		
		if (!item) 
			return false;
		
		std::map<int, NDPicture*>::iterator cache = m_recylePictures.find(item->iItemType);
		
		NDPicture* pic = NULL;
		
		if (cache != m_recylePictures.end() ) 
		{
			pic = cache->second;
		}
		else
		{
			pic = ItemImage::GetItemByIconIndex(item->getIconIndex(), ((NDUIItemButton*)button)->IsGray());
			
			if (!pic) return false;
			
			m_recylePictures.insert(std::pair<int, NDPicture*>(item->iItemType, pic));
		}
		
		if (pic && m_imageMouse) 
		{
			pic->SetGrayState(((NDUIItemButton*)button)->IsGray());
			
			m_imageMouse->SetPicture(pic);
			
			CGSize size = pic->GetSize();
			
			m_imageMouse->SetFrameRect(CGRectMake(moveTouch.x-size.width/2, moveTouch.y-size.height/2-37, pic->GetSize().width, pic->GetSize().height));
			
			return true;
		}
	}
	
	return false;
}

bool TreasureHuntLayer::OnButtonDragOutComplete(NDUIButton* button, CGPoint endTouch, bool outOfRange)
{
	if (!IsHuntItem(button)) return false;
	
	m_imageMouse->SetPicture(NULL);
	
	return true;
}

void TreasureHuntLayer::StartTreasureHunt()
{
	NDTransData bao(_MSG_TRY_BEGIN_TREASURE_HUNT);
	
	for (HuntItemType i = HuntItemTypeBegin; i < HuntItemTypeEnd; i=HuntItemType(i+1)) 
	{
		bao << m_huntItemUI[i].GetItemID();
	}
	
	ShowProgressBar;
	
	SEND_DATA(bao);
}

// huntLost-寻宝成功率 equipAdd-装备加成 duration-当前可寻宝时间
void TreasureHuntLayer::SetRateInfo(int huntLost, int equipAdd, int duration)
{
	if (huntLost < 0) huntLost = 0;
	else if (huntLost > 100) huntLost = 100;
	
	if (equipAdd < 0) equipAdd = 0;
	else if (huntLost > 100) equipAdd = 100;
	
	//duration = duration / 60;
	
	std::stringstream ss;
	
	ss << NDCommonCString("XunBaoSuccRate") << ":" << huntLost << "%";
	
	SetLabelText(m_lbHuntLost, ss.str().c_str()); ss.str("");
	
	ss << NDCommonCString("EquipJiaCheng") << ":" << equipAdd << "%";
	
	SetLabelText(m_lbEquipAdd, ss.str().c_str()); ss.str("");
	
	ss << NDCommonCString("CurActiveXunBao") << duration << NDCommonCString("FengZhong");
	
	SetLabelText(m_lbDuration, ss.str().c_str());
}

void TreasureHuntLayer::FilterHuntItem(const std::vector<Item*>& itemlist, std::vector<Item*>& outItemList)
{
	for_vec(itemlist, std::vector<Item*>::const_iterator)
	{
		int itemtype = (*it)->iItemType;
		
		if ( (itemtype >= 24000040 && itemtype <= 24000060) ||
			 (itemtype >= 24000061 && itemtype <= 24000080) ||
			 (itemtype >= 24000081 && itemtype <= 24000099)
			)
		{
			outItemList.push_back(*it);
		}
	}
}

void TreasureHuntLayer::InitHuntItem()
{
	CGSize winsize = NDDirector::DefaultDirector()->GetWinSize();
	
	const char* text[HuntItemTypeEnd] =
	{
		//"效率", "成功", "猎人",
		NDCommonCString("lucky"), NDCommonCString("expert"), NDCommonCString("QuLing"),
	};
	
	int textStartX = 15,
		itemStartX = textStartX + 34, itemStartY = 100, itemIntervalY = 10,
		tipStarX = itemStartX + NEW_ITEM_CELL_W + 5;
		
	
	for(HuntItemType i = HuntItemTypeBegin; i < HuntItemTypeEnd; i=HuntItemType(i+1))
	{
		NDUILabel				*&lbText = m_huntItemUI[i].lbText;
		NDUIItemButton			*&btn = m_huntItemUI[i].btn;
		NDUILabel				*&tip = m_huntItemUI[i].tip;
		
		int btnY = itemStartY+i*(NEW_ITEM_CELL_H+itemIntervalY);
		
		lbText = new NDUILabel;
		lbText->Initialization();
		lbText->SetFontSize(14);
		lbText->SetFontColor(ccc4(0, 0, 0, 255));
		lbText->SetTextAlignment(LabelTextAlignmentLeft);
		lbText->SetRenderTimes(3);
		lbText->SetText(text[i]);
		lbText->SetFrameRect(CGRectMake(textStartX, btnY+(NEW_ITEM_CELL_H-14)/2, winsize.width, winsize.height));
		this->AddChild(lbText); 
		
		btn = new NDUIItemButton;
		btn->Initialization();
		btn->SetFrameRect(CGRectMake(itemStartX, btnY, NEW_ITEM_CELL_W, NEW_ITEM_CELL_H));
		btn->SetDelegate(this);
		btn->ShowItemCount(false);
		this->AddChild(btn);
		
		tip = new NDUILabel;
		tip->Initialization();
		tip->SetFontSize(14);
		tip->SetFontColor(ccc4(0, 0, 0, 255));
		tip->SetTextAlignment(LabelTextAlignmentLeft);
		tip->SetRenderTimes(3);
		tip->SetFrameRect(CGRectMake(tipStarX, btnY+(NEW_ITEM_CELL_H-14)/2, 110, winsize.height));
		this->AddChild(tip); 
	}

	MAP_USER_STATE& map_state = UserStateUILayer::getAllUserState();
	
	for (MAP_USER_STATE_IT it = map_state.begin(); it != map_state.end(); it++) 
	{
		UserState* state = it->second;
		
		HuntItemType hunt = GetHuntItemTypeByStateID(state->idState);
		
		std::stringstream ss;
		
		switch (hunt) {
			case HuntItemTypeEffect:
				ss << NDCommonCString("XunBaoEffectRate") << state->nData << "%";
				break;
			case HuntItemTypeRate:
				ss << NDCommonCString("XunBaoLvl") << "+" << state->nData;
				break;
			case HuntItemTypeHunt:
				ss << NDCommonCString("GetLinQiAndCoin");
				break;
			default:
				break;
		}
		
		m_huntItemUI[hunt].SetEnable(false);
		
		if (m_huntItemUI[hunt].btn)
		{
			CGSize size = m_huntItemUI[hunt].btn->GetFrameRect().size;
			NDUILayer *layer = new NDUILayer;
			layer->Initialization();
			layer->SetFrameRect(CGRectMake(0, 0, size.width, size.height));
			layer->SetBackgroundColor(ccc4(125, 125, 125, 255));
			layer->SetTouchEnabled(false);
			m_huntItemUI[hunt].btn->AddChild(layer);
		}
		
		SetLabelText(m_huntItemUI[hunt].tip, ss.str().c_str());
	}
}

void TreasureHuntLayer::refreshHuntItem(HuntItemType hunt, NDUIButton *btn)
{
	if (hunt < HuntItemTypeBegin || hunt >= HuntItemTypeEnd ) return;
	
	if (!m_huntItemUI[hunt].IsEnable()) return;
	
	if (btn 
		&& (!btn->IsKindOfClass(RUNTIME_CLASS(NDUIItemButton)) 
			|| !((NDUIItemButton*)btn)->GetItem())
		) 
	{
		return;
	}
	
	if (m_huntItemUI[hunt].btn) 
	{
		m_huntItemUI[hunt].btn->ChangeItem(btn ? ((NDUIItemButton*)btn)->GetItem() : NULL);
	}
	
	NDItemType *itemtype = NULL;
	
	int iItemType = m_huntItemUI[hunt].GetItemType();
	
	if (iItemType != 0)
		itemtype = ItemMgrObj.QueryItemType(iItemType);
	
	refreshHuntTip(hunt, itemtype);
}

void TreasureHuntLayer::refreshHuntTip(HuntItemType hunt, NDItemType* itemtype)
{
	if (hunt < HuntItemTypeBegin || hunt >= HuntItemTypeEnd ) return;
	
	if (!m_huntItemUI[hunt].IsEnable()) return;
	
	NDUILabel *&lb = m_huntItemUI[hunt].tip;
	
	if (!lb) return;
	
	if (itemtype == NULL)
	{
		SetLabelText(lb, "");
		
		return;
	}
	
	std::stringstream ss;
	
	switch (hunt) {
		case HuntItemTypeEffect:
			ss << NDCommonCString("XunBaoEffectRate") << 0 << "%";
			break;
		case HuntItemTypeRate:
			ss << NDCommonCString("XunBaoLvl") << "+" << 0;
			break;
		case HuntItemTypeHunt:
			ss << NDCommonCString("GetLinQiAndCoin");
			break;
		default:
			break;
	}

	SetLabelText(lb, itemtype->m_des.c_str());
}

void TreasureHuntLayer::SetLabelText(NDUILabel*& lb, const char* text)
{
	if (!lb || !text) return;
	
	lb->SetText(text);
}

HuntItemType TreasureHuntLayer::GetHuntItemType(NDUIItemButton *btn)
{
	HuntItemType res = HuntItemTypeEnd;
	
	if (!btn) return res;
	
	Item* item = btn->GetItem();
	
	if (!item) return res;
	
	int itemtype = item->iItemType;
	
	if ( (itemtype >= 24000040) && (itemtype <= 24000060) )
	{
		res = HuntItemTypeEffect;
	}
	else if ( (itemtype >= 24000061 && itemtype <= 24000080) )
	{
		res = HuntItemTypeRate;
	}
	else if ( (itemtype >= 24000080 && itemtype <= 24000099) )
	{
		res = HuntItemTypeHunt;
	}
	
	/*
	bool find = false;
	
	for (HuntItemType i = HuntItemTypeBegin; i < HuntItemTypeEnd; i=HuntItemType(i+1)) 
	{
		if (btn == m_huntItemUI[i].btn && res == i)
		{
			find = true;
		}
	}
	
	if (!find) res = HuntItemTypeEnd; */
	
	return res;
}

HuntItemType TreasureHuntLayer::GetHuntItemTypeByStateID(int idState)
{
	HuntItemType res = HuntItemTypeEnd;
	
	if ( (idState >= 10162001) && (idState <= 10162999) )
	{
		res = HuntItemTypeEffect;
	}
	else if ( (idState >= 10163001 && idState <= 10163999) )
	{
		res = HuntItemTypeRate;
	}
	else if ( (idState >= 10164001 && idState <= 10164999) )
	{
		res = HuntItemTypeHunt;
	}
	
	return res;
}

bool TreasureHuntLayer::IsHuntItem(NDUIButton *btn)
{
	bool find = false;
	for (HuntItemType i = HuntItemTypeBegin; i < HuntItemTypeEnd; i=HuntItemType(i+1)) 
	{
		if (btn == m_huntItemUI[i].btn)
		{
			find = true;
		}
	}
	return find;
}

#pragma mark 寻宝场景

std::string TreasureHuntScene::s_HuntDesc;

void TreasureHuntScene::processHuntDesc(NDTransData& data)
{
	CloseProgressBar;
	
	s_HuntDesc = data.ReadUnicodeString();
	
	NDScene *scene = NDDirector::DefaultDirector()->GetRunningScene();
	
	if (!scene || !scene->IsKindOfClass(RUNTIME_CLASS(TreasureHuntScene)))
		return;
		
	((TreasureHuntScene*)scene)->refreshHuntDesc();
}

enum 
{
	eListBegin = 0,
	eTreasureHunt = eListBegin,
	eTreasureHuntDesc,
	eListEnd,
};

IMPLEMENT_CLASS(TreasureHuntScene, NDCommonScene)

TreasureHuntScene* TreasureHuntScene::Scene()
{
	TreasureHuntScene *scene = new TreasureHuntScene;
	
	scene->Initialization();
	
	return scene;
}

TreasureHuntScene::TreasureHuntScene()
{
	m_tabNodeSize.width = 150;
	m_layerTreasureHunt = NULL;
	m_btnTreasureHunt = NULL;
	m_contentScroll = NULL;
}

TreasureHuntScene::~TreasureHuntScene()
{
	s_HuntDesc = "";
}

void TreasureHuntScene::Initialization()
{
	NDCommonScene::Initialization();
	
	SAFE_DELETE_NODE(m_btnNext);
	
	NDPicturePool& pool = *(NDPicturePool::DefaultPool());
	
	NDPicture *pic = pool.AddPicture(GetImgPathNew("newui_btn.png"));
	
	NDPicture *picTreasureHunt = pool.AddPicture(GetImgPathBattleUI("treasure_hunt.png"));
	
	CGSize size = pic->GetSize();
	
	CGSize sizeTreasureHunt = picTreasureHunt->GetSize();
	
	m_btnTreasureHunt = new NDUIButton;
	
	m_btnTreasureHunt->Initialization();
	
	m_btnTreasureHunt->SetFrameRect(CGRectMake(7, 37-size.height, size.width, size.height));
	
	m_btnTreasureHunt->SetBackgroundPicture(pic, NULL, false, CGRectZero, true);
	
	m_btnTreasureHunt->SetImage(picTreasureHunt, true, CGRectMake((size.width-size.width)/2, (size.height-size.height)/2, size.width, size.height), true);
	
	m_btnTreasureHunt->SetDelegate(this);
	
	m_layerBackground->AddChild(m_btnTreasureHunt);
	
	const char * tabtext[eListEnd] = 
	{
		NDCommonCString("XunBao"),
		NDCommonCString("ShuoMing")
	};
	
	
	for (int i = eListBegin; i < eListEnd; i++) 
	{
		TabNode* tabnode = this->AddTabNode();
		
		tabnode->SetImage(pool.AddPicture(GetImgPathNew("newui_tab_unsel.png"), 150, 31), 
						  pool.AddPicture(GetImgPathNew("newui_tab_sel.png"), 150, 34),
						  pool.AddPicture(GetImgPathNew("newui_tab_selarrow.png")));
		
		tabnode->SetText(tabtext[i]);
		
		tabnode->SetTextColor(ccc4(245, 226, 169, 255));
		
		tabnode->SetFocusColor(ccc4(173, 70, 25, 255));
		
		tabnode->SetTextFontSize(18);
	}
	
	for (int i = eListBegin; i < eListEnd; i++) 
	{
		CGSize winsize = NDDirector::DefaultDirector()->GetWinSize();
		
		NDUIClientLayer* client = this->GetClientLayer(i);
		
		if (i == eTreasureHunt) 
		{
			this->InitTreasureHunt(client);
		}
		
		if (i == eTreasureHuntDesc) 
		{
			InitDesc(client);
		}
	}
	
	this->SetTabFocusOnIndex(eTreasureHunt, true);
}

void TreasureHuntScene::InitTreasureHunt(NDUIClientLayer* client)
{
	if (!client) return;
	
	CGSize sizeClient = client->GetFrameRect().size;

	m_layerTreasureHunt = new TreasureHuntLayer;
	
	m_layerTreasureHunt->Initialization();
	
	m_layerTreasureHunt->SetFrameRect(CGRectMake(0, 0, sizeClient.width, sizeClient.height));
	
	client->AddChild(m_layerTreasureHunt);
}

void TreasureHuntScene::InitDesc(NDUIClientLayer* client)
{
	if (!client) return;
	
	CGSize sizeClient = client->GetFrameRect().size;
	
	m_contentScroll = new NDUIContainerScrollLayer;
	m_contentScroll->Initialization();
	m_contentScroll->SetFrameRect(CGRectMake(20, 20, sizeClient.width-40, sizeClient.height-40));
	m_contentScroll->SetDelegate(this);
	client->AddChild(m_contentScroll);
}

void TreasureHuntScene::OnButtonClick(NDUIButton* button)
{
	if (button != m_btnTreasureHunt)
	{
		OnBaseButtonClick(button);
		return;
	}
	
	std::stringstream StartXunBao;
	StartXunBao << NDCommonCString("StartXunBaoTip") << "\n" << NDCommonCString("XunBaoOrNot");
	NDUIDialog *dlg = new NDUIDialog;
	dlg->Initialization();
	dlg->SetDelegate(this);
	dlg->Show(NDCommonCString("tip"), StartXunBao.str().c_str(), NULL, NDCommonCString("StartXunBao"), NULL);
}

void TreasureHuntScene::OnTabLayerSelect(TabLayer* tab, unsigned int lastIndex, unsigned int curIndex)
{
	NDCommonScene::OnTabLayerSelect(tab, lastIndex, curIndex);
	
	if (curIndex == eTreasureHuntDesc)
	{
		if (s_HuntDesc.empty())
		{
			ShowProgressBar;
			
			NDTransData bao(_MSG_QUERY_TREASURE_HUNT_INFO);
			
			SEND_DATA(bao);
			
			return;
		}
		
		refreshHuntDesc();
	}
}

bool TreasureHuntScene::OnLayerMove(NDUILayer* uiLayer, UILayerMove move, float distance)
{
	if (uiLayer == m_contentScroll)
		m_contentScroll->OnLayerMove(uiLayer, move, distance);
	
	return false;
}

void TreasureHuntScene::refreshHuntDesc()
{
	if (!m_contentScroll) return;
	
	m_contentScroll->RemoveAllChildren(true);
	
	if (s_HuntDesc.empty()) return;
	
	int width = m_contentScroll->GetFrameRect().size.width-4;
	
	uint uiTextHeight = NDUITextBuilder::DefaultBuilder()->StringHeightAfterFilter(s_HuntDesc.c_str(), width, 14);
	
	NDUIText * lbContent = NDUITextBuilder::DefaultBuilder()->Build(
														s_HuntDesc.c_str(), 
														14, 
														CGSizeMake(width, uiTextHeight), 
														ccc4(0, 0, 0, 255),
														false);
	
	lbContent->SetFrameRect(CGRectMake(2, 3, width, uiTextHeight));
	
	if (lbContent->GetParent() == NULL)
		m_contentScroll->AddChild(lbContent);
	
	m_contentScroll->refreshContainer();
	
	return;
}

void TreasureHuntScene::SetRateInfo(int huntLost, int equipAdd, int duration)
{
	if (m_layerTreasureHunt)
		m_layerTreasureHunt->SetRateInfo(huntLost, equipAdd, duration);
}

void TreasureHuntScene::OnDialogButtonClick(NDUIDialog* dialog, unsigned int buttonIndex)
{
	if (buttonIndex == 0) 
	{
		if (m_layerTreasureHunt)
			m_layerTreasureHunt->StartTreasureHunt();
		
		dialog->Close();
	}
}