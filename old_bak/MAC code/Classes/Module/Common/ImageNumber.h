//
//  PictureNumber.h
//  DragonDrive
//
//  Created by xiezhenghai on 11-1-19.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#ifndef __ImageNumber_H
#define __ImageNumber_H

#include "NDUIImage.h"
#include "NDPicture.h"
#include "NDUILayer.h"
#include <vector>

using namespace NDEngine;

class PictureNumber
{
	PictureNumber();
	~PictureNumber();
public:
	static PictureNumber* SharedInstance();
	//number must between 0 and 9
	NDPicture* TitleGoldNumber(unsigned int number);
	CGSize GetTitleGoldNumberSize();
	
	NDPicture* TitleRedNumber(unsigned int number);
	CGSize GetTitleRedNumberSize();
	
	NDPicture* TitleSplit();
	CGSize GetTitleSplitSize();
	
	// 0 ~ 9 / + -
	NDPicture* BigRed(unsigned int index);
	NDPicture* BigGreen(unsigned int index);
	NDPicture* SmallWhite(unsigned int index);
	NDPicture* SmallRed(unsigned int index);
	NDPicture* SmallGreen(unsigned int index);
	NDPicture* SmallGold(unsigned int index);
	CGSize GetBigRedSize();
	CGSize GetSmallWhiteSize();
	CGSize GetSmallRedSize();
	CGSize GetSmallGoldSize();
	
private:
	NDPicture* m_picTitleGlod[10];
	NDPicture* m_picTitleRed[10];
	NDPicture* m_picSmallGold[10];
	NDPicture* m_picTitleSplit;
	// 0 ~ 9 / + -
	NDPicture* m_picBigRed[13];
	// 0 ~ 9 / + -
	NDPicture* m_picBigGreen[13];
	// 0 ~ 9 / + -
	NDPicture* m_picSmallWhite[13];
	NDPicture* m_picSmallRed[13];
	NDPicture* m_picSmallGreen[13];
};

class ImageNumber : public NDUILayer
{
	DECLARE_CLASS(ImageNumber)
	ImageNumber();
	~ImageNumber();
public:
	void SetTitleRedNumber(unsigned int number, unsigned int interval = 0);
	void SetTitleRedTwoNumber(unsigned int number1, unsigned int number2, unsigned int interval = 0);
	
	void SetBigRedNumber(int number, bool bWithSign = false);
	void SetBigRedTwoNumber(int number1, int number2);
	
	void SetBigGreenNumber(int number, bool bWithSign = false);
	void SetSmallGreenNumber(int number, bool bWithSign = false);
	void SetSmallWhiteNumber(int number, bool bWithSign = false);
	void SetSmallRedNumber(int number, bool bWithSign = false);
	void SetSmallRedTwoNumber(uint num1, uint num2);
	void SetSmallGoldNumber(int num);
	
	void Initialization(); override
	CGSize GetNumberSize();
	
private:
	CGSize m_size;
	void NumberBits(unsigned int number, /*out*/std::vector<unsigned int>& bits);
	unsigned int exp(unsigned int value, unsigned int n);
	unsigned int SetTitleRedNumber(bool cleanUp, unsigned int number, unsigned int interval, unsigned int startPos);
};


#endif