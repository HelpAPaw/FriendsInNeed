//
//  FINMapVC.h
//  FriendsInNeed
//
//  Created by Milen on 18/02/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FINDataManager.h"
#import "FINLocationManager.h"

@interface FINMapVC : UIViewController <FINSignalsMapDelegate, FINLocationManagerMapDelegate>

- (void)updateMapWithNearbySignals:(NSArray *)nearbySignals;
- (void)updateMapToLocation:(CLLocation *)location;

@property (strong, nonatomic) NSString *focusSignalID;

@end
