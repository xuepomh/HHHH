//
//  NDLayer.h
//  DragonDrive
//
//  Created by xiezhenghai on 10-12-8.
//  Copyright 2010 (网龙)DeNA. All rights reserved.
//
//	－－介绍－－
//	层是游戏的重点，游戏中大多的时间花在层上。
//	层的显示：
//		后添加的层将会覆盖先前添加的层，
//		如果层时透明、或者半透明，则底部的层将会显示或者部分显示。
//	层的事件响应：
//		最上面的层最先接收到系统事件(如：手指点击屏幕事件)，
//		如果事件被处理了则屏蔽事件的分发，否则将往下面的层进行分发事件，直到事件被屏蔽为止。

#ifndef __NDLAYER_H
#define __NDLAYER_H

#include "NDNode.h"
#include "NDTouch.h"
#include <string>

NS_NDENGINE_BGN

class NDLayer: public NDNode
{
DECLARE_CLASS(NDLayer)
public:
	NDLayer();
	~NDLayer();

public:

	static NDLayer* Layer();

	void Initialization();
	void draw();

	void SetTouchEnabled(bool bEnabled);

	virtual bool TouchBegin(NDTouch* touch);
	virtual void TouchEnd(NDTouch* touch);
	virtual void TouchCancelled(NDTouch* touch);
	virtual void TouchMoved(NDTouch* touch);
	virtual bool TouchDoubleClick(NDTouch* touch);
	
	virtual ND_LAYER_PRIORITY getPriority() { return E_LAYER_PRIORITY_DEFAULT; } //@priority

DECLARE_AUTOLINK(NDLayer)
INTERFACE_AUTOLINK(NDLayer)
};

NS_NDENGINE_END
#endif //__NDLAYER_H