//
//  FINComment.h
//  FriendsInNeed
//
//  Created by Milen on 24/04/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Backendless.h"

@interface FINComment : NSObject

@property (strong, nonatomic) NSString *signalID;
@property (strong, nonatomic) NSString *text;
@property (strong, nonatomic) NSString *type;
@property (strong, nonatomic) NSDate *created;
@property (strong, nonatomic) BackendlessUser *author;

@end
