//
//  FINComment.h
//  FriendsInNeed
//
//  Created by Milen on 24/04/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FINComment : NSObject

@property (strong, nonatomic) NSString *objectId;
@property (strong, nonatomic) NSString *signalId;
@property (strong, nonatomic) NSString *text;
@property (strong, nonatomic) NSString *type;
@property (strong, nonatomic) NSDate *created;
@property (strong, nonatomic) NSString *authorName;
@property (strong, nonatomic) NSString *authorId;
@property (strong, nonatomic) NSURL *photoUrl;
@property (readonly, nonatomic) BOOL hasPhoto;

@end
