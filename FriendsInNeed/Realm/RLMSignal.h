//
//  RLMSignal.h
//  Help A Paw
//
//  Created by Milen on 04/06/19.
//  Copyright © 2019 Milen. All rights reserved.
//

#import <Realm/Realm.h>

NS_ASSUME_NONNULL_BEGIN

@interface RLMSignal : RLMObject

@property NSString *signalId;
@property BOOL      notificationShown;

@end

NS_ASSUME_NONNULL_END
