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

#define BCKNDLSS_APP_ID         @"7381F40A-5BA6-6CB5-FF82-1F0334A63B00"
#define BCKNDLSS_SECRET_KEY     @"***REMOVED***"
#define BCKNDLSS_VERSION_NUM    @"v1"

@interface AppDelegate ()

@property (strong, nonatomic) UILocalNotification *localNotificationReceived;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = TRUE;
    
    [backendless initApp:BCKNDLSS_APP_ID secret:BCKNDLSS_SECRET_KEY version:BCKNDLSS_VERSION_NUM];
    //TODO: change this to YES after debuging is done
    [backendless.userService setStayLoggedIn:NO];
    
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    FINMapVC *mapVC = [[FINMapVC alloc] initWithNibName:nil bundle:nil];
    self.window.rootViewController = mapVC;
    [self.window makeKeyAndVisible];
    
    
    [self registerForLocalNotifications];
    
    
    _locationManager = [FINLocationManager sharedManager];
    
    // TODO: fix this to happen in MapVC
    UILocalNotification *notification = [launchOptions objectForKey:@"UIApplicationLaunchOptionsLocalNotificationKey"];
    [_locationManager setFocusSignalID:[notification.userInfo objectForKey:kNotificationSignalID]];
    
    return YES;
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
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
//    _localNotificationReceived = notification;
    NSString *focusSignalID = [notification.userInfo objectForKey:kNotificationSignalID];
    [_locationManager setFocusSignalID:focusSignalID];
}

#pragma mark - Custom methods
- (void)registerForLocalNotifications
{
    UIMutableUserNotificationCategory *reminderCategory = [UIMutableUserNotificationCategory new];
    reminderCategory.identifier = @"ReminderCategory";
    [reminderCategory setActions:nil forContext:UIUserNotificationActionContextDefault];
    
    NSSet *categories = [NSSet setWithObjects:reminderCategory, nil];
    UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    UIUserNotificationSettings *userNotificationSettings = [UIUserNotificationSettings settingsForTypes:types categories:categories];
    [[UIApplication sharedApplication] registerUserNotificationSettings:userNotificationSettings];
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    
}

@end
