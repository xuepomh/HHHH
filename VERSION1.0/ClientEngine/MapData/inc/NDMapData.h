//
//  NDMapData.h
//  MapData
//
//  Created by jhzheng on 10-12-10.
//  Copyright 2010 (网龙)DeNA. All rights reserved.
//

#ifndef _ND_MAP_DATA_
#define _ND_MAP_DATA_

#include "NDTile.h"
#include "NDUILabel.h"
#include "UsePointPls.h"
#include "cocoa/CCDictionary.h"

class MapTexturePool: public cocos2d::CCObject
{
public:

	static MapTexturePool* defaultPool();
	void purgeDefaultPool();

	cocos2d::CCTexture2D* addImage(const char* path, bool keep);

private:
	cocos2d::CCDictionary*	m_pkDict;

private:
	MapTexturePool();
public:
	~MapTexturePool();
};

class NDMapData;
//切屏点
class NDMapSwitch: public cocos2d::CCObject
{
	CC_SYNTHESIZE(int, m_nX, X)
	CC_SYNTHESIZE(int, m_nY, Y)
	CC_SYNTHESIZE(int, m_nMapIndex, MapIndex)
	CC_SYNTHESIZE(int, m_nPassIndex, PassIndex)
	CC_SYNTHESIZE(std::string, m_strNameDesMap, NameDesMap)
	CC_SYNTHESIZE(std::string, m_strDescDesMap, DescDesMap)

public:
	NDMapSwitch();
	~NDMapSwitch();

	void SetLabel(NDMapData* mapdata);
	void SetLabelNew(NDMapData* pkMapdata);
	void SetLableByType(int eLableType, int x, int y, const char* pszText,
			cocos2d::ccColor4B color1, cocos2d::ccColor4B color2,
			CCSize kParentSize);
	void draw();

private:

	NDEngine::NDUILabel* m_pkNameLabels[2];
	NDEngine::NDUILabel* m_pkDesLabels[2];
};

//布景
class NDSceneTile: public NDTile
{
	CC_SYNTHESIZE(int, m_nOrderID, OrderID)

public:
	NDSceneTile();
	~NDSceneTile()
	{
	}
};

//刷怪区
class NDMapMonsterRange: public cocos2d::CCObject
{
	CC_SYNTHESIZE(int, m_nTypeId, TypeId)
	CC_SYNTHESIZE(int, m_nColumn, Column)
	CC_SYNTHESIZE(int, m_nRow, Row)
	CC_SYNTHESIZE(bool, m_bBoss, Boss)

public:
	NDMapMonsterRange();
};

class anigroup_param: public cocos2d::CCObject,
		public std::map<std::string, int>
{
};

class NDMapData: public cocos2d::CCObject
{
public:
	CC_SYNTHESIZE(bool, m_bBattleMapFlag, BattleMapFlag)
	CC_SYNTHESIZE(bool, m_bDramaMapFlag, DramaMapFlag)
	CC_SYNTHESIZE(std::string, m_strName, Name)
	CC_SYNTHESIZE(int, m_nLayerCount, LayerCount)
	CC_SYNTHESIZE(unsigned int, m_nColumns, Columns)
	CC_SYNTHESIZE(unsigned int, m_nRows, Rows)
	//CC_SYNTHESIZE(int, m_nUnitSize, UnitSize) //分辨率相关，非固定值
	CC_SYNTHESIZE(unsigned int, m_nRoadBlockX, RoadBlockX)
	CC_SYNTHESIZE(unsigned int, m_nRoadBlockY, RoadBlockY)

	CC_SYNTHESIZE_READONLY(CCArray*, m_kMapTiles, MapTiles)
	CC_SYNTHESIZE(std::vector<bool>*, m_pkObstacles, Obstacles)
	CC_SYNTHESIZE(cocos2d::CCArray*, m_pkSceneTiles, SceneTiles)
	CC_SYNTHESIZE(cocos2d::CCArray*, m_pkBackgroundTiles, BgTiles)
	CC_SYNTHESIZE(cocos2d::CCArray*, m_pkSwitchs, Switchs)
	CC_SYNTHESIZE_READONLY(cocos2d::CCArray*, m_pkAnimationGroups, AnimationGroups)
	CC_SYNTHESIZE(cocos2d::CCArray*, m_pkAniGroupParams, AniGroupParams)

public:
	NDMapData();
	~NDMapData();

	/*通过地图文件(不包含路径)加载地图数据
	 参数:mapFile-地图文件名
	 */
	void initWithFile(const char* mapFile);

	/*判断某个位置是否可走
	 参数:row-某行,column-某列
	 返回值:YES/NO
	 */
	bool canPassByRow(unsigned int row, unsigned int column);

	//CustomCCTexture2D * getTileAtRow(unsigned int row, unsigned int column);

	NDSceneTile * getBackGroundTile(unsigned int index);

	void moveBackGround(int x, int y);

	void addObstacleCell(unsigned int row, unsigned int column);
	void removeObstacleCell(unsigned int row, unsigned int column);
	void addMapSwitch(unsigned int x,			// 切屏点 x
			unsigned int y,			// 切屏点 y
			unsigned int index,		// 切屏点索引
			unsigned int mapid,		// 目标地图id
			const char* name,	// 目标地图名称
			const char* desc);	// 目标地图描述
	void setRoadBlock(int x, int y);

	CCSize getMapDataSize() const
	{
		return CCSizeMake(
			this->getColumns() * MAP_UNITSIZE_X,
			this->getRows() * MAP_UNITSIZE_Y
			);
	}
private:
	void decode(FILE* pkStream);
};
#endif
