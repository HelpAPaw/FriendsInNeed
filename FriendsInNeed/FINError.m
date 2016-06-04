//
//  FINError.m
//  FriendsInNeed
//
//  Created by Milen on 09/05/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import "FINError.h"

@interface FINError()

@property (strong, nonatomic) Fault *fault;

@end

@implementation FINError

- (id)initWithFault:(Fault *)fault
{
    self = [super init];
    
    _fault = fault;
    
    return self;
}

- (NSString *)message
{
    return _fault.message;
}

@end
