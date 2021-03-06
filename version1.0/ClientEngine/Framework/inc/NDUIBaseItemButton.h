/*
*
*/

#ifndef NDUIBASEITEMBUTTON_H
#define NDUIBASEITEMBUTTON_H

#include "define.h"
#include "NDObject.h"
#include "NDPicture.h"
#include "NDUINode.h"

NS_NDENGINE_BGN

class NDUIBaseItemButton:public NDUINode
{
	DECLARE_CLASS(NDUIBaseItemButton)

public:

	NDUIBaseItemButton();
	virtual ~NDUIBaseItemButton();

	virtual void InitializationItem();
	virtual void SetItemFrameRect(cocos2d::CCRect rect);
	virtual void CloseItemFrame();
	virtual void SetItemBackgroundPicture(NDPicture *pic, NDPicture *touchPic = NULL,
		bool useCustomRect = false, cocos2d::CCRect customRect = cocos2d::CCRectZero, bool clearPicOnFree = false);
	virtual void SetItemBackgroundPictureCustom(NDPicture *pic, NDPicture *touchPic = NULL,
                                                bool useCustomRect = false, cocos2d::CCRect customRect = CCRectZero);

	virtual void SetItemTouchDownImage(NDPicture *pic, bool useCustomRect = false, cocos2d::CCRect customRect = CCRectZero, bool clearPicOnFree = false);
	virtual void SetItemTouchDownImageCustom(NDPicture *pic, bool useCustomRect = false, cocos2d::CCRect customRect = CCRectZero);

	virtual void SetItemFocusImage(NDPicture *pic, bool useCustomRect = false, cocos2d::CCRect customRect = CCRectZero, bool clearPicOnFree = false);
	virtual void SetItemFocusImageCustom(NDPicture *pic, bool useCustomRect = false, cocos2d::CCRect customRect = CCRectZero);

	virtual void SetLock(bool bSet);
	virtual bool IsLock();

	virtual void ChangeItem(unsigned int unItemId);
	virtual unsigned int GetItemId();

	virtual void ChangeItemType(unsigned int unItemType);
	virtual unsigned int GetItemType();

	virtual void RefreshItemCount();
	virtual unsigned int GetItemCount();

	virtual void SetShowAdapt(bool bShowAdapt);
	virtual bool IsShowAdapt();

protected:
private:
};

NS_NDENGINE_END

#endif