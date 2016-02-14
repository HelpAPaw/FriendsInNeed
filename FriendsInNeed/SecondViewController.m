//
//  SecondViewController.m
//  FriendsInNeed
//
//  Created by Milen on 21/11/15.
//  Copyright © 2015 г. Milen. All rights reserved.
//

#import "SecondViewController.h"
#import "FINLocationManager.h"
#import "Backendless.h"
#import "FINLoginVC.h"

@interface SecondViewController ()
@property (weak, nonatomic) IBOutlet UITextField *titleTextField;

@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onBackgroundTap:)];
    [self.view addGestureRecognizer:tapGR];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onBackgroundTap:(UITapGestureRecognizer *)gr
{
    [_titleTextField resignFirstResponder];
}

- (IBAction)onSubmitSignal:(id)sender
{
    CLLocation *userLocation = [[FINLocationManager sharedManager] getLastKnownUserLocation];
    
//    BackendlessUser *currentUser = [backendless.userService login:@"milen@kanbanize.com" password:@"fuckingshit"];
    BackendlessUser *currentUser = backendless.userService.currentUser;
    if (!currentUser)
    {
        [self showLoginScreen];
        return;
    }
    
    Responder *responder = [Responder responder:self selResponseHandler:@selector(geoPointSaved:) selErrorHandler:@selector(errorHandler:)];
    GEO_POINT coordinate;
    coordinate.latitude = userLocation.coordinate.latitude;
    coordinate.longitude = userLocation.coordinate.longitude;
    NSDictionary *geoPointMeta = @{@"name":_titleTextField.text, @"author":currentUser};
    GeoPoint *point = [GeoPoint geoPoint:coordinate categories:nil metadata:geoPointMeta];
    [backendless.geoService savePoint:point responder:responder];
    
    [_titleTextField setText:@""];
    [_titleTextField resignFirstResponder];
}

- (void)geoPointSaved:(GeoPoint *)response
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Thank you!"
                                                                   message:@"Your signal was submitted."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              [self dismissViewControllerAnimated:YES completion:nil];
                                                              self.tabBarController.selectedIndex = 0;
                                                          }];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:^{}];
    [[FINLocationManager sharedManager] addNewSignal:response];
}

- (void)errorHandler:(Fault *)fault
{
    NSLog(@"%@", fault.description);
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Ooops!"
                                                                   message:[NSString stringWithFormat:@"Something went wrong! Server said:\n%@", fault.description]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              [self dismissViewControllerAnimated:YES completion:nil];
                                                          }];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:^{}];
}

- (void)showLoginScreen
{
    FINLoginVC *loginVC = [[FINLoginVC alloc] init];
    loginVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [self presentViewController:loginVC animated:YES completion:^{}];
    
    [self.tabBarController setSelectedIndex:0];
}

@end
