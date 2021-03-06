//
//  NDPicture.h
//  DragonDrive
//
//  Created by xiezhenghai on 11-1-8.
//  Copyright 2011 (网龙)DeNA. All rights reserved.
//
//	－－介绍－－
//	NDPicture是专门针对本地图片的操作
//	如果需要共享图片资源可以通过NDPicturePool获取NDPicture对象

#ifndef __NDPicture_H
#define __NDPicture_H

#include "NDObject.h"
#include "NDDictionary.h"
#include "CCTexture2D.h"
#include "ccTypes.h"
#include "shaders/ccGLStateCache.h"
#include "shaders/ccGLProgram.h"
#include <vector>
#include <map>

using namespace cocos2d;
using namespace std;

NS_NDENGINE_BGN

typedef enum
{
	PictureRotation0,
	PictureRotation90,
	PictureRotation180,
	PictureRotation270
} PictureRotation;

typedef enum
{
	ContainerTypeNormal,
	ContainerTypeAddPic,
	ContainerTypeAddTexture
}ContainerTypeOfTexture;

class NDTexture:public NDObject
{
	DECLARE_CLASS(NDTexture);
public:

	NDTexture();
	virtual ~NDTexture();

	virtual void Initialization(const char* pszImageFile);

	CC_SYNTHESIZE_READONLY(CCTexture2D*,m_pkTexture,Texture);
	
	CCTexture2D* GetTextureRetain();

protected:
private:
};

class NDPicture: public NDObject
{
	DECLARE_CLASS (NDPicture)
	NDPicture(bool canGray = false);
	~NDPicture();
public:

	void Initialization(const char* imageFile);
	void Initialization(vector<const char*>& vImgFiles);
	void Initialization(vector<const char*>& vImgFiles, vector<CCRect>& vImgCustomRect, vector<CCPoint>&vOffsetPoint);
	void Initialization(const char* imageFile, int hrizontalPixel,
			int verticalPixel = 0);

	void Cut(CCRect kRect);

	void SetReverse(bool reverse);

	void Rotation(PictureRotation rotation);

	void SetColor(cocos2d::ccColor4B color);

	void DrawInRect(CCRect kRect);

	CCSize GetSize();

	NDPicture* Copy();

	bool SetGrayState(bool gray);

	bool IsGrayState();
	//void SetScale(float fScale);
	CC_SYNTHESIZE(float,m_fScale,Scale);
	CC_SYNTHESIZE(bool,m_bIsTran,IsTran);

public:
	cocos2d::CCTexture2D *GetTexture();

	void SetTexture(cocos2d::CCTexture2D* tex);

public: //@shader
	CC_SYNTHESIZE_RETAIN(CCGLProgram*, m_pShaderProgram, ShaderProgram);
	CC_SYNTHESIZE(ccGLServerState, m_glServerState, GLServerState);
protected:
	void DrawSetup( const char* shaderType = kCCShader_PositionTexture_uColor );
	virtual void debugDraw();

private:
	//float m_fScale;
	cocos2d::CCTexture2D* m_pkTexture;
	CCRect m_kCutRect;
	bool m_bReverse;
	bool m_bAdvance;
	PictureRotation m_kRotation;

	// 变灰
	bool m_bCanGray;
	bool m_bStateGray;
	cocos2d::CCTexture2D *m_pkTextureGray;

	GLfloat m_coordinates[8];
	GLubyte m_colors[16];
	GLfloat m_pfVertices[8];

	std::string m_strfile;
	int m_hrizontalPixel;
	int m_verticalPixel;

	void SetCoorinates();
	void SetVertices(CCRect drawRect);
};

class NDPictureDictionary: public NDDictionary
{
public:
	NDPictureDictionary();
	~NDPictureDictionary();
	DECLARE_CLASS (NDPictureDictionary)
public:
	void Recyle();
};

class NDPicturePool: public NDObject
{
	DECLARE_CLASS (NDPicturePool)
	NDPicturePool();
	~NDPicturePool();

public:

	typedef map<CCTexture2D*,string> MAP_STRING;

	static NDPicturePool* DefaultPool();

	static void PurgeDefaultPool();

#if 1  // for simple use
	NDPicture* AddPicture(const string& imageFile, bool gray = false) {
		return AddPicture(imageFile.c_str(), gray);
	}

	NDPicture* AddPicture(const string& imageFile, int hrizontalPixel, int verticalPixel = 0, bool gray = false) {
		return 	AddPicture(imageFile.c_str(), hrizontalPixel, verticalPixel, gray );
	}
#endif 

	NDPicture* AddPicture(const char* imageFile, bool gray = false);
	NDPicture* AddPicture(const char* imageFile, int hrizontalPixel,
			int verticalPixel = 0, bool gray = false);
	CCTexture2D* AddTexture(const char* pszImageFile);
	void RemoveTexture(CCTexture2D* tex);
	void RemovePicture(const char* imageFile);

	void Recyle();

private:

	NDPictureDictionary* m_pkTextures;

	std::map<std::string, CCSize> m_mapStr2Size;
	MAP_STRING m_mapTex2Str;

private:
	CCSize GetImageSize(std::string filename);
};

NS_NDENGINE_END

#endif
