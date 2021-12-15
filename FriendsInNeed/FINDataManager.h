//
//  FINDataManager.h
//  FriendsInNeed
//
//  Created by Milen on 29/02/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FINSignal.h"
#import "FINComment.h"
#import "FINError.h"
#import "Secrets.h"

#define kSignalId   @"signalId"
#define kNotificationCategoryNewSignal  @"kNotificationCategoryNewSignal"
#define kNotificationSettingRadiusChanged    @"kNotificationSettingRadiusChanged"
#define kNotificationSettingTimeoutChanged   @"kNotificationSettingTimeoutChanged"

#define kUserPropertyPhoneNumber                @"phoneNumber"
#define kUserPropertyAcceptedPrivacyPolicy      @"acceptedPrivacyPolicy"

@protocol FINSignalsMapDelegate <NSObject>

- (void)updateMapWithNearbySignals:(NSArray *)nearbySignals;

@end

@interface FINDataManager : NSObject

@property (strong, nonatomic) NSArray<NSString *> *signalTypes;

+ (instancetype)sharedManager;
+ (BOOL)setNotificationShownForSignalId:(NSString *)signalId;

- (void)updateDeviceRegistrationWithLocation:(CLLocation *)location;
- (void)getSignalsForNewLocation:(CLLocation *)location
           withCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
- (void)getSignalsForLocation:(CLLocation *)location
                     inRadius:(NSInteger)radius
          overridingDampening:(BOOL)overrideDampening
        withCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
- (void)getCountForSignalsWithStatus:(FINSignalStatus)status
               withCompletionHandler:(void (^)(NSInteger count, FINError *error))completion;
- (void)getTotalSignalCountWithCompletionHandler:(void (^)(NSInteger count, FINError *error))completion;
- (void)getNewSignalsForLastLocationWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
- (void)uploadPhoto:(UIImage *)photo
          forSignal:(FINSignal *)signal
     withCompletion:(void (^)(FINError *error))completion;
- (void)uploadPhoto:(UIImage *)photo
          forComment:(FINComment *)comment
     withCompletion:(void (^)(FINError *error))completion;
- (void)submitNewSignalWithTitle:(NSString *)title
                            type:(NSInteger)type
                  andAuthorPhone:(NSString *)authorPhone
                     forLocation:(CLLocationCoordinate2D)locationCoordinate
                       withPhoto:(UIImage *)photo
                      completion:(void (^)(FINSignal *savedSignal, FINError *error))completion;
- (void)setStatus:(FINSignalStatus)status
        forSignal:(FINSignal *)signal
withCurrentComments:(NSArray<FINComment *> *)currentComments
       completion:(void (^)(FINError *error))completion;
- (void)getSignalWithID:(NSString *)signalId
             completion:(void (^)(FINSignal *signal, FINError *error))completion;
- (BOOL)userIsLogged;
- (BOOL)getUserHasAcceptedPrivacyPolicy;
- (void)setUserHasAcceptedPrivacyPolicy:(BOOL)value;
- (NSString *)getUserId;
- (NSString *)getUserName;
- (NSString *)getUserEmail;
- (NSString *)getUserPhone;
- (void)registerUser:(NSString *)name
           withEmail:(NSString *)email
            password:(NSString *)password
         phoneNumber:(NSString *)phoneNumber
          completion:(void (^)(FINError *error))completion;
- (void)loginWithEmail:(NSString *)email
           andPassword:(NSString *)password
            completion:(void (^)(FINError *error))completion;
- (void)loginWithFacebookAccessToken:(NSString *)tokenString
                          completion:(void (^)(FINError *error))completion;
- (void)loginWithGoogleToken:(NSString *)tokenString
                  completion:(void (^)(FINError *error))completion;
- (void)loginWithAppleToken:(NSString *)tokenString
                 completion:(void (^)(FINError *error))completion;
- (void)logoutWithCompletion:(void (^)(FINError *error))completion;
- (void)resetPasswordForEmail:(NSString *)email
               withCompletion:(void (^)(FINError *error))completion;
- (void)getCommentsForSignal:(FINSignal *)signal
                  completion:(void (^)(NSArray *comments, FINError *error))completion;
- (void)saveComment:(NSString *)commentText
          forSignal:(FINSignal *)signal
withCurrentComments:(NSArray<FINComment *> *)currentComments
         completion:(void (^)(FINComment *comment, FINError *error))completion;
- (BOOL)getIsInTestMode;
- (void)setIsInTestMode:(BOOL)isInTestMode;
- (void)registerDeviceToken:(NSData *)deviceToken;

- (NSInteger)getRadiusSetting;
- (NSInteger)getTimeoutSetting;
- (NSArray<NSNumber *>*)getTypesSetting;
- (void)setRadiusSetting:(NSInteger)newRadius;
- (void)setTimeoutSetting:(NSInteger)newTimeout;
- (void)setTypesSetting:(NSArray<NSNumber *>*)typesArray;
- (NSString *)getStringForSignalTypesSetting;
- (void)saveSettings;

+ (NSInteger)getNewStatusCodeFromStatusChangedComment:(NSString *)commentText;

@property (weak, nonatomic) id<FINSignalsMapDelegate> mapDelegate;
@property (strong, nonatomic) NSMutableArray    *nearbySignals;

@end
