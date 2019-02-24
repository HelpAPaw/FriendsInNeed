//
//  AppDelegate.m
//  FriendsInNeed
//
//  Created by Milen on 21/11/15.
//  Copyright © 2015 г. Milen. All rights reserved.
//

#import "AppDelegate.h"
#import "Backendless.h"
#import "FINMapVC.h"
#import "FINMenuVC.h"
#import "FINDataManager.h"
#import "FINGlobalConstants.pch"
#import <ViewDeck/ViewDeck.h>
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "IQKeyboardManager.h"

@interface AppDelegate () <UNUserNotificationCenterDelegate>

@property (weak, nonatomic) FINMapVC *mapVC;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL r = [[FBSDKApplicationDelegate sharedInstance] application:application
                                    didFinishLaunchingWithOptions:launchOptions];
    
    IQKeyboardManager.sharedManager.enable = YES;
    [backendless initApp:BCKNDLSS_APP_ID APIKey:BCKNDLSS_IOS_API_KEY];
    [backendless.userService setStayLoggedIn:YES];
    [backendless.data mapTableToClass:@"Users" type:[BackendlessUser class]];
    
    [[Crashlytics sharedInstance] setDebugMode:YES];
    [Fabric with:@[[Crashlytics class]]];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // Override point for customization after application launch.
    FINMapVC *mapVC = [[FINMapVC alloc] initWithNibName:nil bundle:nil];
    [[UINavigationBar appearance] setBarTintColor:kCustomOrange];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    [[UINavigationBar appearance] setTranslucent:NO];
     UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:mapVC];
    
    FINMenuVC *menuVC = [[FINMenuVC alloc] initWithNibName:nil bundle:nil];
    
    CGFloat maxMenuWidth = self.window.frame.size.width - 60;
    CGFloat menuWidth = 315;
    menuWidth = menuWidth < maxMenuWidth ? menuWidth : maxMenuWidth;
    
    menuVC.preferredContentSize = CGSizeMake(menuWidth, self.window.frame.size.height);
    
    IIViewDeckController *viewDeckController = [[IIViewDeckController alloc] initWithCenterViewController:navController
                                                                                      leftViewController:menuVC];
    
    self.window.rootViewController = viewDeckController;
    [self.window makeKeyAndVisible];
    _mapVC = mapVC;
    
    
    [self registerForNotifications];
    
    
    UILocalNotification *notification = [launchOptions objectForKey:@"UIApplicationLaunchOptionsLocalNotificationKey"];
    NSString *focusSignalID = [notification.userInfo objectForKey:kNotificationSignalID];
    if (focusSignalID)
    {        
        [_mapVC setFocusSignalID:focusSignalID];
    }
    
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    @try {
        [backendless initAppFault];
    }
    @catch (Fault *fault) {
        NSLog(@"didFinishLaunchingWithOptions: %@", fault);
    }
    return r;
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
    [FBSDKAppEvents activateApp];
}
   
- (BOOL)application:(UIApplication *)application
                openURL:(NSURL *)url
                options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
        
        BOOL result = [[FBSDKApplicationDelegate sharedInstance] application:application
                                                                      openURL:url
                                                            sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
                                                                   annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
    
    /*Doesnt work as shown in BackendlessUser tutorial
    when this function gets called accsess token is stil nil
     so we gonna do it differently 
     */
//        FBSDKAccessToken *token = [FBSDKAccessToken currentAccessToken];
//        @try {
//            BackendlessUser *user = [backendless.userService loginWithFacebookSDK:token fieldsMapping:nil];
//            NSLog(@"USER: %@", user);
//        }
//        @catch (Fault *fault) {
//            NSLog(@"openURL: %@", fault);
//        }
        return result;
    
    }
//- (BOOL)application:(UIApplication *)application
//            openURL:(NSURL *)url
//  sourceApplication:(NSString *)sourceApplication
//         annotation:(id)annotation {
//    BOOL result = [[FBSDKApplicationDelegate sharedInstance]
//                   application:application
//                   openURL:url
//                   sourceApplication:sourceApplication
//                   annotation:annotation];
//
//    FBSDKAccessToken *token = [FBSDKAccessToken currentAccessToken];
//     NSLog(@"openURL: %@", token);
//    NSLog(result ? @"Yes" : @"No");
//
//
//    @try {
//       BackendlessUser *user = [backendless.userService loginWithFacebookSDK:token fieldsMapping:nil];
//       NSLog(@"USER: %@", user);
//    }
//    @catch (Fault *fault) {
//        NSLog(@"openURL: %@", fault);
//    }
//    return result;
//}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Notifications
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    NSString *focusSignalID = [notification.userInfo objectForKey:kNotificationSignalID];
    [_mapVC setFocusSignalID:focusSignalID];
}

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

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [backendless.messaging registerDevice:deviceToken response:^(NSString *registeredDeviceId) {
        //Get only the objectId part
        NSArray *components = [registeredDeviceId componentsSeparatedByString:@":"];
        [FINDataManager saveDeviceRegistrationId:components[0]];
        
    }   error:^(Fault *fault) {
        //Do nothing
    }];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler
{
    completionHandler(UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionAlert);
}

#pragma mark - Background Fetch
- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    CLS_LOG(@"[FIN] Starting background fetch with completion handler: %@", completionHandler);
    [[FINDataManager sharedManager] getNewSignalsForLastLocationWithCompletionHandler:completionHandler];
}
    
    
    

@end
