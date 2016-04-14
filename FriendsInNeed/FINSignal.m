//
//  FINSignal.m
//  FriendsInNeed
//
//  Created by Milen on 20/03/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import "FINSignal.h"

@implementation FINSignal

+ (NSDateFormatter *)geoPointDateFormatter
{
    static NSDateFormatter *dateFormatter;
    
    if (dateFormatter == nil)
    {
        NSDateFormatter *geoPointDateFormatter = [NSDateFormatter new];
        NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        [geoPointDateFormatter setLocale:enUSPOSIXLocale];
        [geoPointDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [geoPointDateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        dateFormatter = geoPointDateFormatter;
    }
    
    return dateFormatter;
}

- (id)initWithGeoPoint:(GeoPoint *)geoPoint
{
    self = [super init];
    
    _geoPoint = geoPoint;
    
//    _title = [geoPoint.metadata objectForKey:kSignalTitleKey];
//    _author = [geoPoint.metadata objectForKey:kSignalAuthorKey];
//    _signalID = geoPoint.objectId;
//    
//    
//    _date = [[[FINDataManager sharedManager] signalDateFormatter] dateFromString:[geoPoint.metadata objectForKey:kSignalDateSubmittedKey]];
//    
//    NSString *statusString = [geoPoint.metadata objectForKey:kSignalStatusKey];
//    if ([statusString isEqualToString:@"2"])
//    {
//        _status = FINSignalStatus2;
//    }
//    else if ([statusString isEqualToString:@"1"])
//    {
//        _status = FINSignalStatus1;
//    }
//    else
//    {
//        _status = FINSignalStatus0;
//    }
    
    return self;
}


- (NSString *)signalID
{
    return _geoPoint.objectId;
}


- (NSString *)title
{
    return [_geoPoint.metadata objectForKey:kSignalTitleKey];
}

- (void)setTitle:(NSString *)newTitle
{
    [_geoPoint.metadata setObject:newTitle forKey:kSignalTitleKey];
}


- (NSString *)author
{
    return [_geoPoint.metadata objectForKey:kSignalAuthorKey];
}

- (void)setAuthor:(NSString *)newAuthor
{
    [_geoPoint.metadata setObject:newAuthor forKey:kSignalAuthorKey];
}


- (NSDate *)date
{
    NSString *dateString = [_geoPoint.metadata objectForKey:kSignalDateSubmittedKey];
    
    return [[FINSignal geoPointDateFormatter] dateFromString:dateString];
}

- (void)setDate:(NSDate *)newDate
{
    [_geoPoint.metadata setObject:[[FINSignal geoPointDateFormatter] stringFromDate:newDate] forKey:kSignalDateSubmittedKey];
}


- (FINSignalStatus)status
{
    FINSignalStatus status;
    
    NSString *statusString = [_geoPoint.metadata objectForKey:kSignalStatusKey];
    if ([statusString isEqualToString:@"2"])
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


- (UIImage *)newStatusImage
{
    UIImage *statusImage;
    
//    switch (_status) {
//        case FINSignalStatus2:
//            statusImage = [UIImage imageNamed:@"pin_green.png"];
//            break;
//            
//        case FINSignalStatus1:
//            statusImage = [UIImage imageNamed:@"pin_orange.png"];
//            break;
//            
//        case FINSignalStatus0:
//            statusImage = [UIImage imageNamed:@"pin_red.png"];
//            break;
//            
//        default:
//            break;
//    }
    
    return statusImage;
}

@end
