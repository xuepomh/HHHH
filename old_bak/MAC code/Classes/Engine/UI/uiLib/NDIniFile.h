#ifndef INIFILE_HEADER_YAY
#define INIFILE_HEADER_YAY

///////////////////////////////////////
//界面编辑器导出信息
// writeby:yay
//2011-11-21
/////////////////////////////////////////

/*
用法：

CNDIniFile ini;
ini.SetPath(szFile);

//读文件
int nPosX = ini.GetValueI(szSection,szKey)
char szPath[256];
strcpy(szPath,ini.GetValue(szSection,szKey)


//写文件： 
ini.SetValue(szSection,szKey);
ini.WriteFile();

*/


#if (CC_TARGET_PLATFORM == CC_PLATFORM_WIN32)
#pragma warning(disable:4786)
#endif
 
#include <string>
#include <vector>
#include <map>
using namespace std;



class CNDIniFile  
{
protected:
	std::string m_strPath;

	struct Value 
	{
		std::string name;
		std::string value;
		std::string line;
	};
	typedef std::vector< Value >		ValueVector;
	struct Section 
	{
		std::string name;
		ValueVector vv;
	};
	typedef std::vector< Section >		SectionVector;
	SectionVector m_sections;

	typedef std::map< std::string, int > Section2Index;
	Section2Index m_section2Index;
	ValueVector::iterator FindValueVector(ValueVector& vv, const char* valuename);

public:
	int FindValue(int keynum, const char* valuename);
	int FindKey(const char* keyname);

public:
	std::string error;
public:

	CNDIniFile();
	CNDIniFile(const char* inipath);
	virtual ~CNDIniFile();

	void SetPath(const char* newpath);
	const char* GetPath() { return m_strPath.c_str(); }
	
	bool ReadFile();
	bool ReadFile(const char* newpath);
	void WriteFile();
	void Reset();

	const char* GetKeyName(int nKeyIndex);
	const char* GetValue(int  nKeyIndex, const char* sValueName);
 

	int GetKeyAmount();							// [KEY]的数量
	int GetLineAmount(const char* keyname);		// -1表示找不到KEY的错误
	int GetValueAmount(const char* keyname);	// -1表示找不到KEY的错误

	const char* GetValue(const char* keyname, const char* valuename);
	const char* GetValue(const char* keyname, std::string valuename);

	int GetValueI(const char* keyname, const char* valuename); 
	int GetValueI(const char* keyname, std::string valuename); 
	
	int GetValueI(int keyname, const char* valuename); 
	double GetValueF(const char* keyname, const char* valuename);
	const char* GetLine(const char* keyname, int idx); 

	bool SetValue(const char* key, const char* valuename, const char* value, bool create = 1);
	bool SetValueI(const char* key, const char* valuename, int value, bool create = 1);
	bool SetValueF(const char* key, const char* valuename, double value, bool create = 1);
	bool SetValueLine(const char* key, const char* valueline, bool create = 1);

 
	//helper
	void GetPos(const char* keyname, const char* valuename, int* x, int* y);
    
    bool DecryptIniFile(char *strBuf, int iBufSize);
};

#endif  