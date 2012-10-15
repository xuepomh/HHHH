/*
 *  GameUIItemConfig.mm
 *  DragonDrive
 *
 *  Created by jhzheng on 11-8-4.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include "GameUIItemConfig.h"
#include "NDDirector.h"
#include "NDPlayer.h"
#include "ItemMgr.h"
#include "ItemImage.h"
#include "Battle.h"
#include "NDUIBaseGraphics.h"
#include "CGPointExtension.h"
#include "GameScene.h"

#define invalid_itemtype (-1)
#define max_speed_count (17)

#define item_row (4)

#define item_col (6)

#define item_width (42)

#define item_height (42)

#define item_interval_w (2)

#define item_interval_h (3)

#define item_startx ((480-(item_interval_w+item_width)*item_col)/2)

#define item_starty (5)


#define page_w (40)

#define page_h (40)

#define page_inter (4)

#define page_startx (480-page_w-10)

#define page_starty (item_starty)



#define speed_item_row (3)

#define speed_item_col (5)

#define speed_item_width (42)

#define speed_item_height (42)

#define speed_item_interval_w (14)

#define speed_item_interval_h (5)

#define speed_item_startx (23) //((480-(speed_item_interval_w+speed_item_width)*speed_item_col)/2)

#define speeditem_starty (55)//(item_starty*2+(item_interval_h+item_height)*item_row)

#define item_option_x (4)

#define item_option_y (3)

#define item_option_w (204)

#define item_option_h (33)

#pragma mark 战斗内物品配置

IMPLEMENT_CLASS(GameUIItemConfig, NDUILayer)

GameUIItemConfig::GameUIItemConfig()
{
	memset(m_btnPage, 0, sizeof(m_btnPage));
	
	m_btnClose = NULL;
	
	m_imageMouse = NULL;
	
	//m_layerSpeedBar = NULL;
	
	m_picOption = m_picOptionSel = NULL;
	
	memset(m_picSpeedNums, 0, sizeof(m_picSpeedNums));
}

GameUIItemConfig::~GameUIItemConfig()
{
	SaveSpeedBarData();
	
	for (std::map<int, Item*>::iterator it = m_recyleItems.begin(); it != m_recyleItems.end(); it++) 
	{
		delete it->second;
	}
	
	m_recyleItems.clear();
	
	for (std::map<int, NDPicture*>::iterator it = m_recylePictures.begin(); it != m_recylePictures.end(); it++) 
	{
		delete it->second;
	}
	
	m_recylePictures.clear();
	
	for (int i = 0; i < 3; i++) 
	{
		if (m_picSpeedNums[i])
			delete m_picSpeedNums[i];
	}
}

void GameUIItemConfig::Initialization()
{
	NDUILayer::Initialization();
	
	CGSize winsize = NDDirector::DefaultDirector()->GetWinSize();
	
	NDPicturePool& pool = *(NDPicturePool::DefaultPool());
	
	this->SetBackgroundImage(pool.AddPicture(GetImgPathBattleUI("item_settle_bg.png"), winsize.width, winsize.height), true);
	
	this->SetFrameRect(CGRectMake(0, 0, winsize.width, winsize.height));
	
	this->SetBackgroundColor(ccc4(0, 0, 0, 255));
	
	m_btnClose = new NDUIButton;
	
	m_btnClose->Initialization();
	
	NDUILabel *lbTitle = new NDUILabel;
	
	lbTitle->Initialization();
	
	lbTitle->SetTextAlignment(LabelTextAlignmentCenter);
	
	lbTitle->SetFontSize(18);
	
	lbTitle->SetFontColor(ccc4(251, 222, 63, 255));
	
	lbTitle->SetText(NDCommonCString("ItemSpeedBarSet"));
	
	lbTitle->SetFrameRect(CGRectMake(item_option_x, item_option_y, item_option_w, item_option_h));
	
	this->AddChild(lbTitle);
	
	//m_btnClose->SetTitle("关闭");
	NDPicture *picClose = pool.AddPicture(GetImgPathBattleUI("close_btn.png"));
	
	CGSize sizeClose = picClose->GetSize();
	
	m_btnClose->SetImage(picClose, false, CGRectZero, true);
	
	m_btnClose->SetDelegate(this);
	
	m_btnClose->SetFrameRect(CGRectMake(winsize.width-10-sizeClose.width, 2, sizeClose.width, sizeClose.height));
	
	this->AddChild(m_btnClose);
	
	m_imageMouse = new NDUIImage;
	
	m_imageMouse->Initialization();
	
	m_imageMouse->EnableEvent(false);
	
	this->AddChild(m_imageMouse, 1);
	
	//AddPageItemBtn();
	
	//AddPageBtn();
	
	AddSpeedBtn();
	
	//ShowPage();
	
	LoadSpeedBarData();
	
	
	VEC_ITEM battleItems;
	
	ItemMgrObj.GetBattleUsableItem(battleItems);
	
	//refreshButtons(battleItems);
	
	m_bag = new NewGameItemBag;
	
	m_bag->Initialization(battleItems,false, false);
	
	m_bag->SetFrameRect(CGRectMake(203, 42, NEW_ITEM_BAG_W, NEW_ITEM_BAG_H));
	
	m_bag->SetPageCount(ItemMgrObj.GetPlayerBagNum());
	
	this->AddChild(m_bag);
	
	refreshSpeedBar(battleItems);
	
	m_picOption = pool.AddPicture(GetImgPathBattleUI("bg_tab_panel.png"), item_option_w, item_option_h);
	
	m_picOptionSel = pool.AddPicture(GetImgPathBattleUI("tab_focused_tab.png"));
	
	for(int i = 0; i < speed_item_row; i++)
	{
		m_picSpeedNums[i] = pool.AddPicture(GetImgPathBattleUI("bag_number.png"));
		m_picSpeedNums[i]->Cut(getNewNumCut(i+1, false));
	}
}

void GameUIItemConfig::OnButtonClick(NDUIButton* button)
{
	if (button == m_btnClose) 
	{
		SaveSpeedBarData();
		
		GameUIItemConfigDelegate *delegate = dynamic_cast<GameUIItemConfigDelegate*> (this->GetDelegate());
		
		if (delegate)
			delegate->OnItemConfigFinish();
		
		this->RemoveFromParent(true);
	}
	else 
	{
	/*
		for (int i = 0; i < max_page; i++) 
		{
			if (button == m_btnPage[i]) 
			{
				m_curPage = i;
				
				ShowPage();
				
				break;
			}
		}
	*/
	}

}

bool GameUIItemConfig::OnButtonDragOut(NDUIButton* button, CGPoint beginTouch, CGPoint moveTouch, bool longTouch)
{
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
		
			m_imageMouse->SetFrameRect(CGRectMake(moveTouch.x-size.width/2, moveTouch.y-size.height/2, pic->GetSize().width, pic->GetSize().height));
			
			return true;
		}
	}
	
	return false;
}

bool GameUIItemConfig::OnButtonDragOutComplete(NDUIButton* button, CGPoint endTouch, bool outOfRange)
{
	m_imageMouse->SetPicture(NULL);
	
	for(size_t i = 0; i < m_vecSpeedBtn.size(); i++)
	{
		if (CGRectContainsPoint(m_vecSpeedBtn[i]->GetFrameRect(), endTouch))
			return false;
	}
	
	for(size_t i = 0; i < m_vecSpeedBtn.size(); i++)
	{
		if (button == m_vecSpeedBtn[i] && outOfRange) 
		{
			
			SetSpeedBar(i, NULL);
			
			return true;
		}
	}
	
	return false;
}

bool GameUIItemConfig::OnButtonDragIn(NDUIButton* desButton, NDUINode *uiSrcNode, bool longTouch)
{
	if (uiSrcNode && uiSrcNode->IsKindOfClass(RUNTIME_CLASS(NDUIItemButton)) && desButton != uiSrcNode) 
	{
		Item* item = ((NDUIItemButton*)uiSrcNode)->GetItem();
		
		if (!item) 
			return false;
			
		size_t find = size_t(-1);	
			
		for(size_t i = 0; i < m_vecSpeedBtn.size(); i++)
		{
			if (desButton == m_vecSpeedBtn[i]) 
			{
				find = i;
				
				break;
			}
		}
		
		size_t findSrc = size_t(-1);
		
		if (find != (unsigned int)-1) 
		{
			for(size_t i = 0; i < m_vecSpeedBtn.size(); i++)
			{
				if (uiSrcNode == m_vecSpeedBtn[i]) 
				{
					findSrc = i;
					
					break;
				}
			}
		}
		
		if (findSrc != (unsigned int)-1 && findSrc != find)
		{
			SwapSpeedBar(findSrc, find);
			
			return true;
		}
	
		if (find == (unsigned int)-1) return false;
		
		SetSpeedBar(find, item);
		
		return true;
	}
	
	return false;
}

void GameUIItemConfig::refreshButtons(std::vector<Item*>& vec_item)
{	
	/*
	for_vec(m_vecBtn, std::vector<NDUIItemButton*>::iterator)
	{
		(*it)->ChangeItem(NULL);
	}
	
	unsigned int maxButtonCount = (item_row * item_col) * max_page;
	
	size_t size = vec_item.size();
	
	for(size_t i = 0; i < size; i++)
	{
		if(i >= maxButtonCount) break;
		
		size_t curBtns = m_vecBtn.size();
		
		if (i >= curBtns) 
			AddPageItemBtn();
		
		if (i <  m_vecBtn.size()) 
			m_vecBtn[i]->ChangeItem(vec_item[i]);
	}
	
	if (size  < m_curPage * (item_row * item_col)) 
		m_curPage = 0;
	
	ShowPage();
	*/
}

void GameUIItemConfig::refreshSpeedBar(std::vector<Item*>& vec_item)
{
	std::map<int, Item*> itemtypes;
	
	for_vec(vec_item, std::vector<Item*>::iterator)
	{
		if (itemtypes.find((*it)->iItemType) == itemtypes.end()) 
			itemtypes.insert(std::pair<int, Item*>((*it)->iItemType, *it));
	}
	
	/*
	for(std::map<int, Item*>::iterator it = itemtypes.begin(); it != itemtypes.end(); it++)
		findSpeedBarEmptyPos(it->first, true);
	*/
	
	
	size_t size = m_vecSpeedBar.size();
	
	for(size_t i = 0; i < size; i++)
	{
		if (i >= m_vecSpeedBtn.size()) break;
		
		ItemBarCellInfo& info = m_vecSpeedBar[i];
		
		std::map<int, Item*>::iterator iter = itemtypes.find(info.idItemType);
		
		if (iter != itemtypes.end() ) 
		{
			m_vecSpeedBtn[i]->ChangeItem(iter->second, true);
			
			m_vecSpeedBtn[i]->EnalbeGray(false);
		}
		else
		{
			std::map<int, Item*>::iterator cache = m_recyleItems.find(info.idItemType);
			
			Item *item = NULL;
			
			if (cache != m_recyleItems.end() ) 
			{
				item = cache->second;
			}
			else
			{
				item = new Item(info.idItemType);
				
				m_recyleItems.insert(std::pair<int, Item*>(info.idItemType, item));
			}
			
			m_vecSpeedBtn[i]->ChangeItem(item, true);
			
			m_vecSpeedBtn[i]->EnalbeGray(true);
		}
	}
}

void GameUIItemConfig::SetSpeedBar(unsigned int index, Item* item)
{
	if (index < m_vecSpeedBar.size() && index < m_vecSpeedBtn.size()) 
	{
		ItemBarCellInfo& info = m_vecSpeedBar[index];
		
		if ((unsigned int)(info.nPos) == index) 
		{
			info.idItemType = index;
			
			info.idItemType = item == NULL ? 0 : item->iItemType;
			
			m_vecSpeedBtn[index]->ChangeItem(item);
		}
	}
}

void GameUIItemConfig::SwapSpeedBar(unsigned int src, unsigned int dest)
{
	if (src < m_vecSpeedBar.size() && src < m_vecSpeedBtn.size() &&
		dest < m_vecSpeedBar.size() && dest < m_vecSpeedBtn.size()) 
	{
		ItemBarCellInfo& infoSrc = m_vecSpeedBar[src];
		ItemBarCellInfo& infoDst = m_vecSpeedBar[dest];
		
		int tmpItemType = infoDst.idItemType;
		
		infoDst.idItemType = infoSrc.idItemType;
		
		infoSrc.idItemType = tmpItemType;
		
		Item* tmpItem = m_vecSpeedBtn[dest]->GetItem();
		bool gray = m_vecSpeedBtn[dest]->IsGray();
		
		m_vecSpeedBtn[dest]->ChangeItem(m_vecSpeedBtn[src]->GetItem(), m_vecSpeedBtn[src]->IsGray());
		m_vecSpeedBtn[dest]->EnalbeGray(m_vecSpeedBtn[src]->IsGray());
		
		m_vecSpeedBtn[src]->ChangeItem(tmpItem, gray);
		m_vecSpeedBtn[src]->EnalbeGray(gray);
	}
}

void GameUIItemConfig::LoadSpeedBarData()
{
	NDItemBarDataPersist& speedBarData = NDItemBarDataPersist::DefaultInstance();
	
	speedBarData.GetItemBarConfigInBattle(NDPlayer::defaultHero().m_id, m_vecSpeedBar);
}

void GameUIItemConfig::SaveSpeedBarData()
{
	NDItemBarDataPersist& speedBarData = NDItemBarDataPersist::DefaultInstance();
	
	int idPlayer = NDPlayer::defaultHero().m_id;
	
	for_vec(m_vecSpeedBar, std::vector<ItemBarCellInfo>::iterator)
	{
		ItemBarCellInfo& info = *it;
		
		speedBarData.SetItemAtIndexInBattle(idPlayer, info.nPos, info.idItemType);
	}
}

void GameUIItemConfig::AddPageItemBtn()
{
	for (int i = 0; i < item_row; i++) 
		for (int j = 0; j < item_col; j++) 
		{
			NDUIItemButton *btn = new NDUIItemButton;
			
			btn->Initialization();
			
			btn->SetDelegate(this);
			
			btn->SetFrameRect(CGRectMake(item_startx+j*(item_width+item_interval_w),
										 item_starty+i*(item_height+item_interval_h), 
										 item_width, 
										 item_height));
			
			this->AddChild(btn);
			
			m_vecBtn.push_back(btn);
		}
}

void GameUIItemConfig::AddPageBtn()
{
	for (int i = 0; i < max_page; i++) 
	{
		m_btnPage[i] = new NDUIButton;
		
		m_btnPage[i]->Initialization();
		
		m_btnPage[i]->SetDelegate(this);
		
		m_btnPage[i]->SetFrameRect(CGRectMake(page_startx,
									 i*(page_h+page_inter), 
									 page_w, 
									 page_h));
		
		this->AddChild(m_btnPage[i]);
	}
}

void GameUIItemConfig::AddSpeedBtn()
{
	for (int i = 0; i < speed_item_row; i++) 
		for (int j = 0; j < speed_item_col; j++) 
		{
			NDUIItemButton *btn = new NDUIItemButton;
			
			btn->Initialization();
			
			btn->SetDelegate(this);
			/*-
			btn->SetFrameRect(CGRectMake(speed_item_startx+j*(speed_item_width+speed_item_interval_w),
										 speeditem_starty+i*(speed_item_height+speed_item_interval_h), 
										 speed_item_width, 
										 speed_item_height));
			*/
			btn->SetFrameRect(CGRectMake(speed_item_startx+i*(speed_item_width+speed_item_interval_w+4),
										 speeditem_starty+j*(speed_item_height+speed_item_interval_h), 
										 speed_item_width, 
										 speed_item_height));
			
			btn->ShowItemCount(false);
			
			this->AddChild(btn);
			
			m_vecSpeedBtn.push_back(btn);
		}
}

void GameUIItemConfig::ShowPage()
{
	unsigned int start = m_curPage * (item_row*item_col);
	
	unsigned int end = (m_curPage+1) * (item_row*item_col);
	
	size_t size = m_vecBtn.size();
	
	for(size_t i = 0; i < size; i++)
	{
		if (i >= start && i < end) 
			m_vecBtn[i]->SetVisible(true);
		else
			m_vecBtn[i]->SetVisible(false);
	}
	
	unsigned int count = size / (item_row*item_col) 
						 + (size % (item_row*item_col) != 0 ? 1 : 0);
	
	for (int i = 0; i < max_page; i++) 
	{
		if (m_btnPage[i]) 
			m_btnPage[i]->SetVisible((unsigned int)i < count);
	}
}

int GameUIItemConfig::findSpeedBarEmptyPos(int itemtype, bool insert/*=false*/)
{
	int res = -1;
	
	bool bfind = false;
	
	std::vector<ItemBarCellInfo>::iterator iter;
	
	for_vec(m_vecSpeedBar, std::vector<ItemBarCellInfo>::iterator)
	{
		ItemBarCellInfo& info = *it;
		
		if (info.idItemType == itemtype) 
		{
			bfind = true;
			
			break;
		}
		
		if (res == -1) 
		{
			iter = it;
			res = info.nPos;
		}
	}
	
	if (bfind) res = -1;
	
	if (res != -1 && insert) 
	{
		(*iter).idItemType = itemtype;
	}
	
	return res;
}

void GameUIItemConfig::draw()
{
	if (!this->IsVisibled()) return;
	
	NDUILayer::draw();
		
	if (m_picOption)
		m_picOption->DrawInRect(CGRectMake(item_option_x, item_option_y, item_option_w, item_option_h));
		
	if (m_picOptionSel)
	{
		CGSize size = m_picOptionSel->GetSize();
		m_picOptionSel->DrawInRect(CGRectMake(item_option_x+(item_option_w-size.width)/2, item_option_y+item_option_h+1, size.width, size.height));
	}
	
	for(int i = 0; i < speed_item_row; i++)
	{
		int x = speed_item_startx-2+i*(speed_item_width+4+speed_item_interval_w),
			y = speeditem_starty-2,
			w = 4+speed_item_width,
			h = 4+(speed_item_height+speed_item_interval_h)*speed_item_col-speed_item_interval_h;
		DrawRecttangle(CGRectMake(x, y, w, h), ccc4(251, 222, 63, 255));
								  
		DrawCircle(ccp(x+w/2, y+h), speed_item_width/2, 0, 40, ccc4(251, 222, 63, 255));
		
		if (m_picSpeedNums[i])
			m_picSpeedNums[i]->DrawInRect(CGRectMake(x+(w-14)/2, y+h, 14, 14));
	}
}

#pragma mark 主界面物品配置

#define main_speed_item_row (3)

#define main_speed_item_col (6)

#define main_speed_item_width (42)

#define main_speed_item_height (42)

#define main_speed_item_interval_w (14)

#define main_speed_item_interval_h (1)

#define main_speed_item_startx (23)

#define main_speeditem_starty (38)

#define main_item_option_x (4)

#define main_item_option_y (3)

#define main_item_option_w (204)

#define main_item_option_h (33)

IMPLEMENT_CLASS(GameMainUIItemConfig, NDUILayer)

GameMainUIItemConfig::GameMainUIItemConfig()
{
	memset(m_btnPage, 0, sizeof(m_btnPage));
	
	m_btnClose = NULL;
	
	m_imageMouse = NULL;
	
	//m_layerSpeedBar = NULL;
	
	m_picOption = m_picOptionSel = NULL;
	
	memset(m_picSpeedNums, 0, sizeof(m_picSpeedNums));
}

GameMainUIItemConfig::~GameMainUIItemConfig()
{
	SaveSpeedBarData();
	
	for (std::map<int, Item*>::iterator it = m_recyleItems.begin(); it != m_recyleItems.end(); it++) 
	{
		delete it->second;
	}
	
	m_recyleItems.clear();
	
	for (std::map<int, NDPicture*>::iterator it = m_recylePictures.begin(); it != m_recylePictures.end(); it++) 
	{
		delete it->second;
	}
	
	m_recylePictures.clear();
	
	for (int i = 0; i < 3; i++) 
	{
		if (m_picSpeedNums[i])
			delete m_picSpeedNums[i];
	}
}

void GameMainUIItemConfig::Initialization()
{
	NDUILayer::Initialization();
	
	CGSize winsize = NDDirector::DefaultDirector()->GetWinSize();
	
	NDPicturePool& pool = *(NDPicturePool::DefaultPool());
	
	this->SetBackgroundImage(pool.AddPicture(GetImgPathBattleUI("item_settle_bg.png"), winsize.width, winsize.height), true);
	
	this->SetFrameRect(CGRectMake(0, 0, winsize.width, winsize.height));
	
	this->SetBackgroundColor(ccc4(0, 0, 0, 255));
	
	m_btnClose = new NDUIButton;
	
	m_btnClose->Initialization();
	
	NDUILabel *lbTitle = new NDUILabel;
	
	lbTitle->Initialization();
	
	lbTitle->SetTextAlignment(LabelTextAlignmentCenter);
	
	lbTitle->SetFontSize(18);
	
	lbTitle->SetFontColor(ccc4(251, 222, 63, 255));
	
	lbTitle->SetText(NDCommonCString("ItemSpeedBarSet"));
	
	lbTitle->SetFrameRect(CGRectMake(main_item_option_x, main_item_option_y, main_item_option_w, main_item_option_h));
	
	this->AddChild(lbTitle);
	
	//m_btnClose->SetTitle("关闭");
	NDPicture *picClose = pool.AddPicture(GetImgPathBattleUI("close_btn.png"));
	
	CGSize sizeClose = picClose->GetSize();
	
	m_btnClose->SetImage(picClose, false, CGRectZero, true);
	
	m_btnClose->SetDelegate(this);
	
	m_btnClose->SetFrameRect(CGRectMake(winsize.width-10-sizeClose.width, 2, sizeClose.width, sizeClose.height));
	
	this->AddChild(m_btnClose);
	
	m_imageMouse = new NDUIImage;
	
	m_imageMouse->Initialization();
	
	m_imageMouse->EnableEvent(false);
	
	this->AddChild(m_imageMouse, 1);
	
	//AddPageItemBtn();
	
	//AddPageBtn();
	
	AddSpeedBtn();
	
	//ShowPage();
	
	LoadSpeedBarData();
	
	
	VEC_ITEM battleItems;
	
	ItemMgrObj.GetCanUsableItem(battleItems);
	
	//refreshButtons(battleItems);
	
	m_bag = new NewGameItemBag;
	
	m_bag->Initialization(battleItems, false, false);
	
	m_bag->SetFrameRect(CGRectMake(203, 42, NEW_ITEM_BAG_W, NEW_ITEM_BAG_H));
	
	m_bag->SetPageCount(ItemMgrObj.GetPlayerBagNum());
	
	this->AddChild(m_bag);
	
	refreshSpeedBar(battleItems);
	
	m_picOption = pool.AddPicture(GetImgPathBattleUI("bg_tab_panel.png"), main_item_option_w, main_item_option_h);
	
	//m_picOptionSel = pool.AddPicture(GetImgPathBattleUI("tab_focused_tab.png"));
	
	for(int i = 0; i < main_speed_item_row; i++)
	{
		m_picSpeedNums[i] = pool.AddPicture(GetImgPathBattleUI("bag_number.png"));
		m_picSpeedNums[i]->Cut(getNewNumCut(i+1, false));
	}
}

void GameMainUIItemConfig::OnButtonClick(NDUIButton* button)
{
	if (button == m_btnClose) 
	{
		SaveSpeedBarData();
		
		GameMainUIItemConfigDelegate *delegate = dynamic_cast<GameMainUIItemConfigDelegate*> (this->GetDelegate());
		
		if (delegate)
			delegate->OnItemConfigFinish();
		
		GameScene* scene = (GameScene*)(NDDirector::DefaultDirector()->GetScene(RUNTIME_CLASS(GameScene)));
		
		if (scene)
			scene->RefreshQuickItem();
			
		NDDirector::DefaultDirector()->PopScene();
	}
	else 
	{
		/*
		 for (int i = 0; i < max_page; i++) 
		 {
		 if (button == m_btnPage[i]) 
		 {
		 m_curPage = i;
		 
		 ShowPage();
		 
		 break;
		 }
		 }
		 */
	}
	
}

bool GameMainUIItemConfig::OnButtonDragOut(NDUIButton* button, CGPoint beginTouch, CGPoint moveTouch, bool longTouch)
{
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
			
			m_imageMouse->SetFrameRect(CGRectMake(moveTouch.x-size.width/2, moveTouch.y-size.height/2, pic->GetSize().width, pic->GetSize().height));
			
			return true;
		}
	}
	
	return false;
}

bool GameMainUIItemConfig::OnButtonDragOutComplete(NDUIButton* button, CGPoint endTouch, bool outOfRange)
{
	m_imageMouse->SetPicture(NULL);
	
	for(size_t i = 0; i < m_vecSpeedBtn.size(); i++)
	{
		if (CGRectContainsPoint(m_vecSpeedBtn[i]->GetFrameRect(), endTouch))
			return false;
	}
	
	for(size_t i = 0; i < m_vecSpeedBtn.size(); i++)
	{
		if (button == m_vecSpeedBtn[i] && outOfRange) 
		{
			
			SetSpeedBar(i, NULL);
			
			return true;
		}
	}
	
	return false;
}

bool GameMainUIItemConfig::OnButtonDragIn(NDUIButton* desButton, NDUINode *uiSrcNode, bool longTouch)
{
	if (uiSrcNode && uiSrcNode->IsKindOfClass(RUNTIME_CLASS(NDUIItemButton)) && desButton != uiSrcNode) 
	{
		Item* item = ((NDUIItemButton*)uiSrcNode)->GetItem();
		
		if (!item) 
			return false;
		
		size_t find = size_t(-1);	
		
		for(size_t i = 0; i < m_vecSpeedBtn.size(); i++)
		{
			if (desButton == m_vecSpeedBtn[i]) 
			{
				find = i;
				
				break;
			}
		}
		
		size_t findSrc = size_t(-1);
		
		if (find != (unsigned int)-1) 
		{
			for(size_t i = 0; i < m_vecSpeedBtn.size(); i++)
			{
				if (uiSrcNode == m_vecSpeedBtn[i]) 
				{
					findSrc = i;
					
					break;
				}
			}
		}
		
		if (findSrc != (unsigned int)-1 && findSrc != find)
		{
			SwapSpeedBar(findSrc, find);
			
			return true;
		}
		
		if (find == (unsigned int)-1) return false;
		
		SetSpeedBar(find, item);
		
		return true;
	}
	
	return false;
}

void GameMainUIItemConfig::refreshButtons(std::vector<Item*>& vec_item)
{	
	/*
	 for_vec(m_vecBtn, std::vector<NDUIItemButton*>::iterator)
	 {
	 (*it)->ChangeItem(NULL);
	 }
	 
	 unsigned int maxButtonCount = (item_row * item_col) * max_page;
	 
	 size_t size = vec_item.size();
	 
	 for(size_t i = 0; i < size; i++)
	 {
	 if(i >= maxButtonCount) break;
	 
	 size_t curBtns = m_vecBtn.size();
	 
	 if (i >= curBtns) 
	 AddPageItemBtn();
	 
	 if (i <  m_vecBtn.size()) 
	 m_vecBtn[i]->ChangeItem(vec_item[i]);
	 }
	 
	 if (size  < m_curPage * (item_row * item_col)) 
	 m_curPage = 0;
	 
	 ShowPage();
	 */
}

void GameMainUIItemConfig::refreshSpeedBar(std::vector<Item*>& vec_item)
{
	std::map<int, Item*> itemtypes;
	
	for_vec(vec_item, std::vector<Item*>::iterator)
	{
		if (itemtypes.find((*it)->iItemType) == itemtypes.end()) 
			itemtypes.insert(std::pair<int, Item*>((*it)->iItemType, *it));
	}
	
	/*
	 for(std::map<int, Item*>::iterator it = itemtypes.begin(); it != itemtypes.end(); it++)
	 findSpeedBarEmptyPos(it->first, true);
	 */
	
	
	size_t size = m_vecSpeedBar.size();
	
	for(size_t i = 0; i < size; i++)
	{
		if (i >= m_vecSpeedBtn.size()) break;
		
		ItemBarCellInfo& info = m_vecSpeedBar[i];
		
		std::map<int, Item*>::iterator iter = itemtypes.find(info.idItemType);
		
		if (iter != itemtypes.end() ) 
		{
			m_vecSpeedBtn[i]->ChangeItem(iter->second, true);
			
			m_vecSpeedBtn[i]->EnalbeGray(false);
		}
		else
		{
			std::map<int, Item*>::iterator cache = m_recyleItems.find(info.idItemType);
			
			Item *item = NULL;
			
			if (cache != m_recyleItems.end() ) 
			{
				item = cache->second;
			}
			else
			{
				item = new Item(info.idItemType);
				
				m_recyleItems.insert(std::pair<int, Item*>(info.idItemType, item));
			}
			
			m_vecSpeedBtn[i]->ChangeItem(item, true);
			
			m_vecSpeedBtn[i]->EnalbeGray(true);
		}
	}
}

void GameMainUIItemConfig::SetSpeedBar(unsigned int index, Item* item)
{
	if (index < m_vecSpeedBar.size() && index < m_vecSpeedBtn.size()) 
	{
		ItemBarCellInfo& info = m_vecSpeedBar[index];
		
		if ((unsigned int)(info.nPos) == index) 
		{
			info.idItemType = index;
			
			info.idItemType = item == NULL ? 0 : item->iItemType;
			
			m_vecSpeedBtn[index]->ChangeItem(item);
		}
	}
}

void GameMainUIItemConfig::SwapSpeedBar(unsigned int src, unsigned int dest)
{
	if (src < m_vecSpeedBar.size() && src < m_vecSpeedBtn.size() &&
		dest < m_vecSpeedBar.size() && dest < m_vecSpeedBtn.size()) 
	{
		ItemBarCellInfo& infoSrc = m_vecSpeedBar[src];
		ItemBarCellInfo& infoDst = m_vecSpeedBar[dest];
		
		int tmpItemType = infoDst.idItemType;
		
		infoDst.idItemType = infoSrc.idItemType;
		
		infoSrc.idItemType = tmpItemType;
		
		Item* tmpItem = m_vecSpeedBtn[dest]->GetItem();
		bool gray = m_vecSpeedBtn[dest]->IsGray();
		
		m_vecSpeedBtn[dest]->ChangeItem(m_vecSpeedBtn[src]->GetItem(), m_vecSpeedBtn[src]->IsGray());
		m_vecSpeedBtn[dest]->EnalbeGray(m_vecSpeedBtn[src]->IsGray());
		
		m_vecSpeedBtn[src]->ChangeItem(tmpItem, gray);
		m_vecSpeedBtn[src]->EnalbeGray(gray);
	}
}

void GameMainUIItemConfig::LoadSpeedBarData()
{
	NDItemBarDataPersist& speedBarData = NDItemBarDataPersist::DefaultInstance();
	
	speedBarData.GetItemBarConfigOutBattle(NDPlayer::defaultHero().m_id, m_vecSpeedBar);
}

void GameMainUIItemConfig::SaveSpeedBarData()
{
	NDItemBarDataPersist& speedBarData = NDItemBarDataPersist::DefaultInstance();
	
	int idPlayer = NDPlayer::defaultHero().m_id;
	
	for_vec(m_vecSpeedBar, std::vector<ItemBarCellInfo>::iterator)
	{
		ItemBarCellInfo& info = *it;
		
		speedBarData.SetItemAtIndexOutBattle(idPlayer, info.nPos, info.idItemType);
	}
}

void GameMainUIItemConfig::AddPageItemBtn()
{
	for (int i = 0; i < item_row; i++) 
		for (int j = 0; j < item_col; j++) 
		{
			NDUIItemButton *btn = new NDUIItemButton;
			
			btn->Initialization();
			
			btn->SetDelegate(this);
			
			btn->SetFrameRect(CGRectMake(item_startx+j*(item_width+item_interval_w),
										 item_starty+i*(item_height+item_interval_h), 
										 item_width, 
										 item_height));
			
			this->AddChild(btn);
			
			m_vecBtn.push_back(btn);
		}
}

void GameMainUIItemConfig::AddPageBtn()
{
	for (int i = 0; i < max_page; i++) 
	{
		m_btnPage[i] = new NDUIButton;
		
		m_btnPage[i]->Initialization();
		
		m_btnPage[i]->SetDelegate(this);
		
		m_btnPage[i]->SetFrameRect(CGRectMake(page_startx,
											  i*(page_h+page_inter), 
											  page_w, 
											  page_h));
		
		this->AddChild(m_btnPage[i]);
	}
}

void GameMainUIItemConfig::AddSpeedBtn()
{
	for (int i = 0; i < main_speed_item_row; i++) 
		for (int j = 0; j < main_speed_item_col; j++) 
		{
			//if (i == 0 && j == main_speed_item_col-1) continue;
			NDUIItemButton *btn = new NDUIItemButton;
			
			btn->Initialization();
			
			btn->SetDelegate(this);
			/*-
			 btn->SetFrameRect(CGRectMake(speed_item_startx+j*(speed_item_width+speed_item_interval_w),
			 speeditem_starty+i*(speed_item_height+speed_item_interval_h), 
			 speed_item_width, 
			 speed_item_height));
			 */
			btn->SetFrameRect(CGRectMake(main_speed_item_startx+i*(main_speed_item_width+main_speed_item_interval_w+4),
										 main_speeditem_starty+j*(main_speed_item_height+main_speed_item_interval_h), 
										 main_speed_item_width, 
										 main_speed_item_height));
			btn->ShowItemCount(false);
			
			this->AddChild(btn);
			
			m_vecSpeedBtn.push_back(btn);
		}
}

void GameMainUIItemConfig::ShowPage()
{
	unsigned int start = m_curPage * (item_row*item_col);
	
	unsigned int end = (m_curPage+1) * (item_row*item_col);
	
	size_t size = m_vecBtn.size();
	
	for(size_t i = 0; i < size; i++)
	{
		if (i >= start && i < end) 
			m_vecBtn[i]->SetVisible(true);
		else
			m_vecBtn[i]->SetVisible(false);
	}
	
	unsigned int count = size / (item_row*item_col) 
	+ (size % (item_row*item_col) != 0 ? 1 : 0);
	
	for (int i = 0; i < max_page; i++) 
	{
		if (m_btnPage[i]) 
			m_btnPage[i]->SetVisible((unsigned int)i < count);
	}
}

int GameMainUIItemConfig::findSpeedBarEmptyPos(int itemtype, bool insert/*=false*/)
{
	int res = -1;
	
	bool bfind = false;
	
	std::vector<ItemBarCellInfo>::iterator iter;
	
	for_vec(m_vecSpeedBar, std::vector<ItemBarCellInfo>::iterator)
	{
		ItemBarCellInfo& info = *it;
		
		if (info.idItemType == itemtype) 
		{
			bfind = true;
			
			break;
		}
		
		if (res == -1) 
		{
			iter = it;
			res = info.nPos;
		}
	}
	
	if (bfind) res = -1;
	
	if (res != -1 && insert) 
	{
		(*iter).idItemType = itemtype;
	}
	
	return res;
}

void GameMainUIItemConfig::draw()
{
	if (!this->IsVisibled()) return;
	
	NDUILayer::draw();
	
	if (m_picOption)
		m_picOption->DrawInRect(CGRectMake(main_item_option_x, main_item_option_y, main_item_option_w, main_item_option_h));
	
	if (m_picOptionSel)
	{
		CGSize size = m_picOptionSel->GetSize();
		m_picOptionSel->DrawInRect(CGRectMake(main_item_option_x, main_item_option_y+main_item_option_h+1, size.width, size.height));
	}
	
	for(int i = 0; i < main_speed_item_row; i++)
	{
		int x = main_speed_item_startx-2+i*(main_speed_item_width+4+main_speed_item_interval_w),
		y = main_speeditem_starty-2,
		w = 4+main_speed_item_width,
		h = 4+(main_speed_item_height+main_speed_item_interval_h)*main_speed_item_col-main_speed_item_interval_h;
		DrawRecttangle(CGRectMake(x, y, w, h), ccc4(251, 222, 63, 255));
		
		DrawCircle(ccp(x+w/2, y+h), main_speed_item_width/2, 0, 40, ccc4(251, 222, 63, 255));
		
		if (m_picSpeedNums[i])
			m_picSpeedNums[i]->DrawInRect(CGRectMake(x+(w-14)/2, y+h, 14, 14));
	}
}

IMPLEMENT_CLASS(GameMainUIItemConfigScene, NDScene)

GameMainUIItemConfigScene* GameMainUIItemConfigScene::Scene()
{
	GameMainUIItemConfigScene* scene = new GameMainUIItemConfigScene;
	scene->Initialization();
	
	GameMainUIItemConfig *config = new GameMainUIItemConfig;
	config->Initialization();
	scene->AddChild(config);
	
	return scene;
}