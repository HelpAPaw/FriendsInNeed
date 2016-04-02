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
    FINSignalStatus2
};

@interface FINSignal : NSObject

@property (strong, nonatomic) NSString                  *signalID;
@property (strong, nonatomic) NSString                  *title;
@property (strong, nonatomic) NSString                  *author;
@property (strong, nonatomic) NSDate                    *date;
@property (assign, nonatomic) FINSignalStatus           status;
@property (assign, nonatomic) CLLocationCoordinate2D    coordinate;


@end
