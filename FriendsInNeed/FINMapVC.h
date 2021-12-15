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
#import "FINSignalDetailsVC.h"

@interface FINMapVC : UIViewController <FINSignalsMapDelegate, FINLocationManagerMapDelegate, FINSignalDetailsVCDelegate>

- (void)updateMapWithNearbySignals:(NSArray *)nearbySignals;
- (void)updateMapToLocation:(CLLocation *)location;

@end
