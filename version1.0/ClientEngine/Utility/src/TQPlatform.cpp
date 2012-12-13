/*
 *  platform.cpp
 *  SMYS
 *
 *  Created by jhzheng on 12-5-07.
 *  Copyright 2012 (����)DeNA. All rights reserved.
 *
 */

#include "TQPlatform.h"
#include "CCImage.h"
#include "CCGeometry.h"
#include "basedefine.h"


#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
#import "Foundation/Foundation.h"
#import "UIKit/UIFont.h"
#import "UIKit/UIStringDrawing.h"
#endif
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
#include <jni.h>
#include "platform/android/jni/JniHelper.h"
#endif
using namespace cocos2d;

#if (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32) || (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
static char g_GBKConvUTF8Buf_Again[5000] = {0};
const char* GBKToUTF8(const char *strChar)
{

	iconv_t iconvH;
	iconvH = iconv_open("utf-8","gb2312");
	if (iconvH == 0)
	{
		return NULL;
	}
	size_t strLength = strlen(strChar);
	size_t outLength = strLength<<2;
	size_t copyLength = outLength;
	memset(g_GBKConvUTF8Buf_Again, 0, 5000);

	char* outbuf = (char*) malloc(outLength);
	char* pBuff = outbuf;
	memset( outbuf, 0, outLength);

	if (-1 == iconv(iconvH, &strChar, &strLength, &outbuf, &outLength))
	{
		iconv_close(iconvH);
		return NULL;
	}
	memcpy(g_GBKConvUTF8Buf_Again,pBuff,copyLength);
	free(pBuff);
	iconv_close(iconvH);
	return g_GBKConvUTF8Buf_Again;
}
#endif

CCSize getStringSize(const char* pszStr, unsigned int fontSize)
{
    CCSize CCSz = CCSizeMake(0.0f, 0.0f);

	if (pszStr) {
#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
        CGSize sz = CGSizeMake(0.0f, 0.0f);
		NSString* str = [NSString stringWithUTF8String:pszStr];	
        NSString* strfont = [NSString stringWithUTF8String:FONT_NAME];
		sz = [str sizeWithFont:[UIFont fontWithName:strfont size:fontSize]];
        CCSz.width = sz.width;
        CCSz.height = sz.height;
#elif (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32) || (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
		int width = 0, height = 0;
		if (CCImage::getStringSize( pszStr, CCImage::kAlignLeft, FONT_NAME, fontSize,
										width, height ))
		{
			return CCSizeMake( width, height );
		}
#endif
	}
    
	return CCSz;     
}

CCSize getStringSizeMutiLine(const char* pszStr, unsigned int fontSize, CCSize contentSize)
{


	CGSize sz = CGSizeZero;
	CCSize CCSz = CCSizeZero;
    
    CGSize CGcontentSize = CGSizeZero;
    CGcontentSize.width = contentSize.width;
    CGcontentSize.height = contentSize.height;

	if (!pszStr)
	{
		return CCSz;
	}

#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
	NSString *nstext = [NSString stringWithUTF8String:pszStr];
    NSString* strfont = [NSString stringWithUTF8String:FONT_NAME];
	sz = [nstext sizeWithFont:[UIFont fontWithName:strfont size:fontSize] constrainedToSize:CGcontentSize];
#elif (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32) || (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
	int width = 0, height = 0;
	if (CCImage::getStringSize( pszStr, CCImage::kAlignLeft, FONT_NAME, fontSize,
		width, height ))
	{
		int rows = 1.0*width/contentSize.width + 1;

		if(1 == rows)
		{
			sz.width = width;
			if(contentSize.height > height)
			{
				sz.height =  height;
			}
			else
			{
				sz.height =  contentSize.height;
			}
		}
		else
		{
			sz.width = contentSize.width;
			if(contentSize.height > height*rows)
			{
				sz.height =  height*rows;
			}
			else
			{
				sz.height =  contentSize.height;
			}
		}
	}
#endif
    CCSz.width = sz.width;
    CCSz.height = sz.height;
	return CCSz;
}
