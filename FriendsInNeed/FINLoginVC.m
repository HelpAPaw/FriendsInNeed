//
//  FINLoginVC.m
//  FriendsInNeed
//
//  Created by Milen on 11/02/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import "FINLoginVC.h"
#import "FINDataManager.h"
#import "FINGlobalConstants.pch"

#define REGISTER_SEGMENT    0
#define LOGIN_SEGMENT       1

@interface FINLoginVC ()
@property (weak, nonatomic) IBOutlet UIToolbar *topToolbar;
@property (weak, nonatomic) IBOutlet UIView *toolbarBackground;
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
    [_topToolbar setBarTintColor:kCustomOrange];
    [_toolbarBackground setBackgroundColor:kCustomOrange];
    
    UITapGestureRecognizer* cGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onContainerTap:)];
    [self.view addGestureRecognizer:cGR];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Gesture Recognizers
- (void)onContainerTap:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        [self.view endEditing:YES];
    }
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
        
        _passwordTextField.returnKeyType = UIReturnKeyNext;
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
        
        _passwordTextField.returnKeyType = UIReturnKeyGo;
        
        if ([_nameTextField isFirstResponder])
        {
            [_nameTextField resignFirstResponder];
        }
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
        
        [_activityIndicator startAnimating];
        _registerLoginButton.enabled = NO;
        
        [[FINDataManager sharedManager] registerUser:_nameTextField.text withEmail:_emailTextField.text andPassword:_passwordTextField.text completion:^(Fault *fault) {
            
            [_activityIndicator stopAnimating];
            _registerLoginButton.enabled = YES;
            
            if (!fault)
            {
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
            }
            else
            {
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
            }
        }];
    }
    else
    {
        [_activityIndicator startAnimating];
        _registerLoginButton.enabled = NO;
        
        [[FINDataManager sharedManager] loginWithEmail:_emailTextField.text andPassword:_passwordTextField.text completion:^(Fault *fault) {
            
            [_activityIndicator stopAnimating];
            _registerLoginButton.enabled = YES;
            
            if (!fault)
            {
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
            }
            else 
            {
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
            }
        }];
    }
}

#pragma mark - UITextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == _emailTextField)
    {
        [textField resignFirstResponder];
        [_passwordTextField becomeFirstResponder];
    }
    else if (textField == _passwordTextField)
    {
        [textField resignFirstResponder];
        
        // If in register mode, go to name text field
        if (_segmentControl.selectedSegmentIndex == REGISTER_SEGMENT)
        {
            [_nameTextField becomeFirstResponder];
        }
        // If in login mode do login
        else
        {
            [self onRegisterButton:_registerLoginButton];
        }
    }
    else if (textField == _nameTextField)
    {
        [textField resignFirstResponder];
        // We are obviously in register mode so do register
        [self onRegisterButton:_registerLoginButton];
    }
    
    return YES;
}

@end
