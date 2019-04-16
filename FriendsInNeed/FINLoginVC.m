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
#import "FINError.h"
#import "Help_A_Paw-Swift.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

#define REGISTER_SEGMENT    1
#define LOGIN_SEGMENT       0

@interface FINLoginVC ()
@property (weak, nonatomic) IBOutlet CustomToolbar *topToolbar;
@property (weak, nonatomic) IBOutlet UIView *toolbarBackground;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;
@property (weak, nonatomic) IBOutlet UIStackView *containerStackView;
@property (weak, nonatomic) IBOutlet UIScrollView *containerScrollView;
@property (weak, nonatomic) IBOutlet UILabel *hintLabel;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet UIButton *whyButton;
@property (weak, nonatomic) IBOutlet UITextField *phoneTextField;
@property (weak, nonatomic) IBOutlet UIButton *registerLoginButton;
@property (weak, nonatomic) IBOutlet UIView *facebookSeparatorView;
@property (weak, nonatomic) IBOutlet UIButton *facebookLoginButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topToolbarTopConstraint;

@end

@implementation FINLoginVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [_topToolbar setBarTintColor:kCustomOrange];
    [_toolbarBackground setBackgroundColor:kCustomOrange];
    [_registerLoginButton setTintColor:kCustomOrange];
    
    _containerScrollView.contentInset = UIEdgeInsetsMake(10.0f, 0.0f, 25.0f, 0.0f);
    
    if (@available(iOS 11, *))
    {
        [_containerStackView setCustomSpacing:20.0f afterView:_registerLoginButton];
        [_containerStackView setCustomSpacing:25.0f afterView:_facebookSeparatorView];
    }
    else
    {        
        _topToolbarTopConstraint.constant = 20.0f;
    }
    
    UITapGestureRecognizer* cGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onContainerTap:)];
    [self.view addGestureRecognizer:cGR];
}

- (void)setupScrollViewContentSize
{
    CGSize scrollSize = _containerScrollView.contentSize;
    scrollSize.height = _facebookLoginButton.frame.origin.y + _facebookLoginButton.frame.size.height + 20;
    _containerScrollView.contentSize = scrollSize;
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
    
    if (segControl.selectedSegmentIndex == LOGIN_SEGMENT)
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
        self.hintLabel.text = NSLocalizedString(@"Become a member", nil);
        self.nameLabel.hidden = NO;
        self.nameTextField.hidden = NO;
        self.phoneLabel.hidden = NO;
        self.phoneTextField.hidden = NO;
        self.whyButton.hidden = NO;
        
        [UIView performWithoutAnimation:^{
            //For immediate change
            self.registerLoginButton.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Register", nil)];
            //To keep the title after state changes (e.g. user taps)
            [self.registerLoginButton setTitle:NSLocalizedString(@"Register", nil) forState:UIControlStateNormal];
            [self.registerLoginButton layoutIfNeeded];
        }];
        
        self.passwordTextField.returnKeyType = UIReturnKeyNext;
    } completion:^(BOOL finished){
        if (finished)
        {
            [self setupScrollViewContentSize];
        }
    }];
}

- (void)setupLoginView
{
    [UIView transitionWithView:_containerScrollView duration:0.6f options:UIViewAnimationOptionTransitionFlipFromRight animations:^{
        self.hintLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Please enter your credentials", nil)];
        self.nameLabel.hidden = YES;
        self.nameTextField.hidden = YES;
        self.phoneLabel.hidden = YES;
        self.phoneTextField.hidden = YES;
        self.whyButton.hidden = YES;
        
        //For immediate change
        self.registerLoginButton.titleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Login", nil)];
        //To keep the title after state changes (e.g. user taps)
        [self.registerLoginButton setTitle:NSLocalizedString(@"Login", nil) forState:UIControlStateNormal];
        
        self.passwordTextField.returnKeyType = UIReturnKeyGo;
        
        if ([self.nameTextField isFirstResponder])
        {
            [self.nameTextField resignFirstResponder];
        }
        else if ([self.phoneTextField isFirstResponder])
        {
            [self.phoneTextField resignFirstResponder];
        }
    } completion:^(BOOL finished){
        if (finished)
        {
            [self setupScrollViewContentSize];
        }
    }];
}

- (IBAction)onCancelButton:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (IBAction)onLoginButton:(id)sender
{
    [_activityIndicator startAnimating];
    
    FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
    [login logInWithReadPermissions: @[@"public_profile"]
                 fromViewController:self
                            handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
         if (error) {
             [self.activityIndicator stopAnimating];
             NSLog(@"Process error");
         } else if (result.isCancelled) {
             [self.activityIndicator stopAnimating];
             NSLog(@"Cancelled");
         } else {
             @try {
                 FBSDKAccessToken *token = [FBSDKAccessToken currentAccessToken];
                 NSString *userId = token.userID;
                 NSString *tokenString = token.tokenString;
                 NSDate *expirationDate = token.expirationDate;
                 NSDictionary *fieldsMapping = @{@"email":@"email"};
                 BackendlessUser *user = [backendless.userService loginWithFacebookSDK:userId tokenString:tokenString expirationDate:expirationDate fieldsMapping:fieldsMapping];
                 [self.activityIndicator stopAnimating];
                 
                 [self askForPrivacyPolicyAcceptanceAfterLogin];
                 
                 NSLog(@"USER: %@", user);
             }
             @catch (Fault *fault) {
                 [self.activityIndicator stopAnimating];
                 NSLog(@"fault: %@", fault);
             }
             
             NSLog(@"Logged in");
         }
     }];
}

-(void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:^{
        NSLog(@"Dismiss completed");
    }];
}

- (IBAction)onRegisterButton:(id)sender
{
    if (_segmentControl.selectedSegmentIndex == REGISTER_SEGMENT)
    {
        NSString *validationError = NSLocalizedString(@"Please fill all required fields", nil);
        BOOL inputValidation = [InputValidator validateGeneralInputFor:@[_passwordTextField, _nameTextField] message:validationError parent:self];
        inputValidation &= [InputValidator validateEmailFor:@[_emailTextField] message:validationError parent:self];
        if (!inputValidation)
        {
            return;
        }
        
        [self showPrivacyPolicyWithAcceptHandler:^(UIAlertAction *action) {
            [self register];
        }
                               andDeclineHandler:nil];
    }
    else
    {
        NSString *validationError = NSLocalizedString(@"Please fill all required fields", nil);
        BOOL inputValidation = [InputValidator validateGeneralInputFor:@[_passwordTextField] message:validationError parent:self];
        inputValidation &= [InputValidator validateEmailFor:@[_emailTextField] message:validationError parent:self];
        if (!inputValidation)
        {
            return;
        }
        
        [self login];
    }
}

- (void)showPrivacyPolicyWithAcceptHandler:(void (^)(UIAlertAction *action))acceptHandler andDeclineHandler:(void (^)(UIAlertAction *action))declineHandler
{
    [_activityIndicator startAnimating];
    
    NSError *error;
    NSString *privacyPolicyHtml = [NSString stringWithContentsOfURL:[NSURL URLWithString:[SharedConstants kPrivacyPolicyUrl]]
                                                           encoding:NSUTF8StringEncoding
                                                              error:&error];
    NSAttributedString *privacyPolicyAttributedString = [[NSAttributedString alloc] initWithData:[privacyPolicyHtml dataUsingEncoding:NSUTF8StringEncoding]
                                                                                         options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                                                                   NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)}
                                                                              documentAttributes:nil
                                                                                           error:&error];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert setValue:privacyPolicyAttributedString forKey:@"attributedMessage"];
    [alert addAction:[UIAlertAction actionWithTitle:@"Decline" style:UIAlertActionStyleDestructive handler:declineHandler]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Accept" style:UIAlertActionStyleDefault handler:acceptHandler]];
    
    [self presentViewController:alert animated:YES completion:^{}];
    
    [_activityIndicator stopAnimating];
}

- (void)register
{
    [_activityIndicator startAnimating];
    _registerLoginButton.enabled = NO;
    
    [[FINDataManager sharedManager] registerUser:_nameTextField.text withEmail:_emailTextField.text
                                        password:_passwordTextField.text
                                     phoneNumber:_phoneTextField.text
                                      completion:^(FINError *error) {
        
        [self.activityIndicator stopAnimating];
        self.registerLoginButton.enabled = YES;
        
        if (!error)
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Success!", nil)
                                                                           message:NSLocalizedString(@"A confirmation link has been sent on your email. Please click it to complete your registration.",nil)
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                      [self setupLoginView];
                                                                      [self.segmentControl setSelectedSegmentIndex:LOGIN_SEGMENT];
                                                                  }];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:^{}];
        }
        else
        {
            NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(@"Something went wrong! Server said:\n%@",nil), error.message];
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Ooops!", nil)
                                                                           message:errorMessage
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                  }];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:^{}];
        }
    }];
}

- (void)login
{
    [_activityIndicator startAnimating];
    _registerLoginButton.enabled = NO;
    
    [[FINDataManager sharedManager] loginWithEmail:_emailTextField.text andPassword:_passwordTextField.text completion:^(FINError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.activityIndicator stopAnimating];
            self.registerLoginButton.enabled = YES;
            
            if (!error)
            {
                [self askForPrivacyPolicyAcceptanceAfterLogin];
            }
            else
            {
                NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(@"Something went wrong! Server said:\n%@",nil), error.message];
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Ooops!",nil)
                                                                               message:errorMessage
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                                        style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction * action) {
                                                                      }];
                [alert addAction:defaultAction];
                [self presentViewController:alert animated:YES completion:^{}];
            }
        });
    }];
}

- (void)askForPrivacyPolicyAcceptanceAfterLogin {
    // Show PP only if it hasn't been accepted
    if ([[FINDataManager sharedManager] getUserHasAcceptedPrivacyPolicy])
    {
        [self dismissViewControllerAnimated:YES completion:^{}];
        return;
    }
    
    [self showPrivacyPolicyWithAcceptHandler:^(UIAlertAction *action) {
        
        [[FINDataManager sharedManager] setUserHasAcceptedPrivacyPolicy:YES];
        [self dismissViewControllerAnimated:YES completion:^{}];
    }
                           andDeclineHandler:^(UIAlertAction *action) {
                               [[FINDataManager sharedManager] logoutWithCompletion:^(FINError *error) {
                                   //Do nothing
                               }];
                           }];
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
        [_phoneTextField becomeFirstResponder];
    }
    else if (textField == _phoneTextField)
    {
        [textField resignFirstResponder];
        // We are obviously in register mode so do register
        [self onRegisterButton:_registerLoginButton];
    }
    
    return YES;
}

- (IBAction)onWhyPhoneButton:(id)sender
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Why do you want my phone number?",nil)
                                                                   message:NSLocalizedString(@"Entering your phone number is not required for registration. However, we strongly encourage you to fill it so you can be quickly reached if a volunteer needs information about a signal that you submitted.",nil)
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"I see",nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:^{}];
}

@end
