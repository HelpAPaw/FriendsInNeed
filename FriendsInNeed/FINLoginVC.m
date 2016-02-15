//
//  FINLoginVC.m
//  FriendsInNeed
//
//  Created by Milen on 11/02/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import "FINLoginVC.h"
#import "Backendless.h"

@interface FINLoginVC ()
@property (weak, nonatomic) IBOutlet UIScrollView *containerScrollView;
@property (strong, nonatomic) IBOutlet UIView *registrationView;
@property (strong, nonatomic) IBOutlet UIView *loginView;
@property (weak, nonatomic) IBOutlet UILabel *hintLabel;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UIButton *registerLoginButton;

@end

@implementation FINLoginVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [_containerScrollView addSubview:_registrationView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (IBAction)onRegisterLoginSwitch:(id)sender
{
    UISegmentedControl *segControl = (UISegmentedControl *)sender;
    
    [UIView transitionWithView:_containerScrollView duration:0.6f options:UIViewAnimationOptionTransitionFlipFromLeft animations:^{
        if (segControl.selectedSegmentIndex == 1)
        {
            [self setupLoginView];
        }
        else
        {
            [self setupRegistrationView];
        }
    } completion:^(BOOL finished){}];
}

- (void)setupRegistrationView
{
    _hintLabel.text = @"You need to register before you can submit signals";
    _nameLabel.hidden = NO;
    _nameTextField.hidden = NO;
    
    [UIView performWithoutAnimation:^{
        _registerLoginButton.titleLabel.text = @"Register";
        [_registerLoginButton layoutIfNeeded];
    }];
}

- (void)setupLoginView
{
    _hintLabel.text = @"Please enter your credentials";
    _nameLabel.hidden = YES;
    _nameTextField.hidden = YES;
    _registerLoginButton.titleLabel.text = @"Login";
}

- (IBAction)onCancelButton:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (IBAction)onRegisterButton:(id)sender
{
    //TODO: add input validation
    BackendlessUser *user = [BackendlessUser new];
    user.email = _emailTextField.text;
    user.name = _nameTextField.text;
    user.password = _passwordTextField.text;
    
    [backendless.userService registering:user response:^void (BackendlessUser *registeredUser){
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success!"
                                                                       message:@"You are now registered with Friends In Need and can submit signals."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [self dismissViewControllerAnimated:YES completion:nil];
                                                              }];
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:^{}];
    } error:^void (Fault *fault) {
        NSString *errorMessage = [NSString stringWithFormat:@"Something went wrong! Server said:\n%@", fault.message];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Ooops!"
                                                                       message:errorMessage
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                              }];
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:^{}];
    }];
}

@end
