//
//  FINLocationManager.h
//  FriendsInNeed
//
//  Created by Milen on 24/11/15.
//  Copyright © 2015 г. Milen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@protocol FINLocationManagerMapDelegate <NSObject>

- (void)updateMapToLocation:(CLLocation *)location;

@end

@interface FINLocationManager : NSObject

+ (id)sharedManager;

- (void)startMonitoringSignificantLocationChanges;
- (void)updateUserLocation;
- (CLLocation *)getLastKnownUserLocation;

@property (weak, nonatomic) id<FINLocationManagerMapDelegate> mapDelegate;

@end
