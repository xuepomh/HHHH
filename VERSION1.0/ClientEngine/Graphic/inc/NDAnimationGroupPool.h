//
//  NDAnimationGroupPool.h
//  DragonDrive
//
//  Created by xiezhenghai on 10-12-9.
//  Copyright 2010 (����)DeNA. All rights reserved.
//

#ifndef _ND_ANIMATION_GROUP_POOL_H_
#define _ND_ANIMATION_GROUP_POOL_H_

#include "NDAnimationGroup.h"
#include "cocoa/CCDictionary.h"

class NDAnimationGroupPool: public cocos2d::CCObject
{
public:

	~NDAnimationGroupPool();

	static NDAnimationGroupPool* defaultPool();
	static void purgeDefaultPool();

	NDAnimationGroup* addObjectWithSpr(const char*sprFile);
	NDAnimationGroup* addObjectWithSceneAnimationId(int nSceneAnimationId);
	NDAnimationGroup* addObjectWithModelId(int ModelId);

	void removeObjectWithSpr(const char* sprFile);
	void removeObjectWithSceneAnimationId(int SceneAnimationId);
	void Recyle();

private:

	NDAnimationGroupPool();

	cocos2d::CCDictionary* m_pkAnimationGroups;
};

#endif
