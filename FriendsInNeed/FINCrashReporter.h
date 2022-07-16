//
//  FINCrashReporter.h
//  FriendsInNeed
//
//  Created by Milen Marinov on 9.07.22.
//  Copyright © 2022 Milen. All rights reserved.
//

#ifndef FINCrashReporter_h
#define FINCrashReporter_h

@interface FINCrashReporter : NSObject

+ (void)setUserID:(NSString *)userId;
+ (void)recordError:(NSError *)error;
+ (void)logWithFormat:(NSString *)format, ...;

@end


#endif /* FINCrashReporter_h */
