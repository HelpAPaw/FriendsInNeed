//
//  FINAboutVC.m
//  FriendsInNeed
//
//  Created by Milen on 17/12/16.
//  Copyright © 2016 Milen. All rights reserved.
//

#import "FINAboutVC.h"
#import "FINMailComposer.h"

@interface FINAboutVC ()
@property (weak, nonatomic) IBOutlet UIView *toolbar;

@end

@implementation FINAboutVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    _toolbar.layer.shadowColor = [UIColor lightGrayColor].CGColor;
    _toolbar.layer.shadowOpacity = 1.0f;
    _toolbar.layer.shadowOffset = (CGSize){0.0f, 2.0f};
}

- (IBAction)onCloseButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onContactButtonTapped:(id)sender {
    [[FINMailComposer sharedComposer] presentMailComposerFrom:self];
}

@end
