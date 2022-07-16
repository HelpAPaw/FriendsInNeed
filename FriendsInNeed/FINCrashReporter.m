//
//  FINCrashReporter.m
//  FriendsInNeed
//
//  Created by Milen Marinov on 9.07.22.
//  Copyright © 2022 Milen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FINCrashReporter.h"
@import FirebaseCrashlytics;

@implementation FINCrashReporter

+ (void)setUserID:(NSString *)userId {
    [FIRCrashlytics.crashlytics setUserID:userId];
}

+ (void)recordError:(NSError *)error {
    [FIRCrashlytics.crashlytics recordError:error];
}

+ (void)logWithFormat:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    [FIRCrashlytics.crashlytics logWithFormat:format arguments:args];
    va_end(args);
}

@end
