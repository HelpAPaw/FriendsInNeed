//
//  FINError.h
//  FriendsInNeed
//
//  Created by Milen on 09/05/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Backendless.h"

@interface FINError : NSObject

- (id)initWithFault:(Fault *)fault;
- (NSString *)message;

@end
