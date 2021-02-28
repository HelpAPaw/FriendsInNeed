//
//  FINAnnotation.h
//  FriendsInNeed
//
//  Created by Milen on 22/02/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "FINSignal.h"

@interface FINAnnotation : MKPointAnnotation

@property (strong, nonatomic) FINSignal *signal;

- (FINAnnotation *)initWithSignal:(FINSignal *)signal;

@end
