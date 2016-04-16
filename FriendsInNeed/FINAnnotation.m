//
//  FINAnnotation.m
//  FriendsInNeed
//
//  Created by Milen on 22/02/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import "FINAnnotation.h"
#import "FINDataManager.h"

@implementation FINAnnotation

- (FINAnnotation *)initWithSignal:(FINSignal *)signal
{
    self.title = signal.title;
    self.coordinate = signal.coordinate;
    self.signal = signal;
    
    return self;
}

- (void)updateAnnotationSubtitle
{    
    NSString *statusString;
    
    switch (_signal.status) {
        case FINSignalStatus2:
            statusString = @"Solved";
            break;
        case FINSignalStatus1:
            statusString = @"Somebody on the way";
            break;
            
        default:
            statusString = @"Help needed";
            break;
    }
    
    self.subtitle = [NSString stringWithFormat:@"Status: %@", statusString];
}

@end
