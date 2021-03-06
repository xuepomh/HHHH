/*
 *  NDUICheckBox.mm
 *  DragonDrive
 *
 *  Created by jhzheng on 11-1-11.
 *  Copyright 2011 (����)DeNA. All rights reserved.
 *
 */


#include "NDUICheckBox.h"
#include "NDUILayer.h"
#include "CCTextureCache.h"
#include "NDDirector.h"
#include "CCPointExtension.h"
#include "NDUILabel.h"
//#include "NDUtil.h"
#include "NDPicture.h"
#include "NDPath.h"
#include "ObjectTracker.h"

using namespace NDEngine;


#define CB_WIDTH 18
#define CB_HEIGHT 18

#define FONT_SIZE 15

IMPLEMENT_CLASS(NDUICheckBox, NDUINode)
NDUICheckBox::NDUICheckBox()
{
	INC_NDOBJ_RTCLS

	m_bChecked		= false;
	m_focusColor = cocos2d::ccc3(0, 0, 255);	
	
	m_picCheck = m_picUnCheck = NULL;
	
	m_bClearOnFree = false;
	
	m_imgChecked = NULL;
	
	m_title = NULL;
}

NDUICheckBox::~NDUICheckBox()
{
	DEC_NDOBJ_RTCLS

	if (m_bClearOnFree) 
	{
		delete m_picCheck;
		delete m_picUnCheck;
	}
}

void NDUICheckBox::Initialization()
{
	NDUINode::Initialization();
	
	m_title = new NDUILabel();
	m_title->Initialization();
	m_title->SetText("");
	m_title->SetFontSize(FONT_SIZE);
	m_title->SetTextAlignment(LabelTextAlignmentLeft);
	this->AddChild(m_title);
	
	NDPicture *picCheckBkg = new NDPicture();
	picCheckBkg->Initialization(NDPath::GetImgPath("checkbox_bg.png").c_str());
	
	NDUIImage* image = new NDUIImage();
	image->Initialization();
	image->SetPicture(picCheckBkg, true);
	image->SetFrameRect(CCRectMake(0, 0, CB_WIDTH, CB_HEIGHT));
	this->AddChild(image);
	
	NDPicture *picChecked = new NDPicture();
	picChecked->Initialization(NDPath::GetImgPath("checkbox_check.png").c_str());
	
	m_imgChecked = new NDUIImage();
	m_imgChecked->Initialization();
	m_imgChecked->SetPicture(picChecked, true);
	m_imgChecked->SetFrameRect(CCRectMake(0, 0, CB_WIDTH, CB_HEIGHT));
	this->AddChild(m_imgChecked);
	
	m_imgChecked->SetVisible(m_bChecked);
}

void NDUICheckBox::Initialization(NDPicture *checkPic, NDPicture *unCheckPic, bool bClearOnFree/*=false*/)
{
	NDUINode::Initialization();
	
	if (m_bClearOnFree) 
	{
		if (m_picCheck) delete m_picCheck;
		
		if (m_picUnCheck) delete m_picUnCheck;
	}
	
	m_picCheck = checkPic;
	
	m_picUnCheck = unCheckPic;
	
	m_bClearOnFree = bClearOnFree;
}

void NDUICheckBox::draw()
{
	if (!isDrawEnabled()) return;
	NDUINode::draw();

	if (!this->IsVisibled()) 
	{
		return;
	}
	
	if (m_picCheck || m_picUnCheck) 
	{
		CCRect scrRect = this->GetScreenRect();
		
		if (GetCBState() && m_picCheck) 
		{
			m_picCheck->DrawInRect(CCRectMake(scrRect.origin.x, scrRect.origin.y, m_picCheck->GetSize().width, m_picCheck->GetSize().height));
		} else if (!GetCBState() && m_picUnCheck) 
		{
			m_picUnCheck->DrawInRect(CCRectMake(scrRect.origin.x, scrRect.origin.y, m_picUnCheck->GetSize().width, m_picUnCheck->GetSize().height));
		}
	}
	
//	NDNode* parentNode = this->GetParent();
//	if (parentNode && parentNode->IsKindOfClass(RUNTIME_CLASS(NDUILayer))) 
//	{
//		NDUILayer	*uiLayer = (NDUILayer*)parentNode;
//		CCRect scrRect = this->GetScreenRect();	
//		
//		//draw focus 
//		if (uiLayer->GetFocus() == this) 
//		{
//			//this->DrawRecttangle(scrRect, ccc4(m_focusColor.r, m_focusColor.g, m_focusColor.b, 255));					
//		}
//
//	}
}

void NDUICheckBox::SetFrameRect(CCRect rect)
{
	rect.size.height = CB_HEIGHT;
	NDUINode::SetFrameRect(rect);
	if (m_title) m_title->SetFrameRect(CCRectMake(CB_WIDTH + 10, 0, rect.size.width - CB_WIDTH - 10, rect.size.height));
}

bool NDUICheckBox::GetCBState()
{
	return m_bChecked;
}

void NDUICheckBox::ChangeCBState()
{
	m_bChecked = !m_bChecked;
	if (m_imgChecked) m_imgChecked->SetVisible(m_bChecked);
}

void NDUICheckBox::SetFocusColor(cocos2d::ccColor3B color)
{
	m_focusColor = color;
}

void NDUICheckBox::SetFontColor(cocos2d::ccColor3B fontColor)
{
	if (m_title) 
	{
		m_title->SetFontColor(ccc4(fontColor.r, fontColor.g, fontColor.b, 255));
	}
}
void NDUICheckBox::SetText(std::string text)
{
	if (m_title) 
	{
		m_title->SetText(text.c_str());
	}
}
