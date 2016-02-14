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
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;

@end

@implementation FINLoginVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    //TODO: add support for landscape orientation
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)onCancelButton:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
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
