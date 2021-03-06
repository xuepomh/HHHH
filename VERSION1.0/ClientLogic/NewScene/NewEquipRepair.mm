/*
 *  NewEquipRepair.mm
 *  DragonDrive
 *
 *  Created by jhzheng on 11-9-27.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include "NewEquipRepair.h"
#include "NDDirector.h"
#include "ItemMgr.h"
#include "NDUtility.h"
#include "NDPlayer.h"
#include "ItemMgr.h"
#include "NDUISynLayer.h"
#include "NewGamePlayerBag.h"
#include "ItemImage.h"
//#include "CGPointExtension.h"
#include <sstream>

#define TRADE_LABEL_COLOR (ccc4(255, 255, 255, 255))

IMPLEMENT_CLASS(NewEquipRepairLayer, NDUILayer)

NewEquipRepairLayer* NewEquipRepairLayer::s_instance = NULL;

void NewEquipRepairLayer::refreshAmount()
{
	if (s_instance) 
	{
		s_instance->refresh();
	}
}

void NewEquipRepairLayer::refresh()
{
	m_curItem = NULL;
	
	m_uiCurPage = -1; 
	
	ShowHammerAni(false);
	
	dealRepairAll();
}

NewEquipRepairLayer::NewEquipRepairLayer()
{
	m_itembagPlayer = NULL;
	
	m_layerEquip = NULL;
	
	memset(m_cellinfoEquip, 0, sizeof(m_cellinfoEquip));
	
	m_curItem = NULL;
	
	m_hammer = NULL;
	
	s_instance = this;
	
	m_uiCurPage = -1;
}

NewEquipRepairLayer::~NewEquipRepairLayer()
{
	s_instance = NULL;
}

void NewEquipRepairLayer::Initialization()
{
	NDUILayer::Initialization();
	
	CGSize winSize = NDDirector::DefaultDirector()->GetWinSize();
	
	std::vector<Item*>& itemlist = ItemMgrObj.GetPlayerBagItems();
	m_itembagPlayer = new NewGameItemBag;
	m_itembagPlayer->Initialization(itemlist, true, false);
	m_itembagPlayer->SetDelegate(this);
	m_itembagPlayer->SetPageCount(ItemMgrObj.GetPlayerBagNum());
	m_itembagPlayer->SetFrameRect(CGRectMake(203, 5, NEW_ITEM_BAG_W, NEW_ITEM_BAG_H));
	this->AddChild(m_itembagPlayer);
	
	NDPicturePool& pool = *(NDPicturePool::DefaultPool());
	
	NDPicture* picBagLeftBg = pool.AddPicture(GetImgPathNew("bag_left_bg.png"));
	
	CGSize sizeBagLeftBg = picBagLeftBg->GetSize();
	
	m_layerEquip = new NDUILayer;
	m_layerEquip->Initialization();
	m_layerEquip->SetFrameRect(CGRectMake(0,12, sizeBagLeftBg.width, sizeBagLeftBg.height));
	m_layerEquip->SetBackgroundImage(picBagLeftBg, true);
	//m_layerEquip->SetBackgroundColor(ccc4(25, 255, 255, 0));
	this->AddChild(m_layerEquip);
	
	NDPicture* picRoleBg = pool.AddPicture(GetImgPathNew("role_bg.png"));
	NDUIImage *imgRoleBg = new NDUIImage;
	imgRoleBg->Initialization();
	imgRoleBg->SetFrameRect(CGRectMake(49, 57, picRoleBg->GetSize().width, picRoleBg->GetSize().height));
	imgRoleBg->SetPicture(picRoleBg, true);
	m_layerEquip->AddChild(imgRoleBg);
	
	UpdateEquipList();
	
	m_hammer = new NDUISpriteNode;
	m_hammer->Initialization(GetAniPath("repair.spr"));
	m_layerEquip->AddChild(m_hammer);
	
	CGRect rectall = CGRectMake(49+(picRoleBg->GetSize().width-46)/2, 57+(picRoleBg->GetSize().height-46)/2, 46, 46);
	m_btnAll = new NDUIButton;
	m_btnAll->Initialization();
	m_btnAll->SetImage(pool.AddPicture(GetImgPathNew("repair_all.png")), false, CGRectZero, true);
	m_btnAll->SetFrameRect(rectall);
	m_btnAll->SetDelegate(this);
	//m_btnAll->SetTouchDownColor(ccc4(0, 0, 0, 0));
	m_layerEquip->AddChild(m_btnAll);
	
	m_hammerAll = new NDUISpriteNode;
	m_hammerAll->Initialization(GetAniPath("repair.spr"));
	m_hammerAll->SetSpritePosition(ccpAdd(rectall.origin, ccp(40.0f, 46.0f+32.0f)));
	m_layerEquip->AddChild(m_hammerAll);
	
	ShowHammerAni(false);
	
	dealRepairAll();
}

void NewEquipRepairLayer::UpdateEquipList()
{
	for (int i = Item::eEP_Begin; i < Item::eEP_End; i++)
	{
		InitEquipItemList(i, ItemMgrObj.GetEquipItemByPos(Item::eEquip_Pos(i)));
	}
}

void NewEquipRepairLayer::InitEquipItemList(int iEquipPos, Item* item)
{
	if (iEquipPos < Item::eEP_Begin || iEquipPos >= Item::eEP_End)
	{
		NDLog(@"玩家背包,装备列表初始化失败,装备位[%d]!!!", iEquipPos);
		return;
	}
	
	if (!m_cellinfoEquip[iEquipPos])
	{
		int iCellX = 5, iCellY = 13 , iXInterval = 4, iYInterval = 4;
		
		if(iEquipPos >= 0 && iEquipPos <= 3)
		{
			iCellX += (ITEM_CELL_W+iXInterval)*iEquipPos;
		}
		
		if(iEquipPos == 4 )
		{
			iCellY += (ITEM_CELL_H+iYInterval)*1;
		}
		
		if(iEquipPos == 5 )
		{
			iCellX += (ITEM_CELL_W+iXInterval)*3;
			iCellY += (ITEM_CELL_H+iYInterval)*1;
		}
		
		if(iEquipPos == 6 )
		{
			iCellY += (ITEM_CELL_H+iYInterval)*2;
		}
		
		if(iEquipPos == 7 )
		{
			iCellX += (ITEM_CELL_W+iXInterval)*3;
			iCellY += (ITEM_CELL_H+iYInterval)*2;
		}
		
		if (iEquipPos >= 8 && iEquipPos <= 15) 
		{
			iCellY += (ITEM_CELL_H+iYInterval)*3;
			
			iCellX += (ITEM_CELL_W+iXInterval)*((iEquipPos-8)%4);
			iCellY += (ITEM_CELL_H+iYInterval)*((iEquipPos-8)/4);
		}
		
		NDPicture *picDefaultItem = ItemImage::GetItem(NewPlayerBagLayer::GetIconIndexByEquipPos(iEquipPos), true);
		if (picDefaultItem)
		{
			picDefaultItem->SetColor(ccc4(215, 171, 108, 150));
			picDefaultItem->SetGrayState(true);
		}
		
		m_cellinfoEquip[iEquipPos] = new NDUIItemButton;
		m_cellinfoEquip[iEquipPos]->Initialization();
		m_cellinfoEquip[iEquipPos]->SetFrameRect(CGRectMake( iCellX+1, iCellY+1,ITEM_CELL_W-2, ITEM_CELL_H-2));
		m_cellinfoEquip[iEquipPos]->SetDelegate(this);
		m_cellinfoEquip[iEquipPos]->SetDefaultItemPicture(picDefaultItem);
		m_layerEquip->AddChild(m_cellinfoEquip[iEquipPos]);
	}
	
	m_cellinfoEquip[iEquipPos]->ChangeItem(item);
	
	m_cellinfoEquip[iEquipPos]->setBackDack(false);
	
	if (item) 
	{
		//roleequipok
		if (item->iAmount == 0) 
		{
			ItemMgrObj.SetRoleEuiptItemsOK(true, iEquipPos);
			m_cellinfoEquip[iEquipPos]->setBackDack(true);
			//T.roleEuiptItemsOK[i] = 1;
		}
		if (iEquipPos == Item::eEP_Ride) 
		{
			if (item->sAge == 0) 
			{
				//T.roleEuiptItemsOK[i] = 1;
				ItemMgrObj.SetRoleEuiptItemsOK(true, iEquipPos);
				m_cellinfoEquip[iEquipPos]->setBackDack(true);
			}
		}
	}
}

void NewEquipRepairLayer::ShowHammerAni(bool show, CGRect rect/*=CGRectZero*/)
{
	if (!m_hammer) return;
	
	m_hammer->Show(show);
	
	if (show)
		m_hammer->SetSpritePosition(ccpAdd(rect.origin, ccp(32.0f, 32.0f)));
}

void NewEquipRepairLayer::ShowHammerAllAni(bool show)
{
	if (!m_hammerAll) return;
	
	m_hammerAll->Show(show);
}

void NewEquipRepairLayer::dealRepairAll()
{
	if (!m_hammerAll) return;
	
	ShowHammerAllAni(getEquipRepairCharge(NULL, 1) != 0);
}

void NewEquipRepairLayer::OnButtonClick(NDUIButton* button)
{
	if (button == m_btnAll) 
	{
		repairAllItem();
		return;
	}
	
	NDUIItemButton *btn = NULL;
	for (int i = Item::eEP_Begin; i < Item::eEP_End; i++) 
	{
		if (m_cellinfoEquip[i] == button ) 
		{
			btn = m_cellinfoEquip[i];
			break;
		}
	}
	
	if (!btn) return;
	
	Item *item = btn->GetItem();
	
	if (!item || !item->IsNeedRepair()) 
	{
		return;
	}
	
	if (item != m_curItem)
	{
		m_curItem = item;
		m_uiCurPage = -1;
		ShowHammerAni(true, btn->GetScreenRect());
		return;
	}
	
	repairItem(item);
}

bool NewEquipRepairLayer::OnButtonLongClick(NDUIButton* button)
{
	if (button->IsKindOfClass(RUNTIME_CLASS(NDUIItemButton))) 
	{
		NDUIItemButton *btn = (NDUIItemButton*)button;
		
		Item *item = btn->GetItem();
		
		if (item) 
		{
			if (item->isFormula() || item->isItemPet() || item->isSkillBook())
			{
				sendQueryDesc(item->iID);
			} 
			else
			{
				NDUIDialog *dlg = new NDUIDialog;
				dlg->Initialization();
				std::string strtmp = item->makeItemDes(false, true);
				dlg->Show(item->getItemNameWithAdd().c_str(), strtmp.c_str(), NULL, NULL);
			}	
			
			return true;
		}
	}
	
	return false;
}

bool NewEquipRepairLayer::OnClickCell(NewGameItemBag* itembag, int iPage, int iCellIndex, Item* item, bool bFocused)
{
	if (!item || !item->IsNeedRepair()) 
	{
		return false;
	}
	
	if (m_curItem != item) 
	{
		NDUIItemButton* btn = itembag->GetItemBtnByItem(item);
		if (btn) {
			ShowHammerAni(true, btn->GetScreenRect());
		}
		
		m_curItem = item;
		
		m_uiCurPage = iPage;
		
		return true;
	}
	
	repairItem(item);
	
	return true;
}

void NewEquipRepairLayer::OnClickPage(NewGameItemBag* itembag, int iPage)
{
	if (m_curItem && m_uiCurPage != (unsigned int)-1) 
	{
		if (int(m_uiCurPage) != iPage) 
		{
			ShowHammerAni(false);
		}
		else 
		{
			NDUIItemButton* btn = itembag->GetItemBtnByItem(m_curItem);
			if (btn) 
				ShowHammerAni(true, btn->GetScreenRect());
		}
	}
}

void NewEquipRepairLayer::OnDialogButtonClick(NDUIDialog* dialog, unsigned int buttonIndex)
{
	sendItemRepair(0, Item::_ITEMACT_REPAIR_ALL);
	dialog->Close();
	return;
}

void NewEquipRepairLayer::repairItem(Item* item)
{
	if (!item)
	{
		return;
	}
	
	if (item->isRidePet())
	{
		showDialog(NDCommonCString("WenXinTip"), NDCommonCString("QiChongCantRepaire"));
	} else {
		int sumRepair = getEquipRepairCharge(item, 0);
		if (sumRepair == 0) {
			showDialog(NDCommonCString("WenXinTip"), NDCommonCString("EquipNoNeedRepair"));
		} else {
			if (sumRepair > NDPlayer::defaultHero().money) {
				stringstream ss; ss << NDCommonCString("RepairEquipFee") << sumRepair << "," << NDCommonCString("CantRepairEquipMoney");
				showDialog(NDCommonCString("WenXinTip"), ss.str().c_str());
			} else {
				sendItemRepair(item->iID, Item::_ITEMACT_REPAIR);
			}
		}
	}
}

void NewEquipRepairLayer::repairAllItem()
{
	int sumRepair = getEquipRepairCharge(NULL, 1);
	
	if (sumRepair == 0) {
		showDialog(NDCommonCString("WenXinTip"), NDCommonCString("AllEquipNoNeedRepair"));
	} else {
		if (sumRepair > NDPlayer::defaultHero().money) {
			stringstream ss; ss << NDCommonCString("AllEquipRepairFee") << sumRepair << NDCommonCString("CantRepairAllEquipMoney");
			showDialog(NDCommonCString("WenXinTip"), ss.str().c_str());
		} else {
			stringstream ss; ss << NDCommonCString("RepairAllEquipMoney") << " " << sumRepair << " " << NDCommonCString("RepairAllEquipMoneyTip") << "？";
			NDUIDialog *dlg = new NDUIDialog;
			dlg->Initialization();
			dlg->SetDelegate(this);
			dlg->Show(NDCommonCString("WenXinTip"), ss.str().c_str(), NDCommonCString("Cancel"), NDCommonCString("Ok"), NULL);
		}
	}
}

int NewEquipRepairLayer::getEquipRepairCharge(Item* item, int type)
{
	switch (type) {
		case 0: {
			
			if (!item ) {
				return 0;
			}
			
			int equipAllAmount = item->getAmount_limit();
			int equipPrice = item->getPrice();
			if ((item->iAmount < equipAllAmount) && (equipAllAmount > 1)) {
				return repairEveryMoney(equipPrice, item->iAmount,
										equipAllAmount);
			}
			return 0;
		}
		case 1: {
			int sumRepair = 0;
			for (int i = Item::eEP_Begin; i < Item::eEP_End; i++)
			{
				if (!m_cellinfoEquip[i] || !m_cellinfoEquip[i]->GetItem())
				{
					continue;
				}
				
				Item *tempItem = m_cellinfoEquip[i]->GetItem();
				if (tempItem && tempItem->isEquip() && !tempItem->isRidePet() && i != Item::eEP_Ride) {// 装备
					int equipAllAmount = tempItem->getAmount_limit();
					int equipPrice = tempItem->getPrice();
					
					if ((tempItem->iAmount < equipAllAmount)
						&& (equipAllAmount > 1)) {
						sumRepair += repairEveryMoney(equipPrice,
													  tempItem->iAmount, equipAllAmount);
					}
				}
			}
			
			return sumRepair;
		}
	}
	return 0;
}

int NewEquipRepairLayer::repairEveryMoney(int equipPrice, int dwAmount,int equipAllAmount)
{
	double repairMoney = double(equipPrice
								* ((double)3333333333.0 - (double)dwAmount * (double)10000000000.0 / (equipAllAmount * 3))
								/ (double)10000000000.0);
	return (int) (repairMoney) + 1; // 取整+1
}

#pragma mark 新交易场景

enum 
{
	eListBegin = 0,
	eListRepair = eListBegin,
	eListEnd,
};

IMPLEMENT_CLASS(NewEquipRepairScene, NDCommonScene)

NewEquipRepairScene* NewEquipRepairScene::Scene()
{
	NewEquipRepairScene *scene = new NewEquipRepairScene;
	
	scene->Initialization();
	
	return scene;
}

NewEquipRepairScene::NewEquipRepairScene()
{
	m_tabNodeSize.width = 150;
	
	m_layerRepair = NULL;
}

NewEquipRepairScene::~NewEquipRepairScene()
{
}

void NewEquipRepairScene::Initialization()
{
	NDCommonScene::Initialization();
	
	SAFE_DELETE_NODE(m_btnNext);
	
	NDPicturePool& pool = *(NDPicturePool::DefaultPool());
	
	const char * tabtext[eListEnd] = 
	{
		NDCommonCString("EquipWieXiu"),
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
		
		if (i == eListRepair) 
		{
			this->InitRepair(client);
		}
	}
	
	//this->SetTabFocusOnIndex(eListRepair, true);
}

void NewEquipRepairScene::InitRepair(NDUIClientLayer* client)
{
	if (!client) return;
	
	m_layerRepair = new NewEquipRepairLayer;
	m_layerRepair->Initialization();
	m_layerRepair->SetFrameRect(CGRectMake(0, 0, client->GetFrameRect().size.width, client->GetFrameRect().size.height));
	client->AddChild(m_layerRepair);
}

void NewEquipRepairScene::OnButtonClick(NDUIButton* button)
{
	OnBaseButtonClick(button);
}