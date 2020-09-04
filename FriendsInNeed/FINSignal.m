//
//  FINSignal.m
//  FriendsInNeed
//
//  Created by Milen on 20/03/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import "FINSignal.h"

@implementation FINSignal

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
