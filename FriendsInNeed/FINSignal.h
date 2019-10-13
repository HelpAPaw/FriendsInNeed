//
//  FINSignal.h
//  FriendsInNeed
//
//  Created by Milen on 20/03/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "Backendless.h"

#define kSignalTitleKey         @"title"
#define kSignalAuthorKey        @"author"
#define kSignalDateSubmittedKey @"dateSubmitted"
#define kSignalStatusKey        @"status"

typedef NS_ENUM(NSUInteger, FINSignalStatus) {
    FINSignalStatus0,
    FINSignalStatus1,
    FINSignalStatus2,
    FINSignalStatus3
};

@interface FINSignal : NSObject

@property (strong, nonatomic) GeoPoint *geoPoint;
@property (strong, nonatomic) NSURL  *photoUrl;

- (id)initWithGeoPoint:(GeoPoint *)geoPoint;


- (NSString *)signalID;

- (NSString *)title;
- (void)setTitle:(NSString *)newTitle;

- (NSString *)authorName;
- (NSString *)authorId;
- (NSString *)authorPhone;

- (NSString *)dateString;
- (NSDate *)date;
- (void)setDate:(NSDate *)newDate;

- (FINSignalStatus)status;
- (void)setStatus:(FINSignalStatus)newStatus;

- (CLLocationCoordinate2D)coordinate;


- (UIImage *)createStatusImage;
+ (NSString *)localizedStatusString:(FINSignalStatus)status;

@end
