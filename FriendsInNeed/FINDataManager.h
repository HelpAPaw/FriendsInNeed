//
//  FINDataManager.h
//  FriendsInNeed
//
//  Created by Milen on 29/02/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Backendless.h"

#define kSignalTitleKey         @"title"
#define kSignalAuthorKey        @"author"
#define kSignalDateSubmittedKey @"dateSubmitted"
#define kNotificationSignalID   @"NotificationSignalID"
#define kDefaultMapRegion       4000

@protocol FINSignalsMapDelegate <NSObject>

- (void)updateMapWithNearbySignals:(NSArray *)nearbySignals;

@end

@interface FINDataManager : NSObject

+ (id)sharedManager;

- (void)getSignalsForNewLocation:(CLLocation *)location;
- (void)getNewSignalsForLastLocation;

@property (weak, nonatomic) id<FINSignalsMapDelegate> mapDelegate;
@property (strong, nonatomic) NSDateFormatter   *signalDateFormatter;
@property (strong, nonatomic) NSMutableArray    *nearbySignals;

@end
