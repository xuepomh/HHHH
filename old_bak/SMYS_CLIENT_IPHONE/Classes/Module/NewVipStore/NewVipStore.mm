/*
 *  NewVipStore.mm
 *  DragonDrive
 *
 *  Created by jhzheng on 11-11-4.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include "NewVipStore.h"
#include "NDUtility.h"
#include "NDCommonControl.h"
#include "ItemImage.h"
#include "NDPlayer.h"
#include "NDTransData.h"
#include "NDDataTransThread.h"
#include "NDUISynLayer.h"
#include "NDMsgDefine.h"
#include "ItemMgr.h"
#include "CGPointExtension.h"
#include "NDDirector.h"

#include <sstream>

#pragma mark 划斜线文本

class SlashLabel : public NDUILabel
{
	DECLARE_CLASS(SlashLabel)

public:
	SlashLabel()
	{
		m_colorLine = ccc4(255, 0, 0, 255);
	}
	
	void SetSlashColor(ccColor4B colorLine)
	{
		m_colorLine = colorLine;
	}
	
	void draw() override
	{
		NDUILabel::draw();
		
		if (!this->IsVisibled()) return;
		
		CGRect scrRect = this->GetScreenRect();
		CGSize size = GetTextureSize();
		DrawLine(ccp(scrRect.origin.x-2,scrRect.origin.y+size.height/2-1), 
				 ccpAdd(scrRect.origin, ccp(size.width+2, size.height/2+1)), 
				 m_colorLine, 1);
	}
	
private:
	ccColor4B m_colorLine;
};

IMPLEMENT_CLASS(SlashLabel, NDUILabel)

#pragma mark 系统商店信息

#define max_buy_count (100)

IMPLEMENT_CLASS(VipShopInfo, NDUILayer)

VipShopInfo::VipShopInfo()
{
	m_btnCurItemButton = NULL;
	
	m_lbItemName = m_lbItemLvl = NULL;
	
	m_lbItemPrice = m_lbVipPrice = NULL;
	
	m_descScroll = NULL;
	
	m_slide = NULL;
	
	m_btnBuy = NULL;
	
	memset(m_btnGood, 0, sizeof(m_btnGood));
	
	m_lbEMoney = m_lbMoney = NULL;
	
	m_btnPrev = m_btnNext = NULL;
	
	m_lbPage = NULL;
	
	m_iCurPage = 0;
	
	m_iShopType = 0;
	
	m_iCurItemType = 0;
	
	m_layerPrice = NULL;
}

VipShopInfo::~VipShopInfo()
{
}

void VipShopInfo::Initialization(int shopType)
{
	map_vip_item& mapVipItem = ItemMgrObj.GetVipStore();
	
	NDAsssert(mapVipItem.find(shopType) != mapVipItem.end());
	
	m_iShopType = shopType;
	
	NDUILayer::Initialization();
	
	InitAttrPanel();
	
	InitItemPanel();
	
	UpdateCurpageGoods();
	
	OnButtonClick(m_btnGood[0]);
	
	Update();
}

void VipShopInfo::OnButtonClick(NDUIButton* button)
{
	if (button == m_btnNext)
	{
		ShowNext();
	}
	else if (button == m_btnPrev)
	{
		ShowPrev();
	}
	else if (button == m_btnBuy)
	{
		DealBuy();
	}
	else
	{
		OnClickGoodItem(button);
	}
}

void VipShopInfo::Update() // 包括AttrPanel, 令牌, 荣誉值
{
	UpdateAttrPanel();
	
	UpdateMoney();
}

void VipShopInfo::InitAttrPanel()
{
	NDPicturePool& pool = *(NDPicturePool::DefaultPool());
	
	NDPicture* picBagLeftBg = pool.AddPicture(GetImgPathNew("bag_left_bg.png"));
	
	CGSize sizeBagLeftBg = picBagLeftBg->GetSize();
	
	NDUILayer *layer = new NDUILayer;
	layer->Initialization();
	layer->SetBackgroundImage(picBagLeftBg, true);
	layer->SetFrameRect(CGRectMake(0, 12, sizeBagLeftBg.width, sizeBagLeftBg.height));
	this->AddChild(layer);
	
	m_btnCurItemButton = new NDUIItemButton;
	m_btnCurItemButton->Initialization();
	m_btnCurItemButton->ShowItemCount(false);
	m_btnCurItemButton->SetFrameRect(CGRectMake(18, 14, 42, 42));
	layer->AddChild(m_btnCurItemButton);
	
	m_lbItemName = new NDUILabel;
	m_lbItemName->Initialization();
	m_lbItemName->SetTextAlignment(LabelTextAlignmentLeft);
	m_lbItemName->SetFontSize(18);
	m_lbItemName->SetFrameRect(CGRectMake(73, 14, 200, 20));
	//m_lbItemName->SetText("天宫战斧");
	m_lbItemName->SetFontColor(ccc4(136, 41, 41, 255));
	layer->AddChild(m_lbItemName);
	
	m_lbItemLvl = new NDUILabel;
	m_lbItemLvl->Initialization();
	m_lbItemLvl->SetTextAlignment(LabelTextAlignmentLeft);
	m_lbItemLvl->SetFontSize(16);
	m_lbItemLvl->SetFrameRect(CGRectMake(73, 38, 200, 20));
	//m_lbItemLvl->SetText("等级需求: 14级");
	m_lbItemLvl->SetFontColor(ccc4(136, 41, 41, 255));
	layer->AddChild(m_lbItemLvl);
	
	/*
	NDUILabel* lb = new NDUILabel;
	lb->Initialization();
	lb->SetTextAlignment(LabelTextAlignmentLeft);
	lb->SetFontSize(14);
	lb->SetFrameRect(CGRectMake(18, 70, 200, 20));
	lb->SetFontColor();
	lb->SetText("原价");
	layer->AddChild(m_lbItemPrice);
	
	m_lbItemPrice = new NDUILabel;
	m_lbItemPrice->Initialization();
	m_lbItemPrice->SetTextAlignment(LabelTextAlignmentLeft);
	m_lbItemPrice->SetFontSize(14);
	m_lbItemPrice->SetFrameRect(CGRectMake(55, 70, 200, 20));
	m_lbItemPrice->SetText("8888888");
	layer->AddChild(m_lbItemPrice);
	
	m_lbVipPrice = new NDUILabel;
	m_lbVipPrice->Initialization();
	m_lbVipPrice->SetTextAlignment(LabelTextAlignmentLeft);
	m_lbVipPrice->SetFontSize(14);
	m_lbVipPrice->SetFrameRect(CGRectMake(139, 70, 200, 20));
	m_lbVipPrice->SetText("8888888");
	layer->AddChild(m_lbVipPrice);
	*/
	
	m_layerPrice = new NDUILayer;
	m_layerPrice->Initialization();
	m_layerPrice->SetTouchEnabled(false);
	m_layerPrice->SetFrameRect(CGRectMake(18, 70, 80-18, 20));
	layer->AddChild(m_layerPrice);
	
	NDPicture *picCut = pool.AddPicture(GetImgPathNew("bag_left_fengge.png"));
	
	CGSize sizeCut = picCut->GetSize();
	
	NDUIImage* imageCut = new NDUIImage;
	imageCut->Initialization();
	imageCut->SetPicture(picCut, true);
	imageCut->SetFrameRect(CGRectMake((sizeBagLeftBg.width-sizeCut.width)/2, 95, sizeCut.width, sizeCut.height));
	imageCut->EnableEvent(false);
	layer->AddChild(imageCut);
	
	picCut = pool.AddPicture(GetImgPathNew("bag_left_fengge.png"));
	
	imageCut = new NDUIImage;
	imageCut->Initialization();
	imageCut->SetPicture(picCut, true);
	imageCut->SetFrameRect(CGRectMake((sizeBagLeftBg.width-sizeCut.width)/2, 175, sizeCut.width, sizeCut.height));
	imageCut->EnableEvent(false);
	layer->AddChild(imageCut);
	
	m_descScroll = new NDUIContainerScrollLayer;
	m_descScroll->Initialization();
	m_descScroll->SetFrameRect(CGRectMake(10, 100, sizeBagLeftBg.width-20, 70));
	layer->AddChild(m_descScroll);
	
	SetDescContent("");
	
	m_slide = new NDSlideBar;
	m_slide->Initialization(CGRectMake(0, 180, sizeBagLeftBg.width-10, 44), 127, true);
	m_slide->SetMin(0);
	m_slide->SetMax(0);
	m_slide->SetCur(0);
	layer->AddChild(m_slide);
	
	m_btnBuy = new NDUIButton;
	m_btnBuy->Initialization();
	m_btnBuy->SetFrameRect(CGRectMake(7, 228, 48, 24));
	m_btnBuy->SetFontColor(ccc4(255, 255, 255, 255));
	m_btnBuy->SetFontSize(12);
	m_btnBuy->CloseFrame();
	m_btnBuy->SetBackgroundPicture(pool.AddPicture(GetImgPathNew("bag_btn_normal.png")),
								   pool.AddPicture(GetImgPathNew("bag_btn_click.png")),
								   false, CGRectZero, true);
	m_btnBuy->SetTitle(NDCommonCString("buy"));
	m_btnBuy->SetDelegate(this);							 
	
	layer->AddChild(m_btnBuy);
}

void VipShopInfo::InitItemPanel()
{
	NDPicturePool& pool = *(NDPicturePool::DefaultPool());
	
	int startX = 217, startY = 17,
	intervalW = 4, intervalH = 5,
	itemW = 42, itemH = 42;
	
	for (int i = 0; i < max_btns; i++) 
	{
		int x = startX+(i % col)*(itemW+intervalW),
		y = startY+(i / col)*(itemH+intervalH);
		NDUIItemButton*& btn = m_btnGood[i];
		btn = new NDUIItemButton;
		btn->Initialization();
		btn->SetDelegate(this);
		btn->SetFrameRect(CGRectMake(x, y, itemW, itemH));
		this->AddChild(btn);
	}
	
	NDUILayer* backlayer = new NDUILayer;
	backlayer->Initialization();
	backlayer->SetBackgroundColor(ccc4(129, 98, 54, 255));
	backlayer->SetFrameRect(CGRectMake(startX, startY+(max_btns/col)*(itemH+intervalH), itemW*col+intervalW*(col-1), 20));
	backlayer->SetTouchEnabled(false);
	this->AddChild(backlayer);
	
	
	NDPicture *picEMoney = pool.AddPicture(GetImgPathNew("bag_bagemoney.png"));
	NDPicture *picMoney = pool.AddPicture(GetImgPathNew("bag_bagmoney.png"));
	
	unsigned int interval = 8;
	
	NDPicture* tmpPics[2];
	tmpPics[0] = picEMoney;
	tmpPics[1] = picMoney;
 	
	int width = backlayer->GetFrameRect().size.width,
	height = backlayer->GetFrameRect().size.height,
	framewidth = width/2;
	
	for (int i = 0; i < 2; i++) 
	{
		CGSize sizePic = tmpPics[i]->GetSize();
		int startx = (i == 0 ? interval : interval+framewidth),
		imageY = (height-sizePic.height)/2,
		numY = (height-14)/2;
		NDUIImage *image = new NDUIImage;
		image->Initialization();
		image->SetPicture(tmpPics[i], true);
		image->SetFrameRect(CGRectMake(startx, imageY, sizePic.width,sizePic.height));
		backlayer->AddChild(image);
		
		NDUILabel *tmpLable = NULL;
		if (i == 0)
		{
			tmpLable = m_lbEMoney = new NDUILabel; 
		}
		else if (i == 1)
		{
			tmpLable = m_lbMoney = new NDUILabel; 
		}
		
		if (tmpLable == NULL) continue;
		
		tmpLable->Initialization();
		tmpLable->SetTextAlignment(LabelTextAlignmentLeft);
		tmpLable->SetFontSize(14);
		tmpLable->SetFrameRect(CGRectMake(startx+sizePic.width+interval, numY, width, height));
		tmpLable->SetText("8888888");
		tmpLable->SetFontColor(ccc4(255, 255, 255, 255));
		backlayer->AddChild(tmpLable);
	}
	
	m_btnPrev = new NDUIButton;
	m_btnPrev->Initialization();
	m_btnPrev->SetFrameRect(CGRectMake(startX+10, 232, 36, 36));
	m_btnPrev->SetDelegate(this);
	m_btnPrev->SetImage(pool.AddPicture(GetImgPathNew("pre_page.png")), true, CGRectMake(0, 4, 36, 31), true);
	m_btnPrev->SetBackgroundPicture(pool.AddPicture(GetImgPathNew("btn_bg1.png")), NULL, false, CGRectZero, true);
	this->AddChild(m_btnPrev);
	
	m_btnNext = new NDUIButton;
	m_btnNext->Initialization();
	m_btnNext->SetFrameRect(CGRectMake(backlayer->GetFrameRect().origin.x
									   +backlayer->GetFrameRect().size.width-10-36, 
									   232, 36, 36));
	m_btnNext->SetDelegate(this);
	m_btnNext->SetImage(pool.AddPicture(GetImgPathNew("next_page.png")), true, CGRectMake(0, 4, 36, 31), true);
	m_btnNext->SetBackgroundPicture(pool.AddPicture(GetImgPathNew("btn_bg1.png")), NULL, false, CGRectZero, true);
	this->AddChild(m_btnNext);
	
	m_lbPage = new NDUILabel;
	m_lbPage->Initialization();
	m_lbPage->SetTextAlignment(LabelTextAlignmentCenter);
	m_lbPage->SetFontSize(16);
	m_lbPage->SetFontColor(ccc4(136, 41, 41, 255));
	m_lbPage->SetFrameRect(CGRectMake(m_btnPrev->GetFrameRect().origin.x, 
									  m_btnPrev->GetFrameRect().origin.y, 
									  m_btnNext->GetFrameRect().origin.x
									  +m_btnNext->GetFrameRect().size.width
									  -m_btnPrev->GetFrameRect().origin.x, 
									  m_btnPrev->GetFrameRect().size.height));
	m_lbPage->SetText("8888888");
	this->AddChild(m_lbPage);
}

void VipShopInfo::ChangeAttrPanel(int bfItemType)
{
	Item *item = NULL;
	
	if (bfItemType > 0)
		item = new Item(bfItemType);
	
	m_btnCurItemButton->ChangeItem(item);
	
	std::stringstream itemName, itemReqLvl;
	
	if (item)
	{
		itemName << item->getItemName();
		
		itemReqLvl << NDCommonCString("LevelRequire") << ": " << item->getReq_level() << NDCommonCString("Ji");
	}
	else
	{
		m_layerPrice->RemoveAllChildren(true);
	}
	
	m_lbItemName->SetText(itemName.str().c_str());
	
	m_lbItemLvl->SetText(itemReqLvl.str().c_str());
	
	
	std::stringstream medal, repute;
	
	VipItem *pVipItem = NULL;
	
	m_layerPrice->RemoveAllChildren(true);
	
	if (GetVipItemInfo(bfItemType, pVipItem) && pVipItem)
	{
		// 价格显示
		std::stringstream price;

		if (pVipItem->price != item->getPrice() && item->getPrice() != 0)
		{
			// 原价
			std::stringstream normalPrice;
			normalPrice << NDCommonCString("NormalPrice") << ": ";
			CGSize size = getStringSize(normalPrice.str().c_str(), 14);
			NDUILabel *lb = new NDUILabel;
			lb->Initialization();
			lb->SetTextAlignment(LabelTextAlignmentLeft);
			lb->SetFontSize(14);
			lb->SetFrameRect(CGRectMake(0, 0, size.width, 20));
			lb->SetText(normalPrice.str().c_str());
			m_layerPrice->AddChild(lb);
			
			std::stringstream itemprice;
			itemprice << item->getPrice();
			CGSize sizePrice = getStringSize(itemprice.str().c_str(), 14);
			
			SlashLabel *slash = new SlashLabel;
			slash->Initialization();
			slash->SetFontColor(ccc4(255, 0, 0, 255));
			slash->SetTextAlignment(LabelTextAlignmentLeft);
			slash->SetFontSize(14);
			slash->SetFrameRect(CGRectMake(size.width, 0, sizePrice.width, 20));
			slash->SetText(itemprice.str().c_str());
			m_layerPrice->AddChild(slash);
			
			price << NDCommonCString("CurPrice") << ": " << pVipItem->price;
			lb = new NDUILabel;
			lb->Initialization();
			lb->SetTextAlignment(LabelTextAlignmentLeft);
			lb->SetFontSize(14);
			lb->SetFrameRect(CGRectMake(size.width+sizePrice.width+10, 0, 200, 20));
			lb->SetText(price.str().c_str());
			m_layerPrice->AddChild(lb);
		}
		else
		{
			price << NDCommonCString("price") << ": " << pVipItem->price;
			
			NDUILabel *lb = new NDUILabel;
			lb->Initialization();
			lb->SetTextAlignment(LabelTextAlignmentLeft);
			lb->SetFontSize(14);
			lb->SetFrameRect(CGRectMake(0, 0, 200, 20));
			lb->SetText(price.str().c_str());
			m_layerPrice->AddChild(lb);
		}
		
		if (!this->IsVisibled())
			m_layerPrice->SetVisible(false);
	}

	std::stringstream desc;
	
	if (item)
	{
		desc << item->makeItemDes(false, true);
	}
	
	SetDescContent(desc.str().c_str());
	
	if (!this->IsVisibled())
	{
		m_descScroll->SetVisible(false);
	}
	
	SetBuyCount(0, GetCanBuyMaxCount(bfItemType));	
}

int  VipShopInfo::GetAttrPanelBFItemType()
{
	return m_iCurItemType;
}


void VipShopInfo::DealBuy()
{
	Item* item = m_btnCurItemButton->GetItem();
	
	if (!item) return;
	
	int curBuyCount = GetCurBuyCount();
	if (!CheckBuyCount(curBuyCount))
	{
		showDialog(NDCommonCString("tip"), NDCommonCString("BuyCountError"));
		return;
	}
	
	ShowProgressBar;
	NDTransData bao(_MSG_SHOP);
	bao << int(item->iItemType) << int(0) << (unsigned char)Item::_SHOPACT_BUY << (unsigned char)curBuyCount;
	SEND_DATA(bao);
}

int VipShopInfo::GetCurBuyCount()
{
	return m_slide->GetCur();
}

int VipShopInfo::GetCanBuyMaxCount(int bfItemType)
{
	int maxBuyCount = 0;
	
	VipItem* pVipItem = NULL;
	
	if (GetVipItemInfo(bfItemType, pVipItem) && pVipItem)
	{
		NDPlayer& player = NDPlayer::defaultHero();
		
		if (pVipItem->price > 0)
			maxBuyCount = player.eMoney / pVipItem->price;
	}
	
	return maxBuyCount;
}

void VipShopInfo::SetBuyCount(int minCount, int maxCount)
{
	m_slide->SetMin(minCount);
	m_slide->SetMax(max_buy_count, true);
}

bool VipShopInfo::CheckBuyCount(int buyCount)
{
	if (buyCount <= 0 || buyCount > max_buy_count)
		return false;
	
	Item* item = m_btnCurItemButton->GetItem();
	
	if (!item)
		return false;

	return true;
}

void VipShopInfo::ShowNext()
{
	if (m_iCurPage+1 >= GetGoodPageCount())
	{
		showDialog(NDCommonCString("tip"), NDCommonCString("LastPageTip"));
		return;
	}
	
	m_iCurPage += 1;
	
	UpdateCurpageGoods();
}

void VipShopInfo::ShowPrev()
{
	if (m_iCurPage-1 < 0)
	{
		showDialog(NDCommonCString("tip"), NDCommonCString("FirstPageTip"));
		return;
	}
	
	m_iCurPage -= 1;
	
	UpdateCurpageGoods();
}

void VipShopInfo::OnClickGoodItem(NDUIButton *btn)
{
	NDUIItemButton *clickItemBtn = NULL;
	for (int i = 0; i < max_btns; i++) 
	{
		if (m_btnGood[i] == btn)
		{
			clickItemBtn = (NDUIItemButton*)btn;
			break;
		}
	}
	
	if (!clickItemBtn)
		return;
	
	Item *item = clickItemBtn->GetItem();
	
	if (item && item->iItemType == m_iCurItemType)
	{
		std::vector<std::string> op;
		item->makeItemDialog(op);
	}
	
	m_iCurItemType = item == NULL ? 0 : item->iItemType;
	
	UpdateAttrPanel();
}

void VipShopInfo::UpdateCurpageGoods() // 包括商品,页标签
{
	map_vip_item& mapVipItem = ItemMgrObj.GetVipStore();
	map_vip_item_it it = mapVipItem.find(m_iShopType);
	
	if (it != mapVipItem.end())
	{
		vec_vip_item& itemlist = it->second;
		
		int size = itemlist.size();
		
		int startIndex = m_iCurPage*max_btns,
		endIndex = (m_iCurPage+1)*max_btns;
		
		for (int i = startIndex; i < endIndex; i++) 
		{
			int btnIndex = i-startIndex;
			
			int curItemType = 0;
			
			if (i < size)
			{
				VipItem* pVipItem = itemlist[i];
				curItemType = pVipItem->itemId;
			}
			
			if (btnIndex < max_btns && btnIndex >= 0 && m_btnGood[btnIndex])
			{
				Item *item = NULL;
				
				if (curItemType != 0)
					item = new Item(curItemType);
				
				m_btnGood[btnIndex]->ChangeItem(item);
			}
		}
	}
	
	if (!m_lbPage) return;
	
	std::stringstream ss;
	
	int pageCount = GetGoodPageCount();
	int curPage = pageCount == 0 ? 0 : m_iCurPage + 1;
	
	ss << curPage << "/" << pageCount;
	
	m_lbPage->SetText(ss.str().c_str());
}

void VipShopInfo::UpdateAttrPanel()
{
	ChangeAttrPanel(m_iCurItemType);
}

void VipShopInfo::UpdateMoney()
{
	NDPlayer& player = NDPlayer::defaultHero();
	
	std::stringstream money, emoney;
	
	emoney << player.eMoney;
	
	money << player.money;
	
	m_lbMoney->SetText(money.str().c_str());
	
	m_lbEMoney->SetText(emoney.str().c_str());
}

bool VipShopInfo::SetDescContent(const char *text, ccColor4B color/*=ccc4(0, 0, 0, 255)*/, unsigned int fontsize/*=12*/)
{
	if (!m_descScroll) return false;
	
	m_descScroll->RemoveAllChildren(true);
	
	if (!text) return false;
	
	int width = m_descScroll->GetFrameRect().size.width;
	
	CGSize textSize;
	textSize.width = width;
	textSize.height = NDUITextBuilder::DefaultBuilder()->StringHeightAfterFilter(text, textSize.width, fontsize);
	
	NDUIText* memo = NDUITextBuilder::DefaultBuilder()->Build(text, 
															  fontsize, 
															  textSize, 
															  color,
															  true);
	memo->SetFrameRect(CGRectMake(0, 0, textSize.width, textSize.height));		
	m_descScroll->AddChild(memo);
	
	m_descScroll->refreshContainer();
	
	return true;
}

int VipShopInfo::GetGoodPageCount()
{
	map_vip_item& mapVipItem = ItemMgrObj.GetVipStore();
	map_vip_item_it it = mapVipItem.find(m_iShopType);
	
	if (it != mapVipItem.end())
	{
		vec_vip_item& itemlist = it->second;
		
		return itemlist.size() / max_btns + ( (itemlist.size() % max_btns) != 0 ? 1 : 0);
	}
	
	return 0;
}

bool VipShopInfo::GetVipItemInfo(int bfItemType, VipItem*& pVipItem)
{
	map_vip_item& mapVipItem = ItemMgrObj.GetVipStore();
	map_vip_item_it itShop = mapVipItem.find(m_iShopType);
	if (itShop != mapVipItem.end())
	{
		for_vec(itShop->second, vec_vip_item_it)
		{
			if ((*it)->itemId != bfItemType)
				continue;
			
			pVipItem = *it;
			
			return true;
		}
	}
	
	return false;
}

#pragma mark 系统商店

IMPLEMENT_CLASS(VipShop, NDCommonLayer)

VipShop::VipShop()
{
	m_uiTabInterval = 3;
}

VipShop::~VipShop()
{
}

void VipShop::Initialization()
{
	CGSize winsize = NDDirector::DefaultDirector()->GetWinSize();
	
	NDPicturePool& pool = *(NDPicturePool::DefaultPool());
	
	map_vip_desc& mapVipDesc = ItemMgrObj.GetVipStoreDesc();
	
	map_vip_item& mapVipItem = ItemMgrObj.GetVipStore();
	
	//NDAsssert(!mapVipDesc.empty());
	
	float maxTitleLen = 0.0f;
	
	for(map_vip_desc_it it = mapVipDesc.begin(); it != mapVipDesc.end(); it++)
	{
		if (mapVipItem.find(it->first) == mapVipItem.end())
		{
			NDLog(@"\n=================系统商场分类[%d]找不到", it->first);
			continue;
		}
		
		CGSize textSize = getStringSize(it->second.c_str(), 18);
		
		if (textSize.width > maxTitleLen)
			maxTitleLen = textSize.width;
	}
	
	maxTitleLen += 36;
	
	int iW = winsize.width-(7+42)-(7+42);
	
	NDCommonLayer::Initialization(maxTitleLen, iW / (maxTitleLen+m_uiTabInterval));
	
	int i = 0;
	
	for(map_vip_desc_it it = mapVipDesc.begin(); it != mapVipDesc.end(); it++)
	{
		if (mapVipItem.find(it->first) == mapVipItem.end())
		{
			continue;
		}
		
		TabNode* tabnode = this->AddTabNode();
		
		tabnode->SetImage(pool.AddPicture(GetImgPathNew("newui_tab_unsel.png"), maxTitleLen, 31), 
						  pool.AddPicture(GetImgPathNew("newui_tab_sel.png"), maxTitleLen, 34),
						  pool.AddPicture(GetImgPathNew("newui_tab_selarrow.png")));
		
		tabnode->SetText(it->second.c_str());
		
		tabnode->SetTextColor(ccc4(245, 226, 169, 255));
		
		tabnode->SetFocusColor(ccc4(173, 70, 25, 255));
		
		tabnode->SetTextFontSize(18);
		
		NDUIClientLayer *client = this->GetClientLayer(i);
		
		CGSize clientsize = this->GetClientSize();
		
		
		SystemShopInfoNew *info = new SystemShopInfoNew;
		info->Initialization(it->first);
		info->SetFrameRect(CGRectMake(0, 0, clientsize.width, clientsize.height));
		client->AddChild(info);
		
		i++;
	}
	
	this->SetTabFocusOnIndex(0, true);
}

void VipShop::UpdateShopInfo()
{
	uint i = 0;
	NDUIClientLayer *client = NULL;
	while ((client = GetClientLayer(i++))) 
	{
		const std::vector<NDNode*>& children = client->GetChildren();
		for_vec(children, std::vector<NDNode*>::const_iterator)
		{
			if (!(*it)->IsKindOfClass(RUNTIME_CLASS(VipShopInfo)))
				continue;
			
			VipShopInfo *info =	(VipShopInfo*)(*it);
			
			//if (!info->IsVisibled())
			//	continue;
			
			info->Update();
		}
	}
}

#pragma mark 系统商城商品-新

IMPLEMENT_CLASS(SystemShopUIItem, ShopUIItem)

SystemShopUIItem::SystemShopUIItem()
{
	m_lbItemName = NULL;
	
	m_imgEmoney = NULL;
	
	m_iShopType = 0;
	
	m_layerPrice = NULL;
}

SystemShopUIItem::~SystemShopUIItem()
{
}

void SystemShopUIItem::Initialization(int shopType)
{
	ShopUIItem::Initialization();
	
	m_iShopType = shopType;
	
	CGSize sizestart = this->GetContentStartSize();
	
	m_lbItemName = new NDUILabel;
	m_lbItemName->Initialization();
	m_lbItemName->SetTextAlignment(LabelTextAlignmentLeft);
	m_lbItemName->SetFontSize(13);
	m_lbItemName->SetFrameRect(CGRectMake(sizestart.width, sizestart.height, 200, 20));
	//m_lbItemName->SetText("天宫战斧");
	m_lbItemName->SetFontColor(ccc4(136, 41, 41, 255));
	this->AddChild(m_lbItemName);
	
	NDPicture *picEMoney = NDPicturePool::DefaultPool()->AddPicture(GetImgPathNew("bag_bagemoney.png"));
	m_imgEmoney = new NDUIImage;
	m_imgEmoney->Initialization();
	m_imgEmoney->SetFrameRect(CGRectMake(sizestart.width, sizestart.height+15, 16, 16));
	m_imgEmoney->SetPicture(picEMoney, true);
	this->AddChild(m_imgEmoney);
	
	m_layerPrice = new NDUILayer;
	m_layerPrice->Initialization();
	m_layerPrice->SetTouchEnabled(false);
	m_layerPrice->SetFrameRect(CGRectMake(sizestart.width+18, sizestart.height+15, 80, 40));
	this->AddChild(m_layerPrice);
}

void SystemShopUIItem::ChangeSystemShopItem(int sysItemType)
{
	Item *item = NULL;
	
	if (sysItemType > 0)
		item = new Item(sysItemType);
	
	this->ChangeItem(item);
	
	std::stringstream itemName;
	
	if (item)
	{
		itemName << item->getItemName();
	}
	
	m_lbItemName->SetText(itemName.str().c_str());
	
	std::stringstream medal, repute;
	
	VipItem *pVipItem = NULL;
	
	m_layerPrice->RemoveAllChildren(true);
	
	if (GetVipItemInfo(sysItemType, pVipItem) && pVipItem)
	{
		// 价格显示
		std::stringstream price;
		
		if (pVipItem->price != item->getPrice() && item->getPrice() != 0)
		{
			// 原价
			std::stringstream normalPrice;
			normalPrice << NDCommonCString("NormalPrice") << ": ";
			CGSize size = getStringSize(normalPrice.str().c_str(), 14);
			NDUILabel *lb = new NDUILabel;
			lb->Initialization();
			lb->SetTextAlignment(LabelTextAlignmentLeft);
			lb->SetFontSize(12);
			lb->SetFrameRect(CGRectMake(0, 0, size.width, 20));
			lb->SetText(normalPrice.str().c_str());
			m_layerPrice->AddChild(lb);
			
			std::stringstream itemprice;
			itemprice << item->getPrice();
			CGSize sizePrice = getStringSize(itemprice.str().c_str(), 14);
			
			SlashLabel *slash = new SlashLabel;
			slash->Initialization();
			slash->SetFontColor(ccc4(255, 0, 0, 255));
			slash->SetTextAlignment(LabelTextAlignmentLeft);
			slash->SetFontSize(12);
			slash->SetFrameRect(CGRectMake(size.width, 0, sizePrice.width, 20));
			slash->SetText(itemprice.str().c_str());
			m_layerPrice->AddChild(slash);
			
			price << NDCommonCString("CurPrice") << ": " << pVipItem->price;
			lb = new NDUILabel;
			lb->Initialization();
			lb->SetTextAlignment(LabelTextAlignmentLeft);
			lb->SetFontSize(12);
			lb->SetFrameRect(CGRectMake(0, 15, 200, 20));
			lb->SetText(price.str().c_str());
			m_layerPrice->AddChild(lb);
		}
		else
		{
			price << NDCommonCString("price") << ": " << pVipItem->price;
			
			NDUILabel *lb = new NDUILabel;
			lb->Initialization();
			lb->SetTextAlignment(LabelTextAlignmentLeft);
			lb->SetFontSize(12);
			lb->SetFrameRect(CGRectMake(0, 0, 200, 20));
			lb->SetText(price.str().c_str());
			m_layerPrice->AddChild(lb);
		}
		
		if (!this->IsVisibled())
			m_layerPrice->SetVisible(false);
	}
}

bool SystemShopUIItem::GetVipItemInfo(int sysItemType, VipItem*& pVipItem)
{
	map_vip_item& mapVipItem = ItemMgrObj.GetVipStore();
	map_vip_item_it itShop = mapVipItem.find(m_iShopType);
	if (itShop != mapVipItem.end())
	{
		for_vec(itShop->second, vec_vip_item_it)
		{
			if ((*it)->itemId != sysItemType)
				continue;
			
			pVipItem = *it;
			
			return true;
		}
	}
	
	return false;
}

#pragma mark 系统商店信息-新

IMPLEMENT_CLASS(SystemShopInfoNew, NDUILayer)

SystemShopInfoNew::SystemShopInfoNew()
{
	m_slide = NULL;
	
	m_btnBuy = NULL;
	
	memset(m_btnGood, 0, sizeof(m_btnGood));
	
	m_lbEmoney = m_lbMoney = NULL;
	
	m_btnPrev = m_btnNext = NULL;
	
	m_lbPage = NULL;
	
	m_iCurPage = 0;
	
	m_iShopType = 0;
	
	m_iCurItemType = 0;
	
	m_scrollItem = NULL;
}

SystemShopInfoNew::~SystemShopInfoNew()
{
}

void SystemShopInfoNew::Initialization(int shopType)
{
	NDLog(@"初始化系统商城[%d]", shopType);

	map_vip_item& mapVipItem = ItemMgrObj.GetVipStore();
	
	NDAsssert(mapVipItem.find(shopType) != mapVipItem.end());
	
	m_iShopType = shopType;
	
	NDUILayer::Initialization();
	
	m_scrollItem = new NDUIContainerScrollLayer;
	m_scrollItem->Initialization();
	//m_scrollItem->SetTouchEnabled(false);
	//m_scrollItem->SetBackgroundColor(ccc4(173, 69, 23, 255));
	m_scrollItem->SetFrameRect(CGRectMake(8, 10, 480-32-8, 205));
	this->AddChild(m_scrollItem);
	
	InitAttrPanel();
	
	InitItemPanel();
	
	m_scrollItem->refreshContainer(GetGoodPageCount()*205);
	
	if (!m_vGoods.empty())
	{
		m_scrollItem->SetFocus(m_vGoods[0]);
		
		m_iCurItemType = m_vGoods[0]->GetItemType();
	}
	
	//UpdateCurpageGoods();
	
	Update();
}

void SystemShopInfoNew::OnButtonClick(NDUIButton* button)
{
	if (button == m_btnNext)
	{
		ShowNext();
		
		//if (m_btnGood[0])
		//	m_btnGood[0]->SetItemFocus(true, true);
	}
	else if (button == m_btnPrev)
	{
		ShowPrev();
		
		//if (m_btnGood[0])
		//	m_btnGood[0]->SetItemFocus(true, true);
	}
	else if (button == m_btnBuy)
	{
		DealBuy();
	}
	else if (button->IsKindOfClass(RUNTIME_CLASS(SystemShopUIItem)))
	{
		OnFocusShopUIItem((SystemShopUIItem*)button);
	}
}

void SystemShopInfoNew::OnFocusShopUIItem(ShopUIItem* shopUiItem)
{
	/*
	 for (int i = 0; i < max_btns; i++) 
	 {
	 if (!m_btnGood[i] || m_btnGood[i] == shopUiItem) continue;
	 
	 m_btnGood[i]->SetItemFocus(false);
	 }
	 */
	
	OnClickGoodItem(shopUiItem);
}

void SystemShopInfoNew::Update() // 包括AttrPanel, 令牌, 荣誉值
{
	UpdateAttrPanel();
	
	UpdateMoney();
}

void SystemShopInfoNew::InitAttrPanel()
{
	NDPicturePool& pool = *(NDPicturePool::DefaultPool());
	
	int startX = 8, startY = 236;
	
	m_btnBuy = new NDUIButton;
	m_btnBuy->Initialization();
	m_btnBuy->SetFrameRect(CGRectMake(startX+15, startY+10, 48, 24));
	m_btnBuy->SetFontColor(ccc4(255, 255, 255, 255));
	m_btnBuy->SetFontSize(12);
	m_btnBuy->CloseFrame();
	m_btnBuy->SetBackgroundPicture(pool.AddPicture(GetImgPathNew("bag_btn_normal.png")),
								   pool.AddPicture(GetImgPathNew("bag_btn_click.png")),
								   false, CGRectZero, true);
	m_btnBuy->SetTitle(NDCommonCString("buy"));
	m_btnBuy->SetDelegate(this);							 
	
	this->AddChild(m_btnBuy);
	
	m_slide = new NDSlideBar;
	m_slide->Initialization(CGRectMake(100, startY-2, 297-100, 44), 127, true);
	m_slide->SetMin(0);
	m_slide->SetMax(0);
	m_slide->SetCur(0);
	m_slide->SetBackgroundImage(NULL, false);
	this->AddChild(m_slide);
	
	m_btnPrev = new NDUIButton;
	m_btnPrev->Initialization();
	m_btnPrev->SetFrameRect(CGRectMake(311, startY, 36, 36));
	m_btnPrev->SetDelegate(this);
	m_btnPrev->SetImage(pool.AddPicture(GetImgPathNew("pre_page.png")), true, CGRectMake(0, 4, 36, 31), true);
	m_btnPrev->SetBackgroundPicture(pool.AddPicture(GetImgPathNew("btn_bg1.png")), NULL, false, CGRectZero, true);
	this->AddChild(m_btnPrev);
	
	m_btnNext = new NDUIButton;
	m_btnNext->Initialization();
	m_btnNext->SetFrameRect(CGRectMake(400, startY, 36, 36));
	m_btnNext->SetDelegate(this);
	m_btnNext->SetImage(pool.AddPicture(GetImgPathNew("next_page.png")), true, CGRectMake(0, 4, 36, 31), true);
	m_btnNext->SetBackgroundPicture(pool.AddPicture(GetImgPathNew("btn_bg1.png")), NULL, false, CGRectZero, true);
	this->AddChild(m_btnNext);
	
	m_lbPage = new NDUILabel;
	m_lbPage->Initialization();
	m_lbPage->SetTextAlignment(LabelTextAlignmentCenter);
	m_lbPage->SetFontSize(16);
	m_lbPage->SetFontColor(ccc4(136, 41, 41, 255));
	m_lbPage->SetFrameRect(CGRectMake(m_btnPrev->GetFrameRect().origin.x, 
									  m_btnPrev->GetFrameRect().origin.y, 
									  m_btnNext->GetFrameRect().origin.x
									  +m_btnNext->GetFrameRect().size.width
									  -m_btnPrev->GetFrameRect().origin.x, 
									  m_btnPrev->GetFrameRect().size.height));
	m_lbPage->SetText("8888888");
	this->AddChild(m_lbPage);
}

void SystemShopInfoNew::InitItemPanel()
{
	NDPicturePool& pool = *(NDPicturePool::DefaultPool());
	
	/*
	 int startX = 10, startY = 14,
	 intervalW = 4, intervalH = 5,
	 itemW = 142, itemH = 45;
	 
	 for (int i = 0; i < max_btns; i++) 
	 {
	 int x = startX+(i % col)*(itemW+intervalW),
	 y = startY+(i / col)*(itemH+intervalH);
	 BFShopUIItem*& btn = m_btnGood[i];
	 btn = new BFShopUIItem;
	 btn->Initialization(m_iShopType);
	 btn->SetDelegate(this);
	 btn->SetFrameRect(CGRectMake(x, y, itemW, itemH));
	 this->AddChild(btn);
	 }
	 */
	
	int startX = 2, startY = 4,
	intervalW = 4, intervalH = 5,
	itemW = 142, itemH = 45;
	
	map_vip_item& mapVipItem = ItemMgrObj.GetVipStore();
	map_vip_item_it it = mapVipItem.find(m_iShopType);
	
	if (it != mapVipItem.end())
	{
		vec_vip_item& itemlist = it->second;
		
		int size = itemlist.size();
		
		for (int i = 0; i < size; i++) 
		{
			int x = startX+(i % col)*(itemW+intervalW),
			y = startY+(i / col)*(itemH+intervalH);
			SystemShopUIItem*btn = new SystemShopUIItem;
			btn->Initialization(m_iShopType);
			btn->SetDelegate(this);
			btn->SetFrameRect(CGRectMake(x, y, itemW, itemH));
			btn->ChangeSystemShopItem(itemlist[i]->itemId);
			m_scrollItem->AddChild(btn);
			
			m_vGoods.push_back(btn);
		}
	}
	
	if (!m_lbPage) return;
	
	std::stringstream ss;
	
	int pageCount = GetGoodPageCount();
	int curPage = pageCount == 0 ? 0 : m_iCurPage + 1;
	
	ss << curPage << "/" << pageCount;
	
	m_lbPage->SetText(ss.str().c_str());
	
	
	NDUILayer* backlayer = new NDUILayer;
	backlayer->Initialization();
	backlayer->SetBackgroundColor(ccc4(129, 98, 54, 255));
	backlayer->SetFrameRect(CGRectMake(10, 18+(max_btns/col)*(itemH+intervalH), 240-startX, 20));
	backlayer->SetTouchEnabled(false);
	this->AddChild(backlayer);
	
	
	NDPicture *picEMoney = pool.AddPicture(GetImgPathNew("bag_bagemoney.png"));
	NDPicture *picMoney = pool.AddPicture(GetImgPathNew("bag_bagmoney.png"));
	
	unsigned int interval = 8;
	
	NDPicture* tmpPics[2];
	tmpPics[0] = picEMoney;
	tmpPics[1] = picMoney;
 	
	int width = backlayer->GetFrameRect().size.width,
	height = backlayer->GetFrameRect().size.height,
	framewidth = width/2;
	
	for (int i = 0; i < 2; i++) 
	{
		CGSize sizePic = tmpPics[i]->GetSize();
		int startx = (i == 0 ? interval : interval+framewidth),
		imageY = (height-sizePic.height)/2,
		numY = (height-14)/2;
		NDUIImage *image = new NDUIImage;
		image->Initialization();
		image->SetPicture(tmpPics[i], true);
		image->SetFrameRect(CGRectMake(startx, imageY, sizePic.width,sizePic.height));
		backlayer->AddChild(image);
		
		NDUILabel *tmpLable = NULL;
		if (i == 0)
		{
			tmpLable = m_lbEmoney = new NDUILabel; 
		}
		else if (i == 1)
		{
			tmpLable = m_lbMoney = new NDUILabel; 
		}
		
		if (tmpLable == NULL) continue;
		
		tmpLable->Initialization();
		tmpLable->SetTextAlignment(LabelTextAlignmentLeft);
		tmpLable->SetFontSize(14);
		tmpLable->SetFrameRect(CGRectMake(startx+sizePic.width+interval, numY, width, height));
		tmpLable->SetText("8888888");
		tmpLable->SetFontColor(ccc4(255, 255, 255, 255));
		backlayer->AddChild(tmpLable);
	}
}

void SystemShopInfoNew::ChangeAttrPanel(int bfItemType)
{
	SetBuyCount(0, GetCanBuyMaxCount(bfItemType));	
}

int  SystemShopInfoNew::GetAttrPanelBFItemType()
{
	return m_iCurItemType;
}


void SystemShopInfoNew::DealBuy()
{	
	int curBuyCount = GetCurBuyCount();
	if (!CheckBuyCount(curBuyCount))
	{
		showDialog(NDCommonCString("tip"), NDCommonCString("BuyCountError"));
		return;
	}
	
	ShowProgressBar;
	NDTransData bao(_MSG_SHOP);
	bao << int(m_iCurItemType) << int(0) << (unsigned char)Item::_SHOPACT_BUY << (unsigned char)curBuyCount;
	SEND_DATA(bao);
}

int SystemShopInfoNew::GetCurBuyCount()
{
	return m_slide->GetCur();
}

int SystemShopInfoNew::GetCanBuyMaxCount(int bfItemType)
{
	int maxBuyCount = 0;
	
	VipItem* pVipItem = NULL;
	
	if (GetVipItemInfo(bfItemType, pVipItem) && pVipItem)
	{
		NDPlayer& player = NDPlayer::defaultHero();
		
		if (pVipItem->price > 0)
			maxBuyCount = player.eMoney / pVipItem->price;
	}
	
	return maxBuyCount;
}

void SystemShopInfoNew::SetBuyCount(int minCount, int maxCount)
{
	m_slide->SetMin(minCount);
	m_slide->SetCur(minCount);
	m_slide->SetMax(max_buy_count, true);
}

bool SystemShopInfoNew::CheckBuyCount(int buyCount)
{
	if (buyCount <= 0 || buyCount > max_buy_count)
		return false;

	return true;
}

void SystemShopInfoNew::ShowNext()
{
	/*
	 if (m_iCurPage+1 >= GetGoodPageCount())
	 {
	 showDialog(NDCommonCString("tip"), "已经是最后一页!");
	 return;
	 }
	 */
	
	int pageCount = GetGoodPageCount();
	
	m_iCurPage = pageCount == 0 ? 0 : (m_iCurPage+1)%pageCount;
	
	UpdateCurpageGoods();
}

void SystemShopInfoNew::ShowPrev()
{
	/*
	 if (m_iCurPage-1 < 0)
	 {
	 showDialog(NDCommonCString("tip"), "已经是第一页!");
	 return;
	 }
	 */
	
	int pageCount = GetGoodPageCount();
	if (m_iCurPage == 0)
		m_iCurPage = pageCount == 0 ? 0 : pageCount-1;
	else
		m_iCurPage = pageCount == 0 ? 0 : m_iCurPage-1;
	
	UpdateCurpageGoods();
}

void SystemShopInfoNew::OnClickGoodItem(ShopUIItem* shopUiItem)
{
	/*
	 BFShopUIItem *clickItemBtn = NULL;
	 for (int i = 0; i < max_btns; i++) 
	 {
	 if (m_btnGood[i] == shopUiItem)
	 {
	 clickItemBtn = (BFShopUIItem*)shopUiItem;
	 break;
	 }
	 }
	 
	 if (!clickItemBtn)
	 return;
	 
	 */
	if (!shopUiItem) return;
	
	Item* item = shopUiItem->GetItem();
	
	if (item && item->iItemType == m_iCurItemType)
	{
		std::vector<std::string> op;
		item->makeItemDialog(op);
	}
	
	if (!item)
		m_iCurItemType = 0;
	else
		m_iCurItemType = item->iItemType;
	
	UpdateAttrPanel();
}

void SystemShopInfoNew::UpdateCurpageGoods() // 包括商品,页标签
{
	/*
	 map_bf_iteminfo_it it = BattleField::mapItemInfo.find(m_iShopType);
	 
	 if (it != BattleField::mapItemInfo.end())
	 {
	 vec_bf_item& itemlist = it->second;
	 
	 int size = itemlist.size();
	 
	 int startIndex = m_iCurPage*max_btns,
	 endIndex = (m_iCurPage+1)*max_btns;
	 
	 for (int i = startIndex; i < endIndex; i++) 
	 {
	 int btnIndex = i-startIndex;
	 
	 int curItemType = 0;
	 
	 if (i < size)
	 {
	 BFItemInfo& bfItemInfo = itemlist[i];
	 curItemType = bfItemInfo.itemType;
	 }
	 
	 if (btnIndex < max_btns && btnIndex >= 0 && m_btnGood[btnIndex])
	 {
	 m_btnGood[btnIndex]->ChangeBFShopItem(curItemType);
	 
	 m_btnGood[btnIndex]->SetVisible(this->IsVisibled() && curItemType != 0);
	 }
	 }
	 }
	 */
	
	size_t size = m_vGoods.size();
	
	size_t top = m_iCurPage * max_btns;
	
	if (top < size && m_scrollItem)
	{
		m_scrollItem->ScrollNodeToTop(m_vGoods[top]);
		m_scrollItem->SetFocus(m_vGoods[top]);
		m_iCurItemType = m_vGoods[top]->GetItemType();
		UpdateAttrPanel();
	}
	
	if (!m_lbPage) return;
	
	std::stringstream ss;
	
	int pageCount = GetGoodPageCount();
	int curPage = pageCount == 0 ? 0 : m_iCurPage + 1;
	
	ss << curPage << "/" << pageCount;
	
	m_lbPage->SetText(ss.str().c_str());
}

void SystemShopInfoNew::UpdateAttrPanel()
{
	ChangeAttrPanel(m_iCurItemType);
}

void SystemShopInfoNew::UpdateMoney()
{
	NDPlayer& player = NDPlayer::defaultHero();
	
	std::stringstream money, emoney;
	
	emoney << player.eMoney;
	
	money << player.money;
	
	m_lbMoney->SetText(money.str().c_str());
	
	m_lbEmoney->SetText(emoney.str().c_str()); 
}

int SystemShopInfoNew::GetGoodPageCount()
{
	map_vip_item& mapVipItem = ItemMgrObj.GetVipStore();
	map_vip_item_it it = mapVipItem.find(m_iShopType);
	
	if (it != mapVipItem.end())
	{
		vec_vip_item& itemlist = it->second;
		
		return itemlist.size() / max_btns + ( (itemlist.size() % max_btns) != 0 ? 1 : 0);
	}
	
	return 0;
}

bool SystemShopInfoNew::GetVipItemInfo(int sysItemType, VipItem*& pVipItem)
{
	map_vip_item& mapVipItem = ItemMgrObj.GetVipStore();
	map_vip_item_it itShop = mapVipItem.find(m_iShopType);
	if (itShop != mapVipItem.end())
	{
		for_vec(itShop->second, vec_vip_item_it)
		{
			if ((*it)->itemId != sysItemType)
				continue;
			
			pVipItem = *it;
			
			return true;
		}
	}
	
	return false;
}