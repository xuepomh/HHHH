/*
 *  UIScrollView.h
 *  SMYS
 *
 *  Created by jhzheng on 12-2-13.
 *  Copyright 2012 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef _UI_SCROLL_VIEW_MUL_HAND_ZJH_
#define _UI_SCROLL_VIEW_MUL_HAND_ZJH_

#include "NDUIScroll.h"
#include "NDUIScrollContainer.h"

using namespace NDEngine;

class CUIScrollViewM : public CUIScroll //don't scroll, only listen
{
	DECLARE_CLASS(CUIScrollViewM)
	
	CUIScrollViewM();
	~CUIScrollViewM();
	
public:
	void Initialization(bool bAccerate=false); override
	void SetScrollViewer(NDCommonProtocol* viewer);
	void SetViewId(unsigned int uiId);
	unsigned int GetViewId();
	void SetViewPos(CCPoint uiPos);
	CCPoint GetViewPos();
private:
	unsigned int				m_uiViewId;
    CCPoint                     m_uiPos;
protected:
	virtual bool OnHorizontalMove(float fDistance);
	virtual bool OnVerticalMove(float fDistance);
	virtual void OnMoveStop();
	DECLARE_AUTOLINK(CUIScrollViewM)
	INTERFACE_AUTOLINK(CUIScrollViewM)
};

/////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////
class ContainerClientLayerM : public NDUILayer
{
	DECLARE_CLASS(ContainerClientLayerM)
	
	ContainerClientLayerM();
	~ContainerClientLayerM();
	
public:
    void Initialization();
	void SetEventRect(CCRect rect);
    
    void SetViewSize(CCSize size);
	CCSize GetViewSize();
    
    void AddView(CUIScrollViewM* view);
    CUIScrollViewM* GetView(unsigned int uiIndex);
    int	GetViewCount();
    
    
	unsigned int GetIndex(){return this->m_unIndex;};
    void SetIndex(unsigned int unIndex){this->m_unIndex=unIndex;};
public:
    
	void MoveClient(float fMove);
    void AdjustView();
    void StopAdjust();
    int WhichViewToScroll();
    void ScrollView(unsigned int uiIndex, bool bImmediatelySet=false);
    
    void SetBeginIndex(unsigned int nIndex);
    void SetBeginViewIndex(unsigned int nIndex);
    
    
    virtual void SetFrameRect(CCRect rect);
    
    float GetScrollDistance(){return m_fScrollDistance;};
    
    void draw(); override
    
    virtual bool TouchMoved(NDTouch* touch); 
    virtual bool TouchEnd(NDTouch* touch);
private:
	CCRect m_rectEvent;
	UIScrollStyle			m_style;
    CCSize m_sizeView;
    
    float                   m_fScrollDistance;
    float					m_fScrollToCenterSpeed;
    unsigned int			m_unBeginIndex;
    
	unsigned int			m_unIndex;      //在父类中的索引
    
    std::vector<CUIScrollViewM*>    m_pScrollViewUINodes;
private:
	bool CanDealEvent(CCPoint pos)
	{
		return cocos2d::CCRect::CCRectContainsPoint(m_rectEvent, pos);
	}
	
protected:
    
    
	virtual bool TouchBegin(NDTouch* touch)
	{
		if (!this->IsVisibled())
		{
			return false;
		}

		if (CanDealEvent(touch->GetLocation()))
		{
           if(m_pScrollViewUINodes.size() == 0 && this->GetFrameRect().origin.x == 0)
			{
               return true;
           }
			return NDUILayer::TouchBegin(touch);
		}
		return false;
	}
    
    
    
    
    
	virtual bool DispatchLongTouchClickEvent(CCPoint beginTouch, CCPoint endTouch)
	{
		if (CanDealEvent(endTouch))
		{
			return NDUILayer::DispatchLongTouchClickEvent(beginTouch, endTouch);
		}
		return false;
	}
	
	virtual bool DispatchLongTouchEvent(CCPoint beginTouch, bool touch)
	{
		if (CanDealEvent(beginTouch))
		{
			return NDUILayer::DispatchLongTouchEvent(beginTouch, touch);
		}
		return false;
	}
	
	virtual bool DispatchDragOutEvent(CCPoint beginTouch, CCPoint moveTouch, bool longTouch=false)
	{
		if (CanDealEvent(moveTouch))
		{
			return NDUILayer::DispatchDragOutEvent(beginTouch, moveTouch, longTouch);
		}
		return false;
	}
	
	virtual bool DispatchDragInEvent(NDUINode* dragOutNode, CCPoint beginTouch, CCPoint endTouch, bool longTouch, bool dealByDefault=false)
	{
		if (CanDealEvent(endTouch))
		{
			return NDUILayer::DispatchDragInEvent(dragOutNode, beginTouch, endTouch, longTouch, dealByDefault);
		}
		return false;
	}
    
    
    
    
};


class CUIScrollViewContainerM : public NDUIScrollContainer
{
	DECLARE_CLASS(CUIScrollViewContainerM)
	
	CUIScrollViewContainerM();
	~CUIScrollViewContainerM();
	
public:
	void Initialization(); override
	void SetStyle(int style);
	UIScrollStyle GetScrollStyle();
	
	void SetCenterAdjust(bool bSet);
	bool IsCenterAdjust();
	
	int	GetViewCount();
	void SetViewSize(CCSize size);
	CCSize GetViewSize();
	void AddView(ContainerClientLayerM* container);
	//void ReplaceView(unsigned int uiIndex, CUIScrollViewM* view);
	//void ReplaceViewById(unsigned int uiViewId, CUIScrollViewM* view);
	void RemoveView(unsigned int uiIndex);
	void RemoveViewById(unsigned int uiViewId);
	void RemoveAllView();
	//void InsertView(unsigned int uiIndex, CUIScrollViewM* view);
	void ShowViewByIndex(unsigned int uiIndex);
	void ShowViewById(unsigned int uiViewId);
	void ScrollViewByIndex(unsigned int uiIndex);
	void ScrollViewById(unsigned int uiViewId);
	ContainerClientLayerM* GetView(unsigned int uiIndex);
	CUIScrollViewM* GetViewById(unsigned int uiViewId);
	CUIScrollViewM* GetBeginView();
	unsigned int GetBeginIndex();
    void EnableScrollBar(bool bEnable)
    {
        NDUIScrollContainer::EnableScrollBar(bEnable);
    }
	
private:
	float					m_fScrollDistance;
	float					m_fScrollToCenterSpeed;
	bool					m_bIsViewScrolling;
	UIScrollStyle			m_style;
	
    std::vector<ContainerClientLayerM*>    m_pClientUINodes;
    
    //ContainerClientLayerM*	m_pClientUINode; // all view's parent
	CCSize					m_sizeView;
    unsigned int			m_unPreIndex;
	unsigned int			m_unBeginIndex;
	bool					m_bCenterAdjust;
	bool					m_bRecaclClientEventRect;
	CAutoLink<CUIScrollViewM> m_linkCurView;
	
private:
	bool CheckView(CUIScrollViewM* view);
	unsigned int ViewIndex(unsigned int uiViewId);
	
	void AdjustView();
	int WhichViewToScroll();
	void ScrollView(unsigned int uiIndex, bool bImmediatelySet=false);
	bool CaclViewCenter(CUIScrollViewM* view, float& fCenter, bool bJudeOver=false);
	CCRect GetClientRect(bool judgeOver);
	float GetContainerCenter();
	float GetViewLen();
    
    //** chh 2012-06-25 **//
    CCPoint GetMaxRowAndCol(ContainerClientLayerM* m_pClientUINode);
    
	void StopAdjust();
    void MoveClient(float fMove);
    
    
	void refrehClientSize();
	bool IsViewScrolling();
	void EnableViewToScroll(bool bEnable);
	void SetBeginViewIndex(unsigned int nIndex);
	unsigned int GetPerPageViews();
	//bool IsViewCanCenter();
	void SetBeginIndex(unsigned int nIndex);
	
	float GetAdjustCenter();
	float GetOverDistance();
	
	
	
    void SetDShowYPos(bool bIsAllShow = true);
public:
	void draw(); override
	void SetFrameRect(CCRect rect); override
	// CommonProtol
	void OnScrollViewMove(NDObject* object, float fVertical, float fHorizontal); override
	void OnScrollViewScrollMoveStop(NDObject* object); override
	bool CanHorizontalMove(NDObject* object, float& hDistance); override
	bool CanVerticalMove(NDObject* object, float& vDistance); override
	
    void DrawScrollBar(ContainerClientLayerM *layer);
protected:
	bool CanDestroyOnRemoveAllChildren(NDNode* pNode);override
    
    virtual bool TouchMoved(NDTouch* touch); 
    virtual bool TouchEnd(NDTouch* touch);
};

#endif // _UI_SCROLL_VIEW_ZJH_