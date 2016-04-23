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

#define BCKNDLSS_APP_ID         @"7381F40A-5BA6-6CB5-FF82-1F0334A63B00"
#define BCKNDLSS_SECRET_KEY     @"9F8B017B-2890-A887-FFD5-63D6A5302100"
#define BCKNDLSS_VERSION_NUM    @"v1"

#define kNotificationSignalID   @"NotificationSignalID"
#define kDefaultMapRegion       4000

@protocol FINSignalsMapDelegate <NSObject>

- (void)updateMapWithNearbySignals:(NSArray *)nearbySignals;

@end

@interface FINDataManager : NSObject

+ (id)sharedManager;

- (void)getSignalsForNewLocation:(CLLocation *)location;
- (void)getNewSignalsForLastLocationWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
- (void)submitNewSignalWithTitle:(NSString *)title forLocation:(CLLocationCoordinate2D)locationCoordinate withPhoto:(UIImage *)photo completion:(void (^)(FINSignal *savedSignal, Fault *fault))completion;
- (void)setStatus:(FINSignalStatus)status forSignal:(FINSignal *)signal completion:(void (^)(Fault *fault))completion;
- (void)getSignalWithID:(NSString *)signalID completion:(void (^)(FINSignal *signal, Fault *fault))completion;
- (BOOL)userIsLogged;
- (void)registerUser:(NSString *)name withEmail:(NSString *)email andPassword:(NSString *)password completion:(void (^)(Fault *fault))completion;
- (void)loginWithEmail:(NSString *)email andPassword:(NSString *)password completion:(void (^)(Fault *fault))completion;
- (void)getPhotoForSignal:(FINSignal *)signal;

@property (weak, nonatomic) id<FINSignalsMapDelegate> mapDelegate;
@property (strong, nonatomic) NSMutableArray    *nearbySignals;

@end
