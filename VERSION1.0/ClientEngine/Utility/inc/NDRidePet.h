/*
*
*/

#ifndef NDRIDEPET_H
#define NDRIDEPET_H

#include "platform.h"
#include <cocos2d.h>
#include "NDSprite.h"
#include "..\..\..\ClientLogic\MapAndRole\inc\NDBaseRole.h"

using namespace cocos2d;

namespace NDEngine
{
	enum 
	{
		TYPE_RIDE = 0,//骑马
		TYPE_RIDE_BIRD = 1,
		TYPE_STAND = 2,
		TYPE_RIDE_FLY = 3,
		TYPE_RIDE_YFSH= 4,
		TYPE_RIDE_QL= 5,
	};

	class NDRidePet:public NDSprite
	{
	public:

		NDRidePet();
		virtual ~NDRidePet();

		//以下方法供逻辑层使用－－－begin
		//......	
		void Initialization(int lookface);

		void WalkToPosition(CGPoint toPos);

		void OnMoveEnd();

		void SetPosition(CGPoint newPosition);
		void SetPositionEx(CGPoint pos);

		void OnMoveTurning(bool bXTurnigToY, bool bInc);

	//	void SetOwner(NDBaseRole* role);

		bool IsOwnerPlayer();

		int iType;
		int quality;

	protected:
	private:
	};
}

#endif