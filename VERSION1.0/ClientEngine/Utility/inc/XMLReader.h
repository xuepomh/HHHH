/*
*
*/

#ifndef XMLREADER_H
#define XMLREADER_H

#include <cocos2d.h>
#include <map>
#include <vector>
#include "..\..\TinyXML\tinyxml.h"

using namespace cocos2d;
using namespace std;

class XMLReader
{
public:

	XMLReader();
	virtual ~XMLReader();

	bool initWithFile(const char* pszFilename);
	bool initWithData(const char* pszData,int nSize);
	void* getObjectWithPath(string strPath,int* pnIndexArray,int nArraySize);

protected:

private:
};

#endif