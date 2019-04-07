//
//  FINAboutVC.m
//  FriendsInNeed
//
//  Created by Milen on 17/12/16.
//  Copyright © 2016 Milen. All rights reserved.
//

#import "FINAboutVC.h"
#import "FINMailComposer.h"
#import "FINGlobalConstants.pch"

@interface FINAboutVC ()
@property (weak, nonatomic) IBOutlet UIView *toolbar;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UILabel *appNameLabel;

@end

@implementation FINAboutVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    _toolbar.layer.shadowColor = [UIColor lightGrayColor].CGColor;
    _toolbar.layer.shadowOpacity = 1.0f;
    _toolbar.layer.shadowOffset = (CGSize){0.0f, 2.0f};
    
    _appNameLabel.layer.shadowColor = kCustomOrange.CGColor;
    _appNameLabel.layer.shadowOpacity = 1.0f;
    _appNameLabel.layer.shadowOffset = (CGSize){0.0f, 0.0f};
    
    // Set the version label text
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
    NSString *build = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey];
    _versionLabel.text = [NSString stringWithFormat:@"v%@ (%@)", version, build];
}

- (IBAction)onCloseButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onContactButtonTapped:(id)sender {
    [[FINMailComposer sharedComposer] presentMailComposerFrom:self];
}

@end
