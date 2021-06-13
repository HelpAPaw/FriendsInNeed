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
#import <AuthenticationServices/AuthenticationServices.h>

#define REGISTER_SEGMENT    1
#define LOGIN_SEGMENT       0

@interface FINLoginVC () <ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding>
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
@property (weak, nonatomic) IBOutlet UIButton *forgotPasswordButton;
@property (weak, nonatomic) IBOutlet UITextField *phoneTextField;
@property (weak, nonatomic) IBOutlet UIButton *registerLoginButton;
@property (weak, nonatomic) IBOutlet UIView *facebookSeparatorView;
@property (weak, nonatomic) IBOutlet UIButton *facebookLoginButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

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
    
    [_containerStackView setCustomSpacing:20.0f afterView:_registerLoginButton];
    [_containerStackView setCustomSpacing:25.0f afterView:_facebookSeparatorView];
    
    [self setupSignInWithAppleButton];
    
    UITapGestureRecognizer* cGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onContainerTap:)];
    [self.view addGestureRecognizer:cGR];
}

- (void)setupSignInWithAppleButton
{
    if (@available(iOS 13.0, *)) {
        ASAuthorizationAppleIDButton *button = [[ASAuthorizationAppleIDButton alloc] init];
        // Using gesture recognizer instead of the built-in mechanism because of a bug:
        // https://stackoverflow.com/questions/63003840/sign-in-with-apple-button-not-firing-target-function
        UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSignInWithAppleButtonTapped)];
        [button addGestureRecognizer:tapGR];
//        [button addTarget:self action:@selector(onSignInWithAppleButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.containerStackView addArrangedSubview:button];
    }
}

- (void)setupScrollViewContentSize
{
    CGSize scrollSize = _containerScrollView.contentSize;
    scrollSize.height = _facebookLoginButton.frame.origin.y + _facebookLoginButton.frame.size.height + 20;
    _containerScrollView.contentSize = scrollSize;
}

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
            self.forgotPasswordButton.hidden = YES;
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
        self.forgotPasswordButton.hidden = NO;
        
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

- (IBAction)onForgotPasswordButton:(id)sender
{
    NSString *validationError = NSLocalizedString(@"enter_registration_email", nil);
    BOOL inputValidation = [InputValidator validateEmailFor:@[_emailTextField] message:validationError parent:self];
    if (!inputValidation)
    {
        return;
    }
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil];
    UIAlertAction *yes = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", nil)
                                                     style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
        [self resetPassword];
    }];
    [self showAlertViewControllerWithTitle:NSLocalizedString(@"Reset password", nil)
                                   message:NSLocalizedString(@"confirm_reset_password", nil)
                                   actions:@[cancel, yes]];
}

- (void)resetPassword
{
    [self.activityIndicator startAnimating];
    [[FINDataManager sharedManager] resetPasswordForEmail:self.emailTextField.text withCompletion:^(FINError *error) {
        [self.activityIndicator stopAnimating];
        if (error == nil) {
            [self showAlertViewControllerWithTitle:NSLocalizedString(@"Success!", nil)
                                           message:NSLocalizedString(@"password_reset_email_sent", nil)
                                           actions:nil];
        } else {
            [self showError:error.message];
        }
    }];
}

#pragma mark - Register and login with email and password

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
            [self showError:error.message];
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
                [self showError:error.message];
            }
        });
    }];
}

#pragma mark - Login with Facebook

- (IBAction)onLoginWithFacebookButton:(id)sender
{
    [_activityIndicator startAnimating];
    
    FBSDKLoginManager *fbLoginManager = [[FBSDKLoginManager alloc] init];
    [fbLoginManager logOut];
    [fbLoginManager logInWithPermissions: @[@"public_profile", @"email"]
                      fromViewController:self
                                 handler:^(FBSDKLoginManagerLoginResult * _Nullable result, NSError * _Nullable error) {
         if (error)
         {
             [self.activityIndicator stopAnimating];
             [self showError:error.localizedDescription];
         }
         else if (result.isCancelled)
         {
             [self.activityIndicator stopAnimating];
         }
         else
         {
             FBSDKAccessToken *token = [FBSDKAccessToken currentAccessToken];
             [[FINDataManager sharedManager] loginWithFacebookAccessToken:token.tokenString
                                                               completion:^(FINError *error) {
                 [self.activityIndicator stopAnimating];
                 
                 if (error != nil) {
                     [self showError:error.message];
                 } else {
                     [self askForPrivacyPolicyAcceptanceAfterLogin];
                 }
             }];
         }
     }];
}

#pragma mark - Sign In With Apple

- (void)onSignInWithAppleButtonTapped
{
    if (@available(iOS 13.0, *)) {
        ASAuthorizationAppleIDProvider *provider = [[ASAuthorizationAppleIDProvider alloc] init];
        ASAuthorizationAppleIDRequest *request = [provider createRequest];
        request.requestedScopes = @[ASAuthorizationScopeFullName, ASAuthorizationScopeEmail];
        
        ASAuthorizationController *controller = [[ASAuthorizationController alloc] initWithAuthorizationRequests:@[request]];
        controller.delegate = self;
        controller.presentationContextProvider = self;
        [controller performRequests];
    }
}

- (ASPresentationAnchor)presentationAnchorForAuthorizationController:(ASAuthorizationController *)controller API_AVAILABLE(ios(13.0));
{
    return self.view.window;
}

- (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithAuthorization:(ASAuthorization *)authorization
API_AVAILABLE(ios(13.0))
{
    ASAuthorizationAppleIDCredential *appleIdCredential = authorization.credential;
    NSData *identityToken = appleIdCredential.identityToken;
    NSString *tokenString = [[NSString alloc] initWithData:identityToken encoding:NSUTF8StringEncoding];
    if (tokenString != nil) {
        [self.activityIndicator startAnimating];
        [[FINDataManager sharedManager] loginWithAppleToken:tokenString
                                                 completion:^(FINError *error) {
            [self.activityIndicator stopAnimating];
            
            if (error != nil) {
                [self showError:error.message];
            } else {
                [self askForPrivacyPolicyAcceptanceAfterLogin];
            }
        }];
    }
}

- (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithError:(NSError *)error
API_AVAILABLE(ios(13.0))
{
    [self showError:error.localizedDescription];
}

#pragma mark - Other

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

- (void)showError:(NSString *)error
{
    NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(@"Something went wrong! Server said:\n%@",nil), error];
    
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

@end
