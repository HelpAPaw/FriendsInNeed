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
            statusString = NSLocalizedString(@"Solved",nil);
            break;
        case FINSignalStatus1:
            statusString = NSLocalizedString(@"Somebody on the way",nil);
            break;
            
        default:
            statusString = NSLocalizedString(@"Help needed",nil);
            break;
    }
    
    self.subtitle = [NSString stringWithFormat:NSLocalizedString(@"Status: %@",nil), statusString];
}

@end
