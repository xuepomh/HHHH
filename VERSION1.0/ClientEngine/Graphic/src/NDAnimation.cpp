//
//  NDAnimation.mm
//  DragonDrive
//
//  Created by xiezhenghai on 10-12-9.
//  Copyright 2010 (网龙)DeNA. All rights reserved.
//

#include "NDAnimation.h"
#include "NDTile.h"
#include "NDAnimationGroup.h"
#include "NDFrame.h"
#include "ObjectTracker.h"

using namespace cocos2d;

NDAnimation::NDAnimation() :
	m_pkFrames(NULL),
	m_nX(0),
	m_nY(0),
	m_nW(0),
	m_nH(0),
	m_nMidX(0),
	m_nBottomY(0),
	m_nType(0),
	m_bReverse(false),
	m_pkBelongAnimationGroup(NULL),
	m_nCurIndexInAniGroup(-1),
	m_nPlayCount(0)
{
	INC_NDOBJ("NDAnimation");
	//m_pkFrames = new cocos2d::CCMutableArray<NDFrame*>();
	m_pkFrames = new cocos2d::CCArray();
}

NDAnimation::~NDAnimation()
{
	DEC_NDOBJ("NDAnimation");
	CC_SAFE_RELEASE (m_pkFrames);
}

CCRect NDAnimation::getRect()
{
	if (m_pkBelongAnimationGroup)
	{
		int nPosX = m_pkBelongAnimationGroup->getPosition().x;
		int nPosY = m_pkBelongAnimationGroup->getPosition().y;

		if (m_nMidX != 0)
		{
			nPosX -= m_nMidX - m_nX;
		}

		if (m_nBottomY != 0)
		{
			nPosY -= m_nBottomY - m_nY;
		}

		return CCRectMake(nPosX, nPosY, m_nW, m_nH);
	}

	return CCRectZero;
}

void NDAnimation::runWithRunFrameRecord(NDFrameRunRecord* pkRunFrameRecord,
		bool bNeedDraw, float fDrawScale)
{
	unsigned int uiFrameCount = m_pkFrames->count();

	if (uiFrameCount)
	{
		if (pkRunFrameRecord->getCurrentFrameIndex() >= (int) uiFrameCount)
		{
			return;
		}

		if (pkRunFrameRecord->getNextFrameIndex() != 0
				&& pkRunFrameRecord->getCurrentFrameIndex() == 0)
		{
			NDFrame* pkFrame = 0;

			if (m_nType == ANIMATION_TYPE_ONCE_END)
			{
				pkFrame = (NDFrame*)m_pkFrames->lastObject();

				if (bNeedDraw)
				{
					pkFrame->run(fDrawScale);
				}

				return;
			}
			else if (m_nType == ANIMATION_TYPE_ONCE_START)
			{
				pkFrame = (NDFrame*)m_pkFrames->objectAtIndex(0);

				if (bNeedDraw)
				{
					pkFrame->run(fDrawScale);
				}

				return;
			}
		}

		//获取动画的当前帧
		NDFrame *pkFrame = (NDFrame*) m_pkFrames->objectAtIndex(
				pkRunFrameRecord->getCurrentFrameIndex());

		pkRunFrameRecord->setTotalFrame((int) uiFrameCount);
		pkRunFrameRecord->setEnduration(pkFrame->getEnduration());

		//判断是否允许跑下一帧，如果允许则跑下一帧，否则还是跑当前帧
		if (pkFrame->enableRunNextFrame(pkRunFrameRecord))
		{
			//runFrameRecord.isCompleted = NO;	
			//取下一帧
			pkFrame = (NDFrame*) m_pkFrames->objectAtIndex(
					pkRunFrameRecord->getNextFrameIndex());

			pkRunFrameRecord->NextFrame(uiFrameCount);

			if (pkRunFrameRecord->getCurrentFrameIndex() + 1 == (int)uiFrameCount)
			{
				m_nPlayCount++;
			}
		}

		if (bNeedDraw)
		{
			//跑一帧
			pkFrame->run(fDrawScale);
		}
	}
}

void NDAnimation::runWithRunFrameRecord(NDFrameRunRecord* pkRunFrameRecord,
		bool bNeedDraw)
{
	this->runWithRunFrameRecord(pkRunFrameRecord, bNeedDraw, 1.0f);
}

void NDAnimation::SlowDown(unsigned int multi)
{
	if (m_pkFrames->count())
	{
		for (unsigned int i = 0; i < m_pkFrames->count(); i++)
		{
			NDFrame *pkFrame = (NDFrame*) m_pkFrames->objectAtIndex(i);
			pkFrame->setEnduration(pkFrame->getEnduration() * multi);
		}
	}
}

bool NDAnimation::lastFrameEnd( NDFrameRunRecord* pkRunRecord )
{
	if (pkRunRecord->isThisFrameEnd())
	{
		return pkRunRecord->getCurrentFrameIndex() ==
			pkRunRecord->getTotalFrame() - 1 && pkRunRecord->getRepeatTimes() <= 1;
	}

	return false;
}

//void NDAnimation::setFrames(cocos2d::CCMutableArray<NDFrame*>* pkFrames)
void NDAnimation::setFrames(cocos2d::CCArray* pkFrames)
{
	m_pkFrames = pkFrames;
}

//cocos2d::CCMutableArray<NDFrame*>* NDAnimation::getFrames()
cocos2d::CCArray* NDAnimation::getFrames()
{
	return m_pkFrames;
}