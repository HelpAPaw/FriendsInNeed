//
//  FINError.h
//  FriendsInNeed
//
//  Created by Milen on 09/05/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FINError : NSObject

@property (strong, nonatomic) NSString *message;

- (id)initWithMessage:(NSString *)message;
- (NSString *)message;

@end
