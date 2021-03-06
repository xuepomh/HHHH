/*
 *  TaskInfoScene.mm
 *  DragonDrive
 *
 *  Created by jhzheng on 11-12-14.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include "TaskInfoScene.h"

#include "NDDirector.h"
#include "CGPointExtension.h"
#include "NDUtility.h"
#include "NewPlayerTask.h"
#include "NDMsgDefine.h"
#include "NDUISynLayer.h"

enum 
{
	eTaskInfoBegin = 0,
	eTaskInfoJuQing = eTaskInfoBegin,
	eTaskInfoDaily,
	eTaskInfoChengZhang,
	eTaskInfoHuoDong,
	eTaskInfoSiShi,
	eTaskInfoEnd,
};

const char * title[eTaskInfoEnd] = 
{
	NDCommonCString("JuQing"),
	NDCommonCString("daily"),
	NDCommonCString("grow"),
	NDCommonCString("active"),
	NDCommonCString("sishi"),
};

IMPLEMENT_CLASS(TaskInfoScene, NDCommonScene)

TaskInfoScene* TaskInfoScene::s_instance = NULL;

TaskInfoScene* TaskInfoScene::Scene()
{
	TaskInfoScene *scene = new TaskInfoScene;
	
	scene->Initialization();
	
	return scene;
}

TaskInfoScene::TaskInfoScene()
{
	m_hasGetCanAcceptTask = false;

	s_instance = this;
}

TaskInfoScene::~TaskInfoScene()
{
	s_instance = NULL;
}

void TaskInfoScene::Initialization()
{
	NDCommonScene::Initialization();
	
	NDPicturePool& pool = *(NDPicturePool::DefaultPool());
	
	for (int i = eTaskInfoBegin; i < eTaskInfoEnd; i++) 
	{
		TabNode* tabnode = this->AddTabNode();
		
		tabnode->SetImage(pool.AddPicture(GetImgPathNew("newui_tab_unsel.png"), 70, 31), 
						  pool.AddPicture(GetImgPathNew("newui_tab_sel.png"), 70, 34),
						  pool.AddPicture(GetImgPathNew("newui_tab_selarrow.png")));
		
		tabnode->SetText(title[i]);
		
		tabnode->SetTextColor(ccc4(245, 226, 169, 255));
		
		tabnode->SetFocusColor(ccc4(173, 70, 25, 255));
		
		tabnode->SetTextFontSize(18);
	}
	
	for (int i = eTaskInfoBegin; i < eTaskInfoEnd; i++) 
	{
		CGSize winsize = NDDirector::DefaultDirector()->GetWinSize();
		
		NDUIClientLayer* client = this->GetClientLayer(i);
		
		if (i == eTaskInfoJuQing)
		{
			InitTask(client);
			
			continue;
		}
		
		int taskType = 0;
		
		switch (i) {
			case eTaskInfoDaily:
				taskType = Task::TASK_DAILY;
				break;
			case eTaskInfoSiShi:
				taskType = Task::TASK_SISHI;
				break;
			case eTaskInfoChengZhang:
				taskType = Task::TASK_GROW;
				break;
			case eTaskInfoHuoDong:
				taskType = Task::TASK_ACTIVITY;
				break;
			default:
				break;
		}
		
		if (taskType != 0)
			InitDailyTask(client, taskType);
	}
	
	this->SetTabFocusOnIndex(eTaskInfoJuQing, true);
}

void TaskInfoScene::OnButtonClick(NDUIButton* button)
{
	if (OnBaseButtonClick(button)) return;
}

void TaskInfoScene::OnTabLayerSelect(TabLayer* tab, unsigned int lastIndex, unsigned int curIndex)
{
	NDCommonScene::OnTabLayerSelect(tab, lastIndex, curIndex);
	
	if (!m_hasGetCanAcceptTask && curIndex == (unsigned int)eTaskInfoJuQing) 
	{
		NDTransData bao(_MSG_QUERY_TASK_LIST_EX);
		bao << (unsigned char)0 << int(0);
		SEND_DATA(bao);
		ShowProgressBar;
		
		m_hasGetCanAcceptTask = true;
	}
}

void TaskInfoScene::InitTask(NDUIClientLayer* client)
{
	if (!client) return;
	
	CGSize sizeClient = client->GetFrameRect().size;
	NDFuncTab *tab = new NDFuncTab;
	tab->Initialization(2, CGPointMake(200, 5));
	
	for(int j =0; j<2; j++)
	{
		TabNode* tabnode = tab->GetTabNode(j);
		
		NDPicture *pic = NDPicturePool::DefaultPool()->AddPicture(GetImgPathNew("newui_text.png"));
		NDPicture *picFocus = NDPicturePool::DefaultPool()->AddPicture(GetImgPathNew("newui_text.png"));
		
		int startX = (j == 0 ? 18*7 : 18*6);
		
		pic->Cut(CGRectMake(startX, 36, 18, 36));
		picFocus->Cut(CGRectMake(startX, 0, 18, 36));
		
		tabnode->SetTextPicture(pic, picFocus);
	}
	
	NewPlayerTask *task = new NewPlayerTask;
	task->Initialization();
	task->SetFrameRect(CGRectMake(0, 0, 200, sizeClient.height));
	client->AddChild(task);
	tab->SetDelegate(task);
	task->AddYiJie(tab->GetClientLayer(0));
	task->AddKeJie(tab->GetClientLayer(1));
	
	client->AddChild(tab);
}

void TaskInfoScene::InitDailyTask(NDUIClientLayer* client, int taskType)
{
	if (!client) return;
	
	CGSize sizeClient = client->GetFrameRect().size;
	
	DailyTask *task = new DailyTask();
	task->Initialization(taskType);
	task->SetFrameRect(CGRectMake(0, 0, sizeClient.width, sizeClient.height));
	client->AddChild(task);
	
	m_vDailyTask.push_back(task);
}

void TaskInfoScene::refresh()
{
	// 日常任务刷新
	for_vec(m_vDailyTask, std::vector<DailyTask*>::iterator)
	{
		(*it)->refresh();
	}
}

void TaskInfoScene::refreshTask()
{
	if (!s_instance) return;
	
	s_instance->refresh();
}
