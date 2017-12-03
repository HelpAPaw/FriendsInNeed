//
//  MailComposer.m
//  FriendsInNeed
//
//  Created by Milen on 17/12/16.
//  Copyright © 2016 Milen. All rights reserved.
//

#import "FINMailComposer.h"

#define kContactEmail @"help.a.paw@outlook.com"

@implementation FINMailComposer

+ (id)sharedComposer
{
    static FINMailComposer *_sharedClient = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate,
                  ^{
                      _sharedClient = [[self alloc] init];
                  });
    
    return _sharedClient;
}

- (void)presentMailComposerFrom:(UIViewController *)viewController
{
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *composeViewController = [[MFMailComposeViewController alloc] initWithNibName:nil bundle:nil];
        [composeViewController setMailComposeDelegate:self];
        [composeViewController setToRecipients:@[kContactEmail]];
        
        [viewController presentViewController:composeViewController animated:YES completion:nil];
    }
    else
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Ooops!", nil)
                                                                       message:[NSString stringWithFormat:NSLocalizedString(@"Your mail client is not set up.\nYou can reach us at %@", nil), kContactEmail]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {}];
        [alert addAction:okAction];
        [viewController presentViewController:alert animated:YES completion:nil];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end
