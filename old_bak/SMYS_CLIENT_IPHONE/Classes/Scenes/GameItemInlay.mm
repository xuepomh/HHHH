/*
 *  GameItemInlay.mm
 *  DragonDrive
 *
 *  Created by jhzheng on 11-8-13.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include "GameItemInlay.h"
#include "NDDirector.h"
#include "ItemMgr.h"
#include "NDUISynLayer.h"
#include "NDUIImage.h"
#include "NDUtility.h"
#include "ItemImage.h"

///////////////////////////////////////////////////////
#define inlay_image ([[NSString stringWithFormat:@"%s", GetImgPath("titles.png")] UTF8String])

const float poly[4*2] = 
{
	10,54,
	470-4, 54,
	10, 266,
	470-4, 266,
};

const float line[26] =
{
	11,60,  //point
	16,60,
	16,55,
	470-6-1,55,
	470-6-1,60,
	470-1-1,60,
	470-1-1,268-(4+2)-1,
	470-6-1,268-(4+2)-1,
	470-6-1,268-1-1,
	16,268-1-1,
	16,268-6-1,
	11,268-6-1,
	11,60,
};

IMPLEMENT_CLASS(GameInlayScene, NDScene)

GameInlayScene::GameInlayScene()
{
	memset(m_stoneInfo, 0, sizeof(CellInfo *)*(e_display_col*e_display_row));
	m_iFocusIndex = 0;
	m_itemfocus = NULL;
	m_tlShare = NULL;
	m_menuLayer = NULL;
	m_toplayer = NULL;
	m_layerBGTitle = NULL;
	m_lbTitle = NULL;
	m_picInlay = NULL; m_imageInlay = NULL;
	m_iItemID = -1;
	
	m_bStone = false;
}

GameInlayScene::~GameInlayScene()
{
	SAFE_DELETE(m_picInlay);
	for (int i = 0; i < e_display_col*e_display_row; i++)
	{
		CellInfo* cellinfo = m_stoneInfo[i];
		if (cellinfo)
		{
			SAFE_DELETE(cellinfo->m_picBack);
			SAFE_DELETE(cellinfo->m_picItem);
			m_stoneInfo[i] = NULL;
		}
	}
}

void GameInlayScene::Initialization(int itemID, int itemType)
{
	NDScene::Initialization();
	
	CGSize winSize = NDDirector::DefaultDirector()->GetWinSize();
	
	m_menuLayer = new NDUIMenuLayer();
	m_menuLayer->Initialization();
	m_menuLayer->SetDelegate(this);
	m_menuLayer->SetBackgroundColor(BKCOLOR4);
	this->AddChild(m_menuLayer);	
	
	if ( m_menuLayer->GetCancelBtn() ) 
	{
		m_menuLayer->GetCancelBtn()->SetDelegate(this);
	}
	
	m_toplayer = new NDUITopLayer;
	m_toplayer->Initialization();
	m_toplayer->Initialization();
	m_toplayer->SetFrameRect(CGRectMake(0,0, winSize.width, winSize.height-48));
	this->AddChild(m_toplayer, 2);
	
	do
	{
		m_tlShare = new NDUITableLayer;
		m_tlShare->Initialization();
		m_tlShare->VisibleSectionTitles(false);
		m_tlShare->SetDelegate(this);
		m_tlShare->SetVisible(false);
		m_tlShare->SetFrameRect(CGRectMake((winSize.width-120)/2, (winSize.height-63)/2, 120, 63));
		
		NDDataSource *dataSource = new NDDataSource;
		NDSection *section = new NDSection;
		section->UseCellHeight(true);
		NDUIButton *btninlay = new NDUIButton;
		btninlay->Initialization();
		btninlay->SetFrameRect(CGRectMake(0, 0, 120, 30));
		btninlay->SetTitle(NDCommonCString("XiangQian"));
		btninlay->SetFontColor(ccc4(38,59,28,255));
		btninlay->SetFocusColor(ccc4(253, 253, 253, 255));
		section->AddCell(btninlay);
		
		NDUIButton *btndetail = new NDUIButton;
		btndetail->Initialization();
		btndetail->SetFrameRect(CGRectMake(0, 0, 120, 30));
		btndetail->SetTitle(NDCommonCString("detail"));
		btndetail->SetFontColor(ccc4(38,59,28,255));
		btndetail->SetFocusColor(ccc4(253, 253, 253, 255));
		section->AddCell(btndetail);
		
		//NDUILabel *lableinlay = new NDUILabel();
		//		lableinlay->Initialization(); 
		//		lableinlay->SetText(NDCommonCString("XiangQian"));
		//		lableinlay->SetFontSize(13);
		//		lableinlay->SetTextAlignment(LabelTextAlignmentCenter);
		//		lableinlay->SetFontColor(ccc4(38,59,28,255));
		//		lableinlay->SetFrameRect(CGRectMake(0, 0, 120, 13));
		//		section->AddCell(lableinlay); 
		//		
		//		NDUILabel *labledetail = new NDUILabel();
		//		labledetail->Initialization(); 
		//		labledetail->SetText(NDCommonCString("detail"));
		//		labledetail->SetFontSize(13);
		//		labledetail->SetTextAlignment(LabelTextAlignmentCenter);
		//		labledetail->SetFontColor(ccc4(38,59,28,255));
		//		labledetail->SetFrameRect(CGRectMake(0, 0, 120, 13));
		//		section->AddCell(labledetail); 
		
		dataSource->AddSection(section);
		
		m_tlShare->SetDataSource(dataSource);
		
		m_toplayer->AddChild(m_tlShare);
	}while (0);
	
	m_layerBGTitle = new NDUILayer;
	m_layerBGTitle->Initialization();
	m_layerBGTitle->SetFrameRect(CGRectMake(14,60, 449, 24));
	m_layerBGTitle->SetBackgroundColor(ccc4(99, 116, 98, 255));
	m_menuLayer->AddChild(m_layerBGTitle);
	
	m_lbTitle = new NDUILabel; 
	m_lbTitle->Initialization(); 
	m_lbTitle->SetText(""); 
	m_lbTitle->SetFontSize(13); 
	m_lbTitle->SetTextAlignment(LabelTextAlignmentLeft); 
	m_lbTitle->SetFrameRect(CGRectMake(4, 5, 438, 13));
	m_lbTitle->SetFontColor(ccc4(255, 255, 255,255));
	m_layerBGTitle->AddChild(m_lbTitle);
	
	for (int i=0; i<4; i++)
	{
		m_polygonCorner[i] = new NDUIPolygon;
		m_polygonCorner[i]->Initialization();
		m_polygonCorner[i]->SetLineWidth(1);
		m_polygonCorner[i]->SetColor(ccc3(46, 67, 50));
		m_polygonCorner[i]->SetFrameRect(CGRectMake(poly[i*2], poly[i*2+1], 4, 4));
		this->AddChild(m_polygonCorner[i]);
	}
	
	for (int i=0; i<12; i++)
	{
		m_line[i] =  new NDUILine;
		m_line[i]->Initialization();
		m_line[i]->SetWidth(1);
		m_line[i]->SetColor(ccc3(46, 67, 50));
		m_line[i]->SetFromPoint(CGPointMake(line[i*2], line[i*2+1]));
		m_line[i]->SetToPoint(CGPointMake(line[i*2+2], line[i*2+1+2]));
		m_line[i]->SetFrameRect(CGRectMake(1, 1, 1, 1));
		this->AddChild(m_line[i]);
	}
	
	m_picInlay = NDPicturePool::DefaultPool()->AddPicture(inlay_image);
	m_picInlay->Cut(CGRectMake(0, 161, 80, 18));
	CGSize sizeInlay = m_picInlay->GetSize();
	
	m_imageInlay =  new NDUIImage;
	m_imageInlay->Initialization();
	m_imageInlay->SetPicture(m_picInlay);
	m_imageInlay->SetFrameRect(CGRectMake((winSize.width-sizeInlay.width)/2, 
										  (28-sizeInlay.height)/2, 
										  sizeInlay.width, sizeInlay.height));
	m_menuLayer->AddChild(m_imageInlay);
	
	m_bStone = itemType / 100000 == 290;
	
	int equipType = (itemType / 100000) % 100;
	
	std::vector<Item*> vec_item_res;
	std::vector<Item*> vec_item = ItemMgrObj.GetPlayerBagItems();
	std::vector<Item*>::iterator it = vec_item.begin();
	for (; it != vec_item.end(); it++)
	{
		Item *item = (*it);
		if (item == NULL)
		{
			continue;
		}
		if (m_bStone) {
			if (item->canInlay()) {
				vec_item_res.push_back(item);
			}
		} else if (item->iItemType / 100000 == 290) {
			bool bAdd = false;
			int stoneType = (item->iItemType / 1000) % 100;
			if (equipType < 40 && stoneType == 1) { // 武器
				bAdd = true;
			} else if (equipType == stoneType) { // 其他装备位
				bAdd = true;
			}
			if (bAdd) {
				vec_item_res.push_back(item);
			}
		}
	}
	
	int itemCount = vec_item_res.size();
	
	if (itemCount == 0) 
	{
		m_lbTitle->SetText(NDCommonCString("NotXiangQiangBaoShi"));
	}
	
	for (int i = 0; i < e_display_col*e_display_row; i++) {
		if (i < itemCount ) {
			InitCellItem(i, vec_item_res[i], true);
		}
		else
		{
			InitCellItem(i, NULL, true);
		}
		
	}
	
	m_itemfocus = new ItemFocus;
	m_itemfocus->Initialization();
	this->AddChild(m_itemfocus,1);
	if (m_stoneInfo[0] && m_stoneInfo[0]->button)
	{
		m_itemfocus->SetFrameRect(m_stoneInfo[0]->button->GetFrameRect());
		if (m_stoneInfo[0]->item)
		{
			m_lbTitle->SetText(m_stoneInfo[0]->item->getItemDesc().c_str());
		}
	}
	m_iFocusIndex = 0;
	m_iItemID = itemID;
}

void GameInlayScene::OnButtonClick(NDUIButton* button)
{
	for (int i = 0; i < e_display_col*e_display_row; i++)
	{
		if (m_stoneInfo[i] && m_stoneInfo[i]->button == button)
		{
			if (m_stoneInfo[i]->item)
			{
				m_lbTitle->SetText(m_stoneInfo[i]->item->getItemDesc().c_str());
			}
			else 
			{
				m_lbTitle->SetText("");
			}
			
			if (m_iFocusIndex != i)
			{
				m_itemfocus->SetFrameRect(m_stoneInfo[i]->button->GetFrameRect());
			}
			else 
			{
				if (m_stoneInfo[i]->item != NULL) 
				{
					m_tlShare->SetVisible(true);
				}
				
			}
			m_iFocusIndex = i;
			
			return;
		}
	}
	
	if (m_menuLayer)
	{
		if (m_menuLayer->GetCancelBtn() == button) 
		{
			if (m_tlShare->IsVisibled())
			{
				m_tlShare->SetVisible(false);
				return;
			}
			NDDirector::DefaultDirector()->PopScene();
		}
	}
	
}

void GameInlayScene::OnTableLayerCellSelected(NDUITableLayer* table, NDUINode* cell, unsigned int cellIndex, NDSection* section)
{
	if (table == m_tlShare && m_iFocusIndex != -1)
	{
		if (cell && cell->IsKindOfClass(RUNTIME_CLASS(NDUIButton)))
		{
			if (m_stoneInfo[m_iFocusIndex] && m_stoneInfo[m_iFocusIndex]->item)
			{
				NDUIButton *btn = (NDUIButton*)cell;
				std::string str = btn->GetTitle();
				Item *item = m_stoneInfo[m_iFocusIndex]->item;
				if (str == NDCommonCString("XiangQian"))
				{
					
					ShowProgressBar;
					NDTransData bao(_MSG_STONE);
					bao << (unsigned char)(Item::LIFESKILL_INLAY) << (int)(m_bStone ? item->iID : m_iItemID)
					<< (int)(m_bStone ? m_iItemID : item->iID);
					SEND_DATA(bao);
				}
				else if (str == NDCommonCString("detail"))
				{
					std::string tempStr = item->makeItemDes(false, true);
					//ChatRecordManager.parserChat(tempStr, -1)
					NDUIDialog *dlg = new NDUIDialog;
					dlg->Initialization();
					dlg->Show(item->getItemNameWithAdd().c_str(), tempStr.c_str(), NULL, NULL);
				}
			}
		}
		m_tlShare->SetVisible(false);
	}
}

void GameInlayScene::InitCellItem(int iIndex, Item* item, bool bShow)
{
	if (iIndex<0 || iIndex>=e_display_col*e_display_row)
	{
		NDLog(@"GameInlayScene::InitCellItem初始化物品格子参数有误!!!");
		return;
	}
	if (!m_stoneInfo[iIndex])
	{
		m_stoneInfo[iIndex] = new CellInfo;
	}
	
	m_stoneInfo[iIndex]->item = item;
	
	NDUIButton*& btn	= m_stoneInfo[iIndex]->button;
	NDPicture*& picBack = m_stoneInfo[iIndex]->m_picBack;
	NDPicture*& picItem = m_stoneInfo[iIndex]->m_picItem;
	NDUIImage*& imgBack = m_stoneInfo[iIndex]->m_imgBack;
	
	if (item)
	{
		int iIconIndex = item->getIconIndex();
		
		if (iIconIndex > 0)
		{
			//imageRowIndex = (byte) (iconIndex / 100 - 1);
			//imageColIndex = (byte) (iconIndex % 100 - 1);
			
			iIconIndex = (iIconIndex % 100 - 1) + (iIconIndex / 100 - 1) * 6;
		}
		
		if (iIconIndex != -1)
		{
			picItem = ItemImage::GetItem(iIconIndex);
		}
	}
	
	if (!btn)
	{
		picBack = NDPicturePool::DefaultPool()->AddPicture(GetImgPath("ui_item.png"));
		
		if (!imgBack) 
		{
			imgBack = new NDUIImage;
			imgBack->Initialization();
			imgBack->SetPicture(picBack);
			imgBack->SetFrameRect(CGRectMake( 30+(12+ITEM_CELL_W)*(iIndex%e_display_col),
											 86+(3+ITEM_CELL_H)*(iIndex/e_display_col), 
											 ITEM_CELL_W, ITEM_CELL_H));
			if(m_menuLayer)
			{
				m_menuLayer->AddChild(imgBack);
			}
			imgBack->SetVisible(bShow);
		}
		
		btn = new NDUIButton;
		btn->Initialization();
		btn->SetDelegate(this);
		//btn->SetFrameRect(CGRectMake(8+(ITEM_CELL_INTERVAL_W+ITEM_CELL_W)*(iIndex%MAX_CELL_PER_PAGE%ITEM_BAG_C),
		//									 30+(ITEM_CELL_INTERVAL_H+ITEM_CELL_H)*(iIndex%MAX_CELL_PER_PAGE/ITEM_BAG_C), 
		//			
		btn->SetFrameRect(CGRectMake( 30+(12+ITEM_CELL_W)*(iIndex%e_display_col)+1,
									 86+(3+ITEM_CELL_H)*(iIndex/e_display_col)+1, 
									 ITEM_CELL_W-2, ITEM_CELL_H-2));
		
		if(m_menuLayer)
		{
			m_menuLayer->AddChild(btn);
		}
	}
	
	if (picItem)
	{
		btn->SetImage(picItem);
		int iColor = item->getItemColor();
		btn->SetBackgroundColor(INTCOLORTOCCC4(iColor));
		btn->SetBackgroundPicture(ItemImage::GetPinZhiPic(item->iItemType), NULL, true);
	}
	else 
	{
		//		btn->SetImage(picBack);
		//		btn->SetBackgroundColor(BKCOLOR4);
		btn->SetBackgroundPicture(NULL, NULL, true);
	}
	btn->SetVisible(bShow && picItem);
}