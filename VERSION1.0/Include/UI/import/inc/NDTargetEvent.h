/*
 *  NDTargetEvent.h
 *  DragonDrive
 *
 *  Created by jhzheng on 11-12-15.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#pragma once

enum TARGET_EVENT
{
	TE_NONE = 0,
	
	// 按钮事件
	TE_TOUCH_BTN_CLICK = 1,
	
	TE_TOUCH_BTN_DRAG_OUT = 2,
	
	TE_TOUCH_BTN_DRAG_OUT_COMPLETE = 3,
	
	TE_TOUCH_BTN_DRAG_IN = 4,
	
	//滚动层某个视图跑到容器起始处(参数为视图索引)
	TE_TOUCH_SC_VIEW_IN_BEGIN = 5,
	
	//checkbox状态发生改变
	TE_TOUCH_CHECK_CLICK = 6,
	
	//RadioGroup选项发生改变
	TE_TOUCH_RADIO_GROUP = 7,
	
	//edit事件
	TE_TOUCH_EDIT_RETURN = 8,
	TE_TOUCH_EDIT_TEXT_CHANGE = 9,
	TE_TOUCH_EDIT_INPUT_FINISH =10,
	
	//按钮双击
	TE_TOUCH_BTN_DOUBLE_CLICK = 11,
	// ...
	TE_END,
};