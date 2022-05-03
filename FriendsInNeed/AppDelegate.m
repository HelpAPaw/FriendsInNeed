//
//  AppDelegate.m
//  FriendsInNeed
//
//  Created by Milen on 21/11/15.
//  Copyright © 2015 г. Milen. All rights reserved.
//

#import "AppDelegate.h"
#import <Backendless-Swift.h>
#import "FINMapVC.h"
#import "FINMenuVC.h"
#import "FINDataManager.h"
#import "FINGlobalConstants.pch"
#import <ViewDeck/ViewDeck.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "IQKeyboardManager.h"
#import <Realm/Realm.h>
#import <UserNotifications/UserNotifications.h>
@import Firebase;
@import GoogleSignIn;
@import Branch;

@interface AppDelegate () <UNUserNotificationCenterDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[FBSDKApplicationDelegate sharedInstance] application:application
                             didFinishLaunchingWithOptions:launchOptions];
    
    IQKeyboardManager.sharedManager.enable = YES;
    
    // Setup Realm
    RLMRealm *realm = [RLMRealm defaultRealm];
    // Get our Realm file's parent directory
    NSString *folderPath = realm.configuration.fileURL.URLByDeletingLastPathComponent.path;
    // Disable file protection for this directory
    [[NSFileManager defaultManager] setAttributes:@{NSFileProtectionKey: NSFileProtectionNone}
                                     ofItemAtPath:folderPath error:nil];
    
    // Setup Crashlytics
    [FIRApp configure];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *barAppearance = [[UINavigationBarAppearance alloc] init];
        [barAppearance configureWithOpaqueBackground];
        [barAppearance setBackgroundColor:kCustomOrange];
        [barAppearance setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
        [[UINavigationBar appearance] setScrollEdgeAppearance:barAppearance];
    }
    
    [[UINavigationBar appearance] setBarTintColor:kCustomOrange];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    [[UINavigationBar appearance] setTranslucent:NO];
    FINMapVC *mapVC = [[FINMapVC alloc] initWithNibName:nil bundle:nil];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:mapVC];
    
    FINMenuVC *menuVC = [[FINMenuVC alloc] initWithNibName:nil bundle:nil];
    
    CGFloat maxMenuWidth = self.window.frame.size.width - 60;
    CGFloat menuWidth = 315;
    menuWidth = menuWidth < maxMenuWidth ? menuWidth : maxMenuWidth;
    
    menuVC.preferredContentSize = CGSizeMake(menuWidth, self.window.frame.size.height);
    
    IIViewDeckController *viewDeckController = [[IIViewDeckController alloc] initWithCenterViewController:navController
                                                                                       leftViewController:menuVC];
    
    self.window.rootViewController = viewDeckController;
    [self.window makeKeyAndVisible];
    
    [self setupBranchWith:launchOptions];
    
    [self registerForNotifications];
    
    [FINDataManager incrementAppLaunchCounter];
    
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    return YES;
}

- (void)setupBranchWith:(NSDictionary * _Nullable)launchOptions {
    
    // if you are using the TEST key
    //[Branch setUseTestBranchKey:YES];
    
    // enable pasteboard check for iOS 15+ only
    if ([[[UIDevice currentDevice] systemVersion] compare:@"15.0" options:NSNumericSearch] != NSOrderedAscending) {
        [[Branch getInstance] checkPasteboardOnInstall];
    }
    
     // listener for Branch Deep Link data
    [[Branch getInstance] initSessionWithLaunchOptions:launchOptions andRegisterDeepLinkHandler:^(NSDictionary * _Nonnull params, NSError * _Nullable error) {
        // do stuff with deep link data (nav to page, display content, etc)
        NSString *signalId = [params objectForKey:kSignalId];
        if (signalId != nil) {
            [self postNotificationToFocusSignalWithId:signalId];
        }
    }];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    
}

- (BOOL)application:(UIApplication *)application
continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
    // handler for Universal Links
    return [[Branch getInstance] continueUserActivity:userActivity];;
}
   
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    return [[Branch getInstance] application:application openURL:url options:options];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Notifications
- (void)registerForNotifications
{
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] registerForRemoteNotifications];
            });
        }
    }];
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [[FINDataManager sharedManager] registerDeviceToken:deviceToken];
}

// Currently unused because this is called only when "content-available" property is set to 1 but in this case there is no notification
// shown to the user. One possible solution is to send double notifications to iOS devices - one with "content-availabe" and
// one without. For now we will just set the "notification shown" flag when the user opens it.
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(nonnull void (^)(UIBackgroundFetchResult))completionHandler
{
    NSString *category = [userInfo objectForKey:@"ios-category"];
    if ([category isEqualToString:kNotificationCategoryNewSignal])
    {
        NSString *signalId = [userInfo objectForKey:kSignalId];
        [FINDataManager setNotificationShownForSignalId:signalId];
    }
    
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler
{
    completionHandler(UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionAlert);
}

- (void)postNotificationToFocusSignalWithId:(NSString *)signalId {
    [NSNotificationCenter.defaultCenter postNotificationName:kNotificationFocusedSignalChanged
                                                      object:self
                                                    userInfo:@{kSignalId : signalId}];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler
{
    UNNotificationRequest *request = response.notification.request;
    NSString *category = request.content.categoryIdentifier;
    if ([category isEqualToString:kNotificationCategoryNewSignal])
    {
        if ([response.actionIdentifier isEqualToString:UNNotificationDefaultActionIdentifier])
        {            
            NSDictionary *userInfo = request.content.userInfo;
            NSString *signalId = [userInfo objectForKey:kSignalId];
            [FINDataManager setNotificationShownForSignalId:signalId];
            [self postNotificationToFocusSignalWithId:signalId];
        }
    }
    else
    {
        //Handle other notification categories in the future
    }
}

#pragma mark - Background Fetch
- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    CLS_LOG(@"[FIN] Starting background fetch with completion handler: %@", completionHandler);
    [[FINDataManager sharedManager] getNewSignalsForLastLocationWithCompletionHandler:completionHandler];
}

@end
