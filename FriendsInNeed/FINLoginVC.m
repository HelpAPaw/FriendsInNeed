//
//  FINLoginVC.m
//  FriendsInNeed
//
//  Created by Milen on 11/02/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import "FINLoginVC.h"
#import "Backendless.h"

#define REGISTER_SEGMENT    0
#define LOGIN_SEGMENT       1

@interface FINLoginVC ()
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;
@property (weak, nonatomic) IBOutlet UIScrollView *containerScrollView;
@property (weak, nonatomic) IBOutlet UILabel *hintLabel;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UIButton *registerLoginButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation FINLoginVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
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
    
    if (segControl.selectedSegmentIndex == 1)
    {
        [self setupLoginView];
    }
    else
    {
        [self setupRegistrationView];
    }
}

- (void)setupRegistrationView
{
    [UIView transitionWithView:_containerScrollView duration:0.6f options:UIViewAnimationOptionTransitionFlipFromLeft animations:^{
        _hintLabel.text = @"You need to register before you can submit signals";
        _nameLabel.hidden = NO;
        _nameTextField.hidden = NO;
        
        [UIView performWithoutAnimation:^{
            //For immediate change
            _registerLoginButton.titleLabel.text = @"Register";
            //To keep the title after state changes (e.g. user taps)
            [_registerLoginButton setTitle:@"Register" forState:UIControlStateNormal];
            [_registerLoginButton layoutIfNeeded];
        }];
    } completion:^(BOOL finished){}];
}

- (void)setupLoginView
{
    [UIView transitionWithView:_containerScrollView duration:0.6f options:UIViewAnimationOptionTransitionFlipFromRight animations:^{
        _hintLabel.text = @"Please enter your credentials";
        _nameLabel.hidden = YES;
        _nameTextField.hidden = YES;
        //For immediate change
        _registerLoginButton.titleLabel.text = @"Login";
        //To keep the title after state changes (e.g. user taps)
        [_registerLoginButton setTitle:@"Login" forState:UIControlStateNormal];
    } completion:^(BOOL finished){}];
}

- (IBAction)onCancelButton:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (IBAction)onRegisterButton:(id)sender
{
    if (_segmentControl.selectedSegmentIndex == REGISTER_SEGMENT)
    {
        //TODO: add input validation
        BackendlessUser *user = [BackendlessUser new];
        user.email = _emailTextField.text;
        user.name = _nameTextField.text;
        user.password = _passwordTextField.text;
        
        [_activityIndicator startAnimating];
        _registerLoginButton.enabled = NO;
        
        [backendless.userService registering:user response:^void (BackendlessUser *registeredUser) {
            [_activityIndicator stopAnimating];
            _registerLoginButton.enabled = YES;
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success!"
                                                                           message:@"A confirmation link has been sent on your email. Please click it to complete your registration."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                      [self setupLoginView];
                                                                      [_segmentControl setSelectedSegmentIndex:LOGIN_SEGMENT];
                                                                  }];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:^{}];
        } error:^void (Fault *fault) {
            [_activityIndicator stopAnimating];
            _registerLoginButton.enabled = YES;
            
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
    else
    {
        [_activityIndicator startAnimating];
        _registerLoginButton.enabled = NO;
        
        [backendless.userService login:_emailTextField.text password:_passwordTextField.text response:^void (BackendlessUser *loggeduser) {
            [_activityIndicator stopAnimating];
            _registerLoginButton.enabled = YES;
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success!"
                                                                           message:@"You are now logged in and can submit signals."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                      [self dismissViewControllerAnimated:YES completion:^{}];
                                                                  }];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:^{}];
        } error:^void (Fault *fault) {
            [_activityIndicator stopAnimating];
            _registerLoginButton.enabled = YES;
            
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
}

@end
