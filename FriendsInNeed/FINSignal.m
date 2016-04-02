//
//  FINSignal.m
//  FriendsInNeed
//
//  Created by Milen on 20/03/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import "FINSignal.h"
#import "Backendless.h"
#import "FINDataManager.h"

@implementation FINSignal

- (id)initWithGeoPoint:(GeoPoint *)geoPoint
{
    self = [super init];
    
    _title = [geoPoint.metadata objectForKey:kSignalTitleKey];
    _author = [geoPoint.metadata objectForKey:kSignalAuthorKey];
    _signalID = geoPoint.objectId;
    
    
    _date = [[[FINDataManager sharedManager] signalDateFormatter] dateFromString:[geoPoint.metadata objectForKey:kSignalDateSubmittedKey]];
    
    NSString *statusString = [geoPoint.metadata objectForKey:kSignalStatusKey];
    if ([statusString isEqualToString:@"2"])
    {
        _status = FINSignalStatus2;
    }
    else if ([statusString isEqualToString:@"1"])
    {
        _status = FINSignalStatus1;
    }
    else
    {
        _status = FINSignalStatus0;
    }
    
    return self;
}

- (UIImage *)newStatusImage
{
    UIImage *statusImage;
    
    switch (_status) {
        case FINSignalStatus2:
            statusImage = [UIImage imageNamed:@"pin_green.png"];
            break;
            
        case FINSignalStatus1:
            statusImage = [UIImage imageNamed:@"pin_orange.png"];
            break;
            
        case FINSignalStatus0:
            statusImage = [UIImage imageNamed:@"pin_red.png"];
            break;
            
        default:
            break;
    }
    
    return statusImage;
}

@end
