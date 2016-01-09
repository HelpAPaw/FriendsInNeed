//
//  FINLocationManager.h
//  FriendsInNeed
//
//  Created by Milen on 24/11/15.
//  Copyright © 2015 г. Milen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface FINLocationManager : NSObject

@property (weak, nonatomic) MKMapView *mapView;

+ (id)sharedManager;

- (void)startMonitoringSignificantLocationChanges;
- (void)updateUserLocation;
- (void)updateMapToLastKnownLocation;

@end
