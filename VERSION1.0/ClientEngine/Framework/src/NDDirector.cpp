//
//  NDDirector.mm
//  DragonDrive
//
//  Created by xiezhenghai on 10-12-10.
//  Copyright 2010 (网龙)DeNA. All rights reserved.
//

#include "NDDirector.h"
#include "ccMacros.h"
// #include "NDAnimationGroupPool.h"
// #include "NDMapDataPool.h"
#include "CCEGLView.h"
#include "CCTexture2D.h"
#include "CCTextureCache.h"
#include "CCTouchDispatcher.h"
//#include "NDMapData.h"

using namespace cocos2d;

namespace NDEngine
{
IMPLEMENT_CLASS(NDDirector, NDObject)

static NDDirector* NDDirector_defaultDirector = NULL;

NDDirector::NDDirector()
{
	NDAsssert(NDDirector_defaultDirector == NULL);

	//CC_DIRECTOR_INIT();
	m_pkDirector = CCDirector::sharedDirector();
	m_setViewRectNode = NULL;
	m_resetViewRect = false;

	m_TransitionSceneWait = NULL;

	m_TransitionSceneType = eTransitionSceneNone;
}

NDDirector::~NDDirector()
{
	if (m_TransitionSceneWait)
	{
		delete m_TransitionSceneWait;
	}

	m_pkDirector->release();
	NDDirector_defaultDirector = NULL;
}

NDDirector* NDDirector::DefaultDirector()
{
	if (NDDirector_defaultDirector == NULL)
	{
		NDDirector_defaultDirector = new NDDirector();
	}
	return NDDirector_defaultDirector;
}

void NDDirector::Initialization()
{
	m_pkDirector->setOpenGLView(&CCEGLView::sharedOpenGLView());

	m_pkDirector->setDeviceOrientation(kCCDeviceOrientationLandscapeLeft);

	CC_GLVIEW* view = m_pkDirector->getOpenGLView();
#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
	//view->setMultipleTouchEnabled(false);
#endif
	m_pkDirector->enableRetinaDisplay(true);
	m_pkDirector->setAnimationInterval(1.0f / 24.0f);

	CCTexture2D::setDefaultAlphaPixelFormat (kTexture2DPixelFormat_RGBA8888);

	//#if ND_DEBUG_STATE == 1
	m_pkDirector->setDisplayFPS(true);
	//#else
	//m_director.displayFPS = NO;
	//#endif
}

void NDDirector::AddDelegate(NDObject* receiver)
{
	m_delegates.push_back(receiver);
}

void NDDirector::RemoveDelegate(NDObject* receiver)
{
	std::vector<NDObject*>::iterator iter;

	for (iter = m_delegates.begin(); iter != m_delegates.end(); iter++)
	{
		NDObject* obj = (NDObject*) *iter;

		if (obj == receiver)
		{
			m_delegates.erase(iter);
			break;
		}
	}
}

void NDDirector::TransitionAnimateComplete()
{
	if (!m_TransitionSceneWait)
	{
		return;
	}

	switch (m_TransitionSceneType)
	{
	case eTransitionSceneReplace:
		ReplaceScene (m_TransitionSceneWait);
		break;
	case eTransitionScenePush:
		PushScene(m_TransitionSceneWait);
		break;
	case eTransitionScenePop:
		PopScene(NULL, false);
	default:
		break;
	}

	m_TransitionSceneWait = NULL;
}

void NDDirector::SetTransitionScene(NDScene *scene, TransitionSceneType type)
{
// 		m_TransitionSceneWait = scene;
// 		
// 		m_TransitionSceneType = type;
// 		
// 		[m_director pushScene:[CCTransitionFadeTR transitionWithDuration:1.2f scene:(CCScene *)scene->m_ccNode]];

	/*
	 static bool right = true;
	 if (right)
	 [m_director pushScene:[CCMoveInRTransition transitionWithDuration:0.6f scene:(CCScene *)scene->m_ccNode]];
	 else
	 [m_director pushScene:[CCMoveInLTransition transitionWithDuration:0.6f scene:(CCScene *)scene->m_ccNode]];

	 right = !right;
	 */
}

void NDDirector::EnableDispatchEvent(bool enable)
{
	CCTouchDispatcher::sharedDispatcher()->setDispatchEvents(
			enable ? true : false);
}

void NDDirector::RunScene(NDScene* scene)
{
	m_scenesStack.push_back(scene);
	m_pkDirector->runWithScene((CCScene *) scene->m_ccNode);
}

void NDDirector::ReplaceScene(NDScene* scene, bool bAnimate/*=false*/)
{
// 		if (bAnimate) 
// 		{
// 			SetTransitionScene(scene, eTransitionSceneReplace);
// 			
// 			return;
// 		}

	if (m_scenesStack.size() > 0)
	{
		//NDLog("===============================当前场景栈大小[%u]", m_scenesStack.size());
		this->BeforeDirectorPopScene(m_scenesStack.back(), true);

		delete m_scenesStack.back();
		m_scenesStack.pop_back();

		this->AfterDirectorPopScene(true);
	}

	this->BeforeDirectorPushScene(scene);

	m_scenesStack.push_back(scene);

	m_pkDirector->replaceScene((CCScene *) scene->m_ccNode);

	this->AfterDirectorPushScene(scene);

	//NDLog("===============================当前场景栈大小[%u]", m_scenesStack.size());
}

void NDDirector::PushScene(NDScene* scene, bool bAnimate/*=false*/)
{
// 		if (bAnimate) 
// 		{
// 			SetTransitionScene(scene, eTransitionScenePush);
// 			
// 			return;
// 		}

	this->BeforeDirectorPushScene(scene);

	m_scenesStack.push_back(scene);
	m_pkDirector->pushScene((CCScene *) scene->m_ccNode);

	this->AfterDirectorPushScene(scene);

	//NDLog("===============================当前场景栈大小[%u]", m_scenesStack.size());
}

bool NDDirector::PopScene(NDScene* scene/*=NULL*/, bool bAnimate/*=false*/)
{
// 		if (bAnimate && m_scenesStack.size() >= 2) 
// 		{
// 			SetTransitionScene(m_scenesStack[m_scenesStack.size()-2], eTransitionScenePop);
// 			
// 			return true;
// 		}

	return this->PopScene(true);
}

bool NDDirector::PopScene(bool cleanUp)
{
	if (m_scenesStack.size() < 2)
	{
		return false;
	}

	this->BeforeDirectorPopScene(this->GetRunningScene(), cleanUp);

	//NDLog("===============================当前场景栈大小[%u]", m_scenesStack.size());

	if (cleanUp)
	{
		delete m_scenesStack.back();
	}
	m_scenesStack.pop_back();
	m_pkDirector->popScene();

	this->AfterDirectorPopScene(cleanUp);

	//NDLog("===============================当前场景栈大小[%u]", m_scenesStack.size());

	return true;
}

void NDDirector::PurgeCachedData()
{
	// todo(zjh)
// 		NDPicturePool::PurgeDefaultPool();
// 		CCTextureCache::sharedTextureCache()->removeAllTextures();
// 		NDAnimationGroupPool::purgeDefaultPool();
}

void NDDirector::Pause()
{
	m_pkDirector->pause();
}

void NDDirector::Resume()
{
	m_pkDirector->resume();
}

void NDDirector::StopAnimation()
{
	m_pkDirector->stopAnimation();
}

void NDDirector::StartAnimation()
{
	m_pkDirector->startAnimation();
}

void NDDirector::Stop()
{
	m_pkDirector->end();

	while (m_scenesStack.begin() != m_scenesStack.end())
	{
		delete m_scenesStack.back();
		m_scenesStack.pop_back();
	}
}

bool NDDirector::isPaused()
{
	return (bool) m_pkDirector->isPaused();
}

NDScene* NDDirector::GetScene(const NDRuntimeClass* runtimeClass)
{
	for (size_t i = 0; i < m_scenesStack.size(); i++)
	{
		NDScene* scene = m_scenesStack.at(i);

		if (scene->IsKindOfClass(runtimeClass))
		{
			return scene;
		}
	}
	return NULL;
}

NDScene* NDDirector::GetRunningScene()
{
	if (m_scenesStack.size() > 0)
	{
		return m_scenesStack.back();
	}

	return NULL;
}

void NDDirector::SetDisplayFPS(bool bDisplayed)
{
	m_pkDirector->setDisplayFPS(bDisplayed);
}

CGSize NDDirector::GetWinSize()
{
	return m_pkDirector->getWinSizeInPixels();
}

void NDDirector::SetViewRect(CGRect rect, NDNode* node)
{
	if (m_TransitionSceneWait)
	{
		return;
	}

	CGSize winSize = m_pkDirector->getWinSizeInPixels();

	glEnable (GL_SCISSOR_TEST);
	//		if (m_TransitionSceneWait)
	//			glScissor(winSize.width - rect.origin.x - rect.size.width,
	//					  winSize.height - rect.origin.y - rect.size.height,
	//					  rect.size.width, rect.size.height);
	//		else
	glScissor(winSize.height - rect.origin.y - rect.size.height,
			winSize.width - rect.origin.x - rect.size.width, rect.size.height,
			rect.size.width);

	m_setViewRectNode = node;
	m_resetViewRect = true;
}

void NDDirector::ResumeViewRect(NDNode* drawingNode)
{
	if (!m_resetViewRect)
	{
		return;
	}

	if (m_setViewRectNode)
	{
		if (drawingNode == m_setViewRectNode)
		{
			return;
		}

		if (drawingNode->IsChildOf(m_setViewRectNode))
		{
			return;
		}
	}

	DisibleScissor();
}

void NDDirector::DisibleScissor()
{
	glDisable (GL_SCISSOR_TEST);
	m_setViewRectNode = NULL;
	m_resetViewRect = false;
}

void NDDirector::BeforeDirectorPopScene(NDScene* scene, bool cleanScene)
{
	std::vector<NDObject*>::iterator iter;

	for (iter = m_delegates.begin(); iter != m_delegates.end(); iter++)
	{
		NDObject* obj = (NDObject*) *iter;
		NDDirectorDelegate* delegate = dynamic_cast<NDDirectorDelegate*>(obj);

		if (delegate)
		{
			delegate->BeforeDirectorPopScene(this, scene, cleanScene);
		}
	}
}

void NDDirector::AfterDirectorPopScene(bool cleanScene)
{
	std::vector<NDObject*>::iterator iter;
	for (iter = m_delegates.begin(); iter != m_delegates.end(); iter++)
	{
		NDObject* obj = (NDObject*) *iter;
		NDDirectorDelegate* delegate = dynamic_cast<NDDirectorDelegate*>(obj);

		if (delegate)
		{
			delegate->AfterDirectorPopScene(this, cleanScene);
		}
	}
}

void NDDirector::BeforeDirectorPushScene(NDScene* scene)
{
	std::vector<NDObject*>::iterator iter;

	for (iter = m_delegates.begin(); iter != m_delegates.end(); iter++)
	{
		NDObject* obj = (NDObject*) *iter;
		NDDirectorDelegate* delegate = dynamic_cast<NDDirectorDelegate*>(obj);

		if (delegate)
		{
			delegate->BeforeDirectorPushScene(this, scene);
		}
	}
}

void NDDirector::AfterDirectorPushScene(NDScene* scene)
{
	std::vector<NDObject*>::iterator iter;

	for (iter = m_delegates.begin(); iter != m_delegates.end(); iter++)
	{
		NDObject* obj = (NDObject*) *iter;
		NDDirectorDelegate* delegate = dynamic_cast<NDDirectorDelegate*>(obj);

		if (delegate)
		{
			delegate->AfterDirectorPushScene(this, scene);
		}
	}
}

NDScene* NDDirector::GetSceneByTag(int nSceneTag)
{
	for (size_t i = 0; i < m_scenesStack.size(); i++)
	{
		NDScene* scene = m_scenesStack.at(i);
		if (scene->GetTag() == nSceneTag)
		{
			return scene;
		}
	}
	return NULL;
}

float NDDirector::GetScaleFactor()
{
	return m_pkDirector->getContentScaleFactor();
}
}
