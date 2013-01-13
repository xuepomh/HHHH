/****************************************************************************
Copyright (c) 2010-2012 cocos2d-x.org
Copyright (c) 2009      Valentin Milea

http://www.cocos2d-x.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
****************************************************************************/

#include "CCTouchDispatcher.h"
#include "CCTouchHandler.h"
#include "cocoa/CCArray.h"
#include "cocoa/CCSet.h"
#include "CCTouch.h"
#include "textures/CCTexture2D.h"
#include "support/data_support/ccCArray.h"
#include "ccMacros.h"
#include <algorithm>

#if ND_MOD
	#include "CCDirector.h"
	#include "ObjectTracker.h"
#endif

NS_CC_BEGIN

/**
 * Used for sort
 */
static int less(const CCObject* p1, const CCObject* p2)
{
#if 0
	//备注：当多个同类型的Layer显示时，一个priority不够用，
	//		因此加个subPriority，规则一样是数值小的优先处理.

	CCTouchHandler* h1 = (CCTouchHandler*)p1;
	CCTouchHandler* h2 = (CCTouchHandler*)p2;

	if (h1->getPriority() < h2->getPriority())
	{
		return 1;
	}

	if (h1->getPriority() == h2->getPriority())
	{
		CCTouchDelegate* d1 = h1->getDelegate();
		CCTouchDelegate* d2 = h2->getDelegate();
		if (d1->getSubPriority() < d2->getSubPriority())
		{
			return 1;
		}
	}
	return 0;

#else
    return ((CCTouchHandler*)p1)->getPriority() < ((CCTouchHandler*)p2)->getPriority();
#endif
}

bool CCTouchDispatcher::isDispatchEvents(void)
{
    return m_bDispatchEvents;
}

void CCTouchDispatcher::setDispatchEvents(bool bDispatchEvents)
{
    m_bDispatchEvents = bDispatchEvents;
}

/*
+(id) allocWithZone:(CCZone *)zone
{
    @synchronized(self) {
        CCAssert(sharedDispatcher == nil, @"Attempted to allocate a second instance of a singleton.");
        return [super allocWithZone:zone];
    }
    return nil; // on subsequent allocation attempts return nil
}
*/

bool CCTouchDispatcher::init(void)
{
    m_bDispatchEvents = true;
    m_pTargetedHandlers = CCArray::createWithCapacity(8);
    m_pTargetedHandlers->retain();
     m_pStandardHandlers = CCArray::createWithCapacity(4);
    m_pStandardHandlers->retain();
    m_pHandlersToAdd = CCArray::createWithCapacity(8);
    m_pHandlersToAdd->retain();
    m_pHandlersToRemove = ccCArrayNew(8);

    m_bToRemove = false;
    m_bToAdd = false;
    m_bToQuit = false;
    m_bLocked = false;

    m_sHandlerHelperData[CCTOUCHBEGAN].m_type = CCTOUCHBEGAN;
    m_sHandlerHelperData[CCTOUCHMOVED].m_type = CCTOUCHMOVED;
    m_sHandlerHelperData[CCTOUCHENDED].m_type = CCTOUCHENDED;
    m_sHandlerHelperData[CCTOUCHCANCELLED].m_type = CCTOUCHCANCELLED;

#if ND_MOD
	m_curPos = CCPointZero;
	m_prePos = CCPointZero;
#endif

	return true;
}

#if ND_MOD
CCTouchDispatcher::CCTouchDispatcher() 
	: m_pTargetedHandlers(NULL)
	, m_pStandardHandlers(NULL)
	, m_pHandlersToAdd(NULL)
	, m_pHandlersToRemove(NULL)
{
	INC_CCOBJ("CCTouchDispatcher");

// #if ND_MOD
// 	m_pHandlingTouch = NULL;
// #endif

}
#endif

CCTouchDispatcher::~CCTouchDispatcher(void)
{
	DEC_CCOBJ("CCTouchDispatcher");

// #if ND_MOD
// 	m_pHandlingTouch = NULL;
// #endif

     CC_SAFE_RELEASE(m_pTargetedHandlers);
     CC_SAFE_RELEASE(m_pStandardHandlers);
     CC_SAFE_RELEASE(m_pHandlersToAdd);
 
     ccCArrayFree(m_pHandlersToRemove);
    m_pHandlersToRemove = NULL;
}

//
// handlers management
//
void CCTouchDispatcher::forceAddHandler(CCTouchHandler *pHandler, CCArray *pArray)
{
    unsigned int u = 0;

    CCObject* pObj = NULL;
    CCARRAY_FOREACH(pArray, pObj)
     {
         CCTouchHandler *h = (CCTouchHandler *)pObj;
         if (h)
         {
             if (h->getPriority() < pHandler->getPriority())
             {
                 ++u;
             }
 
#if 0
			 if (h->getPriority() == pHandler->getPriority())
			 {
				 if (h->getDelegate()->getSubPriority() < pHandler->getDelegate()->getSubPriority())
				 {
					 ++u;
				 }
			 }
#endif

             if (h->getDelegate() == pHandler->getDelegate())
             {
                 CCAssert(0, "");
                 return;
             }
         }
     }

    pArray->insertObject(pHandler, u);
}

void CCTouchDispatcher::addStandardDelegate(CCTouchDelegate *pDelegate, int nPriority)
{    
    CCTouchHandler *pHandler = CCStandardTouchHandler::handlerWithDelegate(pDelegate, nPriority);
    if (! m_bLocked)
    {
        forceAddHandler(pHandler, m_pStandardHandlers);
    }
    else
    {
        /* If pHandler is contained in m_pHandlersToRemove, if so remove it from m_pHandlersToRemove and return.
         * Refer issue #752(cocos2d-x)
         */
        if (ccCArrayContainsValue(m_pHandlersToRemove, pDelegate))
        {
            ccCArrayRemoveValue(m_pHandlersToRemove, pDelegate);
            return;
        }

        m_pHandlersToAdd->addObject(pHandler);
        m_bToAdd = true;
    }
}

void CCTouchDispatcher::addTargetedDelegate(CCTouchDelegate *pDelegate, int nPriority, bool bSwallowsTouches)
{    
    CCTouchHandler *pHandler = CCTargetedTouchHandler::handlerWithDelegate(pDelegate, nPriority, bSwallowsTouches);
    if (! m_bLocked)
    {
        forceAddHandler(pHandler, m_pTargetedHandlers);
    }
    else
    {
        /* If pHandler is contained in m_pHandlersToRemove, if so remove it from m_pHandlersToRemove and return.
         * Refer issue #752(cocos2d-x)
         */
        if (ccCArrayContainsValue(m_pHandlersToRemove, pDelegate))
        {
            ccCArrayRemoveValue(m_pHandlersToRemove, pDelegate);
            return;
        }
        
        m_pHandlersToAdd->addObject(pHandler);
        m_bToAdd = true;
    }
}

void CCTouchDispatcher::forceRemoveDelegate(CCTouchDelegate *pDelegate)
{
    CCTouchHandler *pHandler;

    // XXX: remove it from both handlers ???
    
    // remove handler from m_pStandardHandlers
    CCObject* pObj = NULL;
    CCARRAY_FOREACH(m_pStandardHandlers, pObj)
    {
        pHandler = (CCTouchHandler*)pObj;
        if (pHandler && pHandler->getDelegate() == pDelegate)
        {
            m_pStandardHandlers->removeObject(pHandler);
            break;
        }
    }

    // remove handler from m_pTargetedHandlers
    CCARRAY_FOREACH(m_pTargetedHandlers, pObj)
    {
        pHandler = (CCTouchHandler*)pObj;
        if (pHandler && pHandler->getDelegate() == pDelegate)
        {
            m_pTargetedHandlers->removeObject(pHandler);
            break;
        }
    }
}

void CCTouchDispatcher::removeDelegate(CCTouchDelegate *pDelegate)
{
    if (pDelegate == NULL)
    {
        return;
    }

    if (! m_bLocked)
    {
        forceRemoveDelegate(pDelegate);
    }
    else
    {
        /* If pHandler is contained in m_pHandlersToAdd, if so remove it from m_pHandlersToAdd and return.
         * Refer issue #752(cocos2d-x)
         */
        CCTouchHandler *pHandler = findHandler(m_pHandlersToAdd, pDelegate);
        if (pHandler)
        {
            m_pHandlersToAdd->removeObject(pHandler);
            return;
        }

        ccCArrayAppendValue(m_pHandlersToRemove, pDelegate);
        m_bToRemove = true;
    }
}

void CCTouchDispatcher::forceRemoveAllDelegates(void)
{
     m_pStandardHandlers->removeAllObjects();
     m_pTargetedHandlers->removeAllObjects();
}

void CCTouchDispatcher::removeAllDelegates(void)
{
    if (! m_bLocked)
    {
        forceRemoveAllDelegates();
    }
    else
    {
        m_bToQuit = true;
    }
}

CCTouchHandler* CCTouchDispatcher::findHandler(CCTouchDelegate *pDelegate)
{
    CCObject* pObj = NULL;
    CCARRAY_FOREACH(m_pTargetedHandlers, pObj)
    {
        CCTouchHandler* pHandler = (CCTouchHandler*)pObj;
        if (pHandler->getDelegate() == pDelegate)
        {
            return pHandler;
        }
    }

    CCARRAY_FOREACH(m_pStandardHandlers, pObj)
    {
        CCTouchHandler* pHandler = (CCTouchHandler*)pObj;
        if (pHandler->getDelegate() == pDelegate)
        {
            return pHandler;
        }
    } 

    return NULL;
}

CCTouchHandler* CCTouchDispatcher::findHandler(CCArray* pArray, CCTouchDelegate *pDelegate)
{
    CCAssert(pArray != NULL && pDelegate != NULL, "");

    CCObject* pObj = NULL;
    CCARRAY_FOREACH(pArray, pObj)
    {
        CCTouchHandler* pHandle = (CCTouchHandler*)pObj;
        if (pHandle->getDelegate() == pDelegate)
        {
            return pHandle;
        }
    }

    return NULL;
}

void CCTouchDispatcher::rearrangeHandlers(CCArray *pArray)
{
    std::sort(pArray->data->arr, pArray->data->arr + pArray->data->num, less);
}

void CCTouchDispatcher::setPriority(int nPriority, CCTouchDelegate *pDelegate)
{
    CCAssert(pDelegate != NULL, "");

    CCTouchHandler *handler = NULL;

    handler = this->findHandler(pDelegate);

    CCAssert(handler != NULL, "");
	
    if (handler->getPriority() != nPriority)
    {
        handler->setPriority(nPriority);
        this->rearrangeHandlers(m_pTargetedHandlers);
        this->rearrangeHandlers(m_pStandardHandlers);
    }
}

//
// dispatch events
//
void CCTouchDispatcher::touches(CCSet *pTouches, CCEvent *pEvent, unsigned int uIndex)
{
    CCAssert(uIndex >= 0 && uIndex < 4, "");

    CCSet *pMutableTouches;
    m_bLocked = true;

    // optimization to prevent a mutable copy when it is not necessary
     unsigned int uTargetedHandlersCount = m_pTargetedHandlers->count();
// 	 CCLog("@@ CCTouchDispatcher::touches() uTargetedHandlersCount=%d", uTargetedHandlersCount);
// 	 CCLog("@@ CCTouchDispatcher::touches() Touches Count=%d", pTouches->count());
     unsigned int uStandardHandlersCount = m_pStandardHandlers->count();
    bool bNeedsMutableSet = (uTargetedHandlersCount && uStandardHandlersCount);

    pMutableTouches = (bNeedsMutableSet ? pTouches->mutableCopy() : pTouches);

    struct ccTouchHandlerHelperData sHelper = m_sHandlerHelperData[uIndex];
    //
    // process the target handlers 1st
    //
    if (uTargetedHandlersCount > 0)
    {
        CCTouch *pTouch;
        CCSetIterator setIter;
        for (setIter = pTouches->begin(); setIter != pTouches->end(); ++setIter)
        {
            pTouch = (CCTouch *)(*setIter);

// #if ND_MOD
// 			if(m_pHandlingTouch)
// 			{
// 				if(pTouch != m_pHandlingTouch)
// 					continue;
// 			}
// #endif

            CCTargetedTouchHandler *pHandler = NULL;
            CCObject* pObj = NULL;
            CCARRAY_FOREACH(m_pTargetedHandlers, pObj)
            {
                pHandler = (CCTargetedTouchHandler *)(pObj);

                if (! pHandler)
                {
                   break;
                }

                bool bClaimed = false;
                if (uIndex == CCTOUCHBEGAN)
                {
                    bClaimed = pHandler->getDelegate()->ccTouchBegan(pTouch, pEvent);

                    if (bClaimed)
                    {
                        pHandler->getClaimedTouches()->addObject(pTouch);
// #if ND_MOD
// 						m_pHandlingTouch = pTouch;
// #endif
                    }
                } else
                if (pHandler->getClaimedTouches()->containsObject(pTouch))
                {
                    // moved ended canceled
                    bClaimed = true;

                    switch (sHelper.m_type)
                    {
                    case CCTOUCHMOVED:
                        pHandler->getDelegate()->ccTouchMoved(pTouch, pEvent);
                        break;
                    case CCTOUCHENDED:
                        pHandler->getDelegate()->ccTouchEnded(pTouch, pEvent);
                        pHandler->getClaimedTouches()->removeObject(pTouch);
// #if ND_MOD
// 						m_pHandlingTouch = NULL;
// #endif
                        break;
                    case CCTOUCHCANCELLED:
                        pHandler->getDelegate()->ccTouchCancelled(pTouch, pEvent);
                        pHandler->getClaimedTouches()->removeObject(pTouch);
// #if ND_MOD
// 						m_pHandlingTouch = NULL;
// #endif
                        break;
                    }
                }

                if (bClaimed && pHandler->isSwallowsTouches())
                {
                    if (bNeedsMutableSet)
                    {
                        pMutableTouches->removeObject(pTouch);
// #if ND_MOD
// 						m_pHandlingTouch = NULL;
// #endif
                    }
#if ND_MOD && 0
					CCLog( 
						"@@ CCTouchDispatcher::touches(), %s swallowed!! touchCount=%d, uIndex=%d, (priority=%d, subPriority=%d), handle=%08X, delegate=%08X\r\n", 
						pHandler->getDelegate()->getDebugName(), 
						pTouches->count(), uIndex,
						pHandler->getPriority(), pHandler->getDelegate()->getSubPriority(),
						pHandler, pHandler->getDelegate());
#endif
                    break;
                }
            }
        }
    }

    //
    // process standard handlers 2nd
    //
    if (uStandardHandlersCount > 0 && pMutableTouches->count() > 0)
    {
        CCStandardTouchHandler *pHandler = NULL;
        CCObject* pObj = NULL;
        CCARRAY_FOREACH(m_pStandardHandlers, pObj)
        {
            pHandler = (CCStandardTouchHandler*)(pObj);

            if (! pHandler)
            {
                break;
            }

            switch (sHelper.m_type)
            {
            case CCTOUCHBEGAN:
                pHandler->getDelegate()->ccTouchesBegan(pMutableTouches, pEvent);
                break;
            case CCTOUCHMOVED:
                pHandler->getDelegate()->ccTouchesMoved(pMutableTouches, pEvent);
                break;
            case CCTOUCHENDED:
                pHandler->getDelegate()->ccTouchesEnded(pMutableTouches, pEvent);
                break;
            case CCTOUCHCANCELLED:
                pHandler->getDelegate()->ccTouchesCancelled(pMutableTouches, pEvent);
                break;
            }
        }
    }

    if (bNeedsMutableSet)
    {
        pMutableTouches->release();
    }

    //
    // Optimization. To prevent a [handlers copy] which is expensive
    // the add/removes/quit is done after the iterations
    //
    m_bLocked = false;
    if (m_bToRemove)
    {
        m_bToRemove = false;
        for (unsigned int i = 0; i < m_pHandlersToRemove->num; ++i)
        {
            forceRemoveDelegate((CCTouchDelegate*)m_pHandlersToRemove->arr[i]);
        }
        ccCArrayRemoveAllValues(m_pHandlersToRemove);
    }

    if (m_bToAdd)
    {
        m_bToAdd = false;
        CCTouchHandler* pHandler = NULL;
        CCObject* pObj = NULL;
        CCARRAY_FOREACH(m_pHandlersToAdd, pObj)
         {
             pHandler = (CCTouchHandler*)pObj;
            if (! pHandler)
            {
                break;
            }

            if (dynamic_cast<CCTargetedTouchHandler*>(pHandler) != NULL)
            {                
                forceAddHandler(pHandler, m_pTargetedHandlers);
            }
            else
            {
                forceAddHandler(pHandler, m_pStandardHandlers);
            }
         }
 
         m_pHandlersToAdd->removeAllObjects();    
    }

    if (m_bToQuit)
    {
        m_bToQuit = false;
        forceRemoveAllDelegates();
    }
}

void CCTouchDispatcher::touchesBegan(CCSet *touches, CCEvent *pEvent)
{
#if ND_MOD
	CCSize winSize = CCDirector::sharedDirector()->getWinSize();
	CCTouch *touch = (CCTouch *) touches->anyObject();
	CCPoint curPos = touch->locationInView();
	CCPoint prePos = touch->previousLocationInView();

	//m_curPos = CCPointMake(curPos.y, winSize.height - curPos.x);
	//m_prePos = CCPointMake(prePos.y, winSize.height - prePos.x);
	// 	m_curPos = CCPointMake(curPos.x, winSize.height - curPos.y);
	// 	m_prePos = CCPointMake(prePos.x, winSize.height - prePos.y);
	m_curPos = curPos;
	m_prePos = prePos;
#endif

	if (m_bDispatchEvents)
	{
		//CCLog( "@@ CCTouchDispatcher::touchesBegan( %d, %d )\r\n", int(m_curPos.x), int(m_curPos.y) );

		this->touches(touches, pEvent, CCTOUCHBEGAN);
	}
}

void CCTouchDispatcher::touchesMoved(CCSet *touches, CCEvent *pEvent)
{
#if ND_MOD
	CCSize winSize = CCDirector::sharedDirector()->getWinSize();
	CCTouch *touch = (CCTouch *) touches->anyObject();
	CCPoint curPos = touch->locationInView();
	CCPoint prePos = touch->previousLocationInView();

	// 	m_curPos = CCPointMake(curPos.y, winSize.height - curPos.x);
	// 	m_prePos = CCPointMake(prePos.y, winSize.height - prePos.x);
	// 	m_curPos = CCPointMake(curPos.x, winSize.height - curPos.y);
	// 	m_prePos = CCPointMake(prePos.x, winSize.height - prePos.y);
	m_curPos = curPos;
	m_prePos = prePos;
#endif

    if (m_bDispatchEvents)
	{
		this->touches(touches, pEvent, CCTOUCHMOVED);
	}
}

void CCTouchDispatcher::touchesEnded(CCSet *touches, CCEvent *pEvent)
{
#if ND_MOD
	CCSize winSize = CCDirector::sharedDirector()->getWinSize();
	CCTouch *touch = (CCTouch *) touches->anyObject();
	CCPoint curPos = touch->locationInView();
	CCPoint prePos = touch->previousLocationInView();

	// 	m_curPos = CCPointMake(curPos.y, winSize.height - curPos.x);
	// 	m_prePos = CCPointMake(prePos.y, winSize.height - prePos.x);
	// 	m_curPos = CCPointMake(curPos.x, winSize.height - curPos.y);
	// 	m_prePos = CCPointMake(prePos.x, winSize.height - prePos.y);
	m_curPos = curPos;
	m_prePos = prePos;
#endif

    if (m_bDispatchEvents)
	{
		//CCLog( "@@ CCTouchDispatcher::touchesEnded( %d, %d )\r\n", int(m_curPos.x), int(m_curPos.y));

		this->touches(touches, pEvent, CCTOUCHENDED);
	}
}

void CCTouchDispatcher::touchesCancelled(CCSet *touches, CCEvent *pEvent)
{
#if ND_MOD
 	CCSize winSize = CCDirector::sharedDirector()->getWinSize();
 	CCTouch *touch = (CCTouch *)touches->anyObject();
 	CCPoint curPos = touch->locationInView();
 	CCPoint prePos = touch->previousLocationInView();
// 
// 	m_curPos = CCPointMake(curPos.y, winSize.height - curPos.x);
// 	m_prePos = CCPointMake(prePos.y, winSize.height - prePos.x);
#endif

    if (m_bDispatchEvents)
	{
		this->touches(touches, pEvent, CCTOUCHCANCELLED);
	}
}

#if ND_MOD
CCPoint CCTouchDispatcher::getCurPos()
{
	return m_curPos;
}

CCPoint CCTouchDispatcher::getPrePos()
{
	return m_prePos;
}

//for debug only.
std::string CCTouchDispatcher::dump()
{
	std::string info;

	int index = 0;

	// remove handler from m_pStandardHandlers
	CCObject* pObj = NULL;
	CCARRAY_FOREACH(m_pStandardHandlers, pObj)
	{
		CCTouchHandler* pHandler = (CCTouchHandler*)pObj;
		if (!pHandler) continue;

		CCTouchDelegate* del = pHandler->getDelegate();
		if (!del) continue;

		int priority = pHandler->getPriority();
		int subPriority = del->getSubPriority();

		const char* dbgName = del->getDebugName();

		char str[1024] = "";
		sprintf( str, "standard handler[%d]: priority=%d, subPriority=%d, dbgName=%s\r\n", 
			index++, priority, subPriority, dbgName?dbgName:"" );

		//CCLog( str );
		info+= str;
	}

	index = 0;

	// remove handler from m_pTargetedHandlers
	CCARRAY_FOREACH(m_pTargetedHandlers, pObj)
	{
		CCTouchHandler* pHandler = (CCTouchHandler*)pObj;
		if (!pHandler) continue;

		CCTouchDelegate* del = pHandler->getDelegate();
		if (!del) continue;

		int priority = pHandler->getPriority();
		int subPriority = del->getSubPriority();

		const char* dbgName = del->getDebugName();

		char str[1024] = "";
		sprintf( str, "target handler[%d]: priority=%d, subPriority=%d, dbgName=%s\r\n", 
			index++, priority, subPriority, dbgName?dbgName:"" );

		//CCLog( str );
		info+= str;
	}
	return info;
}

#endif //ND_MOD

NS_CC_END
