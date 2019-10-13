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
    NSString *statusString = [FINSignal localizedStatusString:_signal.status];    
    self.subtitle = [NSString stringWithFormat:NSLocalizedString(@"Status: %@",nil), statusString];
}

@end
