//
//  FINSignal.m
//  FriendsInNeed
//
//  Created by Milen on 20/03/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import "FINSignal.h"
#import "FINDataManager.h"

@implementation FINSignal

- (id)initWithGeoPoint:(GeoPoint *)geoPoint
{
    self = [super init];
    
    _geoPoint = geoPoint;
    
    return self;
}


- (NSString *)signalID
{
    return _geoPoint.objectId;
}


- (NSString *)title
{
    id title = [_geoPoint.metadata objectForKey:kSignalTitleKey];
    
    // Protection for wrong type. Usually NSNull if signal was recorded with empty title.
    if (![title isKindOfClass:[NSString class]])
    {
        title = NSLocalizedString(@"(empty description)",nil);
    }
    
    return title;
}

- (void)setTitle:(NSString *)newTitle
{
    [_geoPoint.metadata setObject:newTitle forKey:kSignalTitleKey];
}


- (NSString *)authorName;
{
    BackendlessUser *user = [_geoPoint.metadata objectForKey:kSignalAuthorKey];
    
    return user.name;
}

- (NSString *)authorId;
{
    BackendlessUser *user = [_geoPoint.metadata objectForKey:kSignalAuthorKey];
    
    return user.objectId;
}

- (NSString *)authorPhone
{    
    NSString *authorPhone = [_geoPoint.metadata objectForKey:kSignalAuthorPhoneKey];
    
    return authorPhone;
}


- (NSString *)dateString
{
    NSString *dateString = [_geoPoint.metadata objectForKey:kSignalDateSubmittedKey];
    
    return dateString;
}

- (NSDate *)date
{
    NSString *dateSubmitted = [_geoPoint.metadata objectForKey:kSignalDateSubmittedKey];
    long long unixTimestamp = dateSubmitted.longLongValue;
    NSTimeInterval timeInterval = unixTimestamp / 1000.0;
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    
    return date;
}

- (void)setDate:(NSDate *)newDate
{
    [_geoPoint.metadata setObject:[NSNumber numberWithDouble:[newDate timeIntervalSince1970]] forKey:kSignalDateSubmittedKey];
}


- (FINSignalStatus)status
{
    FINSignalStatus status;
    
    NSString *statusString = [_geoPoint.metadata objectForKey:kSignalStatusKey];
    if ([statusString isEqualToString:@"3"])
    {
        status = FINSignalStatus3;
    }
    else if ([statusString isEqualToString:@"2"])
    {
        status = FINSignalStatus2;
    }
    else if ([statusString isEqualToString:@"1"])
    {
        status = FINSignalStatus1;
    }
    else
    {
        status = FINSignalStatus0;
    }
    
    return status;
}

- (void)setStatus:(FINSignalStatus)newStatus
{
    NSString *statusString;
    
    switch (newStatus) {
        case FINSignalStatus3:
            statusString = @"3";
            break;
            
        case FINSignalStatus2:
            statusString = @"2";
            break;
            
        case FINSignalStatus1:
            statusString = @"1";
            break;
            
        default:
            statusString = @"0";
            break;
    }
    
    [_geoPoint.metadata setObject:statusString forKey:kSignalStatusKey];
}


- (CLLocationCoordinate2D)coordinate
{
    CLLocationCoordinate2D coordinate;
    coordinate.latitude  = _geoPoint.latitude.doubleValue;
    coordinate.longitude = _geoPoint.longitude.doubleValue;
    
    return coordinate;
}


- (UIImage *)createStatusImage
{
    UIImage *statusImage;
    FINSignalStatus status = [self status];
    
    switch (status) {
        case FINSignalStatus3:
            statusImage = [UIImage imageNamed:@"pin_white.png"];
            break;
            
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

+ (NSString *)localizedStatusString:(FINSignalStatus)status
{
    switch (status) {
        case FINSignalStatus2:
            return NSLocalizedString(@"Solved", nil);
            break;
        case FINSignalStatus1:
            return NSLocalizedString(@"Somebody on the way", nil);
            break;
            
        default:
            return NSLocalizedString(@"Help needed", nil);
            break;
    }
}

@end
