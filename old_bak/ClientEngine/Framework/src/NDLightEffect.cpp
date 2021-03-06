//
//  NDLightEffect.mm
//  DragonDrive
//
//  Created by xiezhenghai on 11-4-21.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#include "NDLightEffect.h"
#include "NDAnimationGroupPool.h"

namespace NDEngine
{
	IMPLEMENT_CLASS(NDLightEffect, NDNode)
	
	NDLightEffect::NDLightEffect()
	{
		m_frameRunRecord = NULL;
		m_aniGroup = NULL;
		m_lightId = 0;
		m_reverse = false;
	}
	
	NDLightEffect::~NDLightEffect()
	{
		CC_SAFE_RELEASE(m_aniGroup);
		CC_SAFE_RELEASE(m_frameRunRecord);
	}
	
	void NDLightEffect::Initialization(const char* sprFile)
	{
		NDNode::Initialization();	
		m_aniGroup = NDAnimationGroupPool::defaultPool()->addObjectWithSpr(sprFile);
		m_frameRunRecord = new NDFrameRunRecord();		
	}
	
	void NDLightEffect::SetPosition(CGPoint newPosition)
	{
		m_position = newPosition;
	}
	
	void NDLightEffect::SetRepeatTimes(unsigned int times)
	{
		if (m_frameRunRecord) 
			m_frameRunRecord->setRepeatTimes(times);
	}
	
	void NDLightEffect::SetLightId(unsigned int lightId, bool reverse/*=true*/)
	{
		m_lightId = lightId;
		m_reverse = reverse;
	}
	
	void NDLightEffect::SlowDown(unsigned int mutli)
	{
		if (m_aniGroup)
		{
			NDAnimation *ani = m_aniGroup->getAnimations()->objectAtIndex(m_lightId);
			if (ani) 
				ani->SlowDown(mutli);
		}
	}
	
	void NDLightEffect::Run(CGSize mapSize, bool draw/*=true*/)
	{		
		if (m_aniGroup->getAnimations()->count() > m_lightId) 
		{	
			NDSprite *oldSprite = m_aniGroup->getRuningSprite();
			m_aniGroup->setRuningSprite(NULL);			
			NDAnimation *ani = m_aniGroup->getAnimations()->objectAtIndex(m_lightId);			
			m_aniGroup->setRunningMapSize(mapSize);
			m_aniGroup->setPosition(m_position);			
			ani->setReverse(m_reverse);
			ani->runWithRunFrameRecord(m_frameRunRecord, true);
			m_aniGroup->setRuningSprite(oldSprite);
		}
	}
	
	
	void NDLightEffect::draw()
	{
		NDNode::draw();
		
		NDLayer* layer = (NDLayer*)this->GetParent();
		if (layer) 
		{
			if (m_frameRunRecord->getIsCompleted()) 
			{
				this->RemoveFromParent(true);
				return;
			}
			
			if (m_aniGroup->getAnimations()->count() > m_lightId) 
			{				
				NDAnimation *ani = m_aniGroup->getAnimations()->objectAtIndex(m_lightId);		
				m_aniGroup->setRunningMapSize(layer->GetContentSize());
				m_aniGroup->setPosition(m_position);			
				ani->setReverse(m_reverse);
				ani->runWithRunFrameRecord(m_frameRunRecord, true);
			}
			else 
			{
				this->RemoveFromParent(true);
			}
		}				
	}
}


