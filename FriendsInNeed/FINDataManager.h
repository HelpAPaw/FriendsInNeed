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

#define kNotificationSignalID   @"NotificationSignalID"
#define kDefaultMapRegion       4000

@protocol FINSignalsMapDelegate <NSObject>

- (void)updateMapWithNearbySignals:(NSArray *)nearbySignals;

@end

@interface FINDataManager : NSObject

+ (id)sharedManager;

- (void)getSignalsForNewLocation:(CLLocation *)location;
- (void)getNewSignalsForLastLocationWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
- (void)submitNewSignalWithTitle:(NSString *)title forLocation:(CLLocationCoordinate2D)locationCoordinate completion:(void (^)(GeoPoint *savedGeoPoint, Fault *fault))completion;
- (void)setStatus:(FINSignalStatus)status forSignal:(FINSignal *)signal completion:(void (^)(Fault *fault))completion;

@property (weak, nonatomic) id<FINSignalsMapDelegate> mapDelegate;
@property (strong, nonatomic) NSDateFormatter   *signalDateFormatter;
@property (strong, nonatomic) NSMutableArray    *nearbySignals;

@end
