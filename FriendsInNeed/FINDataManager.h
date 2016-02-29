//
//  FINDataManager.h
//  FriendsInNeed
//
//  Created by Milen on 29/02/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kSignalTitleKey         @"title"
#define kSignalAuthorKey        @"author"
#define kSignalDateSubmittedKey @"dateSubmitted"

@interface FINDataManager : NSObject

+ (id)sharedManager;

@property (strong, nonatomic) NSDateFormatter *signalDateFormatter;

@end
