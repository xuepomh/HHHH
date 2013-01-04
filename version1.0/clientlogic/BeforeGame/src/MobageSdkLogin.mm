/*
 *  NDSdkLogin.mm
 *  DragonDrive
 *
 *  Created by jhzheng on 11-11-14.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#import "MobageSdkLogin.h"
#import "ScriptGlobalEvent.h"
#import "NDDirector.h"
#include "ScriptMgr.h"
#ifdef USE_MGSDK
#import "MobageViewController.h"
#import "MBGPlatform.h"
#endif
#import "NDBeforeGameMgr.h"
#import "SMLoginScene.h"
#import "SMGameScene.h"


@implementation MobageSdkLogin

- (id)init
{
	if ((self = [super init])) 
	{
	}
	return self;
}

- (void)LoginWithUser
{
#if defined(USE_MGSDK)
    MobageViewController* viewController = [MobageViewController sharedViewController];
    [[MBGPlatform sharedPlatform] setDelegate:self withWindow:viewController.window withRootViewController:viewController];
    
    if ([MBGPlatform isProductionEnv]) {
        [MBGPlatform initialize:MBG_REGION_TW serverType:MBG_PRODUCTION consumerKey:@"sdk_app_id:23000052" consumerSecret:@"e25f32276192dca071e175771f02c78b" appId:@"23000052"];
    }else {
        [MBGPlatform initialize:MBG_REGION_TW serverType:MBG_SANDBOX consumerKey:@"sdk_app_id:23000052" consumerSecret:@"7512ae70a3bb19ecb6c6ddf87611b6aa" appId:@"23000052"];
    }
    
    [MBGPlatform registerTick];
    [[MBGPlatform sharedPlatform] checkLoginStatus];
#endif
}

- (void) onLoginComplete:(NSString *)userId {
	NSLog(@"app delegate onLoginComplete userId %@", userId);
	NDBeforeGameMgr& mgr = NDBeforeGameMgrObj;
	mgr.SetCurrentUser([userId intValue]);
    //ScriptGlobalEvent::OnEvent(GE_LOGINOK_NORMAL, [userId intValue]);
    CSMGameScene * pGameScene = (CSMGameScene *)NDDirector::DefaultDirector()->GetSceneByTag(SMGAMESCENE_TAG);
    if ( pGameScene )
    {
        ScriptMgrObj.excuteLuaFunc( "SetAccountID", "Login_ServerUI", [userId intValue] );
        quitGame();
        return;
    }
	CSMLoginScene* pScene = (CSMLoginScene*)NDDirector::DefaultDirector()->GetSceneByTag(SMLOGINSCENE_TAG);
	if(pScene)
	{
        if( pScene->GetChild( 2068 ) )//Login_ServerUI
        {
            ScriptMgrObj.excuteLuaFunc( "LoginOK_Normal", "Login_ServerUI", [userId intValue] );
            return;
        }
        else
			return pScene->OnEvent_LoginOKGuest([userId intValue]);
	}
}
- (void) onLoginRequired {
	NSLog(@"app delegate showLoginDialog");
    [[MBGPlatform sharedPlatform] showLoginDialog];
}
- (void) onLoginError:(MBGError *)error {
	NSLog(@"app delegate onLoginError %@", error.description);
    //ScriptGlobalEvent::OnEvent(GE_LOGINERROR, error.code);
	CSMLoginScene* pScene = (CSMLoginScene*)NDDirector::DefaultDirector()->GetSceneByTag(SMLOGINSCENE_TAG);
	if(pScene)
	{
		return pScene->OnEvent_LoginError(error.code);
	}
}
- (void) onSplashComplete {
	NSLog(@"app delegate hideSplashScreen");
    
    [[MBGPlatform sharedPlatform] hideSplashScreen];
}
@end

