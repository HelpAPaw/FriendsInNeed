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

@interface SecondViewController ()
@property (weak, nonatomic) IBOutlet UITextField *titleTextField;

@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onSubmitSignal:(id)sender
{
    CLLocation *userLocation = [[FINLocationManager sharedManager] getLastKnownUserLocation];
    
    Responder *responder = [Responder responder:self selResponseHandler:@selector(geoPointSaved: ) selErrorHandler:@selector(errorHandler:)];
    GEO_POINT coordinate;
    coordinate.latitude = userLocation.coordinate.latitude;
    coordinate.longitude = userLocation.coordinate.longitude;
    NSDictionary *geoPointMeta = @{@"name":_titleTextField.text};
    GeoPoint *point = [GeoPoint geoPoint:coordinate categories:nil metadata:geoPointMeta];
    [backendless.geoService savePoint:point responder:responder];
}

- (void)geoPointSaved:(GeoPoint *)response
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success!"
                                                                   message:@"You have successfully submitted your first signal! Congratulations!"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Cool!"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              [self dismissViewControllerAnimated:YES completion:nil];
                                                          }];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:^{}];
}

- (void)errorHandler:(Fault *)fault
{
    NSLog(@"%@", fault.description);
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Fuck!"
                                                                   message:[NSString stringWithFormat:@"Something went wrong! Server said:\n%@", fault.description]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Ooook..."
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              [self dismissViewControllerAnimated:YES completion:nil];
                                                          }];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:^{}];
}

@end
