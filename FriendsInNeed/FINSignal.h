//
//  FINSignal.h
//  FriendsInNeed
//
//  Created by Milen on 20/03/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

typedef NS_ENUM(NSUInteger, FINSignalStatus) {
    FINSignalStatus0,
    FINSignalStatus1,
    FINSignalStatus2,
    FINSignalStatus3
};

@interface FINSignal : NSObject

@property (strong, nonatomic) NSString *signalId;
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *authorName;
@property (strong, nonatomic) NSString *authorId;
@property (strong, nonatomic) NSString *authorPhone;
@property (strong, nonatomic) NSDate   *dateCreated;
@property (assign, nonatomic) FINSignalStatus status;
@property (assign, nonatomic) CLLocationCoordinate2D coordinate;
@property (strong, nonatomic) NSURL  *photoUrl;

- (UIImage *)createStatusImage;
+ (NSString *)localizedStatusString:(FINSignalStatus)status;

@end
