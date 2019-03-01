//
//  FINDataManager.h
//  FriendsInNeed
//
//  Created by Milen on 29/02/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Backendless.h"
#import "FINSignal.h"
#import "FINComment.h"
#import "FINError.h"

#define BCKNDLSS_APP_ID         @"***REMOVED***"
#define BCKNDLSS_IOS_API_KEY    @"***REMOVED***"
#define BCKNDLSS_REST_API_KEY   @"***REMOVED***"

#define kNotificationSignalID   @"NotificationSignalID"
#define kNotificationCategoryNewSignal  @"kNotificationCategoryNewSignal"
#define kNotificationSettingRadiusChanged    @"kNotificationSettingRadiusChanged"
#define kNotificationSettingTimeoutChanged   @"kNotificationSettingTimeoutChanged"

#define kUserPropertyPhoneNumber                @"phoneNumber"
#define kUserPropertyAcceptedPrivacyPolicy      @"acceptedPrivacyPolicy"

@protocol FINSignalsMapDelegate <NSObject>

- (void)updateMapWithNearbySignals:(NSArray *)nearbySignals;

@end

@interface FINDataManager : NSObject

+ (instancetype)sharedManager;
+ (void)saveDeviceRegistrationId:(NSString *)deviceRegistrationId;

- (void)getSignalsForNewLocation:(CLLocation *)location withCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
- (void)getSignalsForLocation:(CLLocation *)location inRadius:(NSInteger)radius overridingDampening:(BOOL)overrideDampening withCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
- (void)getNewSignalsForLastLocationWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
- (void)getAllSignalsWithCompletionHandler:(void (^)(NSArray<FINSignal *> *signals, FINError *error))completionHandler;
- (void)submitNewSignalWithTitle:(NSString *)title forLocation:(CLLocationCoordinate2D)locationCoordinate withPhoto:(UIImage *)photo completion:(void (^)(FINSignal *savedSignal, FINError *error))completion;
- (void)setStatus:(FINSignalStatus)status forSignal:(FINSignal *)signal completion:(void (^)(FINError *error))completion;
- (void)getSignalWithID:(NSString *)signalID completion:(void (^)(FINSignal *signal, FINError *error))completion;
- (BOOL)userIsLogged;
- (BOOL)getUserHasAcceptedPrivacyPolicy;
- (void)setUserHasAcceptedPrivacyPolicy:(BOOL)value;
- (NSString *)getUserName;
- (NSString *)getUserEmail;
- (void)registerUser:(NSString *)name withEmail:(NSString *)email password:(NSString *)password phoneNumber:(NSString *)phoneNumber completion:(void (^)(FINError *error))completion;
- (void)loginWithEmail:(NSString *)email andPassword:(NSString *)password completion:(void (^)(FINError *error))completion;
- (void)logoutWithCompletion:(void (^)(FINError *error))completion;
- (void)getCommentsForSignal:(FINSignal *)signal completion:(void (^)(NSArray *comments, FINError *error))completion;
- (void)saveComment:(NSString *)commentText forSigna:(FINSignal *)signal completion:(void (^)(FINComment *comment, FINError *error))completion;
- (BOOL)getIsInTestMode;
- (void)setIsInTestMode:(BOOL)isInTestMode;

- (NSInteger)getRadiusSetting;
- (NSInteger)getTimeoutSetting;
- (void)setRadiusSetting:(NSInteger)newRadius;
- (void)setTimeoutSetting:(NSInteger)newTimeout;

+ (NSInteger)getNewStatusCodeFromStatusChangedComment:(NSString *)commentText;

@property (weak, nonatomic) id<FINSignalsMapDelegate> mapDelegate;
@property (strong, nonatomic) NSMutableArray    *nearbySignals;

@end
