/*
 *  NDTimer.cpp
 *  DragonDrive
 *
 *  Created by wq on 11-1-17.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include "NDTimer.h"
#include "CCScheduler.h"

class Timer : public cocos2d::CCObject
{
	CC_PROPERTY(int, m_nTag, Tag)
	CC_PROPERTY(ITimerCallback*, m_TimerCallback, TimerCallback)
	
public:
	void onTimer(ccTime elapsed);
};

Timer::Timer()
: m_nTag(0)
, m_TimerCallback(NULL)
{
}

void Timer::onTimer(ccTime elapsed)
{
	if (timerCallback)
	{
		timerCallback->OnTimer(tag);
	}
}

NDTimer::NDTimer()
{
	
}

NDTimer::~NDTimer()
{
	CCScheduler *sch = CCScheduler->sharedScheduler();
	MAP_TIMER::iterator it = m_mapTimer.begin();
	for (; it != m_mapTimer.end(); it++)
	{
		Timer *timer = it->second;
		sch->unscheduleSelector(schedule_selector(NDTimer::onTimer), timer);
		timer->release();
	}
}

void NDTimer::SetTimer(ITimerCallback* timerCallback, OBJID tag, float interval)
{
	if (timerCallback && interval > 0)
	{
		IMP_CALLBACK cbImp;
		cbImp.tag				= tag;
		cbImp.timerCallback		= timerCallback;
		
		if (m_mapTimer.count(cbImp) <= 0)
		{
			CCScheduler *sch = CCScheduler::sharedScheduler();
			Timer *timer = new Timer;
			timer->setTag(tag);
			timer->setTimerCallback(timerCallback);
			sch->scheduleSelector(schedule_selector(NDTimer::onTimer), timer, interval, false);
			m_mapTimer[cbImp] = timer;
		}
	}
}

void NDTimer::KillTimer(ITimerCallback* timerCallback, OBJID tag)
{
	IMP_CALLBACK cbImp;
	cbImp.tag = tag;
	cbImp.timerCallback = timerCallback;
	
	MAP_TIMER::iterator it = m_mapTimer.find(cbImp);
	
	if (it != m_mapTimer.end())
	{
		CCScheduler *sch = CCScheduler::sharedScheduler();
		Timer *timer = it->second;
		sch->unscheduleSelector(schedule_selector(NDTimer::onTimer), timer);
		timer->release();
		m_mapTimer.erase(it);
	}
}