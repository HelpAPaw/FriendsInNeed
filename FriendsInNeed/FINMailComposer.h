//
//  MailComposer.h
//  FriendsInNeed
//
//  Created by Milen on 17/12/16.
//  Copyright © 2016 Milen. All rights reserved.
//

#ifndef FINMailComposer_h
#define FINMailComposer_h

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>

@interface FINMailComposer : NSObject <MFMailComposeViewControllerDelegate>

+ (id)sharedComposer;
- (void)presentMailComposerFrom:(UIViewController *)viewController;

@end

#endif /* MailComposer_h */
