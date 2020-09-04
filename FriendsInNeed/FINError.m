//
//  FINError.m
//  FriendsInNeed
//
//  Created by Milen on 09/05/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import "FINError.h"

@implementation FINError

- (id)initWithMessage:(NSString *)message
{
    self = [super init];
    
    _message = message;
    
    return self;
}

@end
