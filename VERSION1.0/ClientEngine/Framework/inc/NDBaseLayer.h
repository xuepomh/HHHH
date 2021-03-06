//
//  NDBaseLayer.h
//  DragonDrive
//
//  Created by xiezhenghai on 10-12-8.
//  Copyright 2010 (����)DeNA. All rights reserved.
//

#ifndef _ND_BASE_LAYER_H_
#define _ND_BASE_LAYER_H_

#include "CCLayer.h"
#include "NDTouch.h"
#include "NDNode.h"
#include "NDUILayer.h"
#include "NDLayer.h"


using namespace NDEngine;

class NDBaseLayer: public cocos2d::CCLayer
{
public:

	NDBaseLayer();
	~NDBaseLayer();

private:

	CAutoLink<NDUILayer> m_kUILayerNode;
	CAutoLink<NDLayer> m_kLayerNode;
	NDTouch* m_pkTouch;
	bool m_bPress;

public:

	void SetUILayer(NDUILayer* uilayer);
	void SetLayer(NDLayer* layer);
	
	virtual ND_LAYER_PRIORITY getPriority() { return E_LAYER_PRIORITY_DEFAULT; }

public:
	virtual void draw();

	void onExit();

	virtual void registerWithTouchDispatcher(void);

	virtual bool ccTouchBegan(cocos2d::CCTouch *pTouch,
			cocos2d::CCEvent *pEvent);
	virtual void ccTouchMoved(cocos2d::CCTouch *pTouch,
			cocos2d::CCEvent *pEvent);
	virtual void ccTouchEnded(cocos2d::CCTouch *pTouch,
			cocos2d::CCEvent *pEvent);

	virtual void ccTouchCancelled(cocos2d::CCTouch *pTouch,
			cocos2d::CCEvent *pEvent);
	// toto
	virtual bool ccTouchDoubleClick(cocos2d::CCTouch *pTouch,
			cocos2d::CCEvent *pEvent);
};

#endif
