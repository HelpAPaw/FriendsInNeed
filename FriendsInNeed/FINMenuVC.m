//
//  FINMenuVC.m
//  FriendsInNeed
//
//  Created by Milen on 29/10/16.
//  Copyright © 2016 Milen. All rights reserved.
//

#import "FINMenuVC.h"
#import "FINLoginVC.h"
#import <ViewDeck/ViewDeck.h>
#import "FINDataManager.h"
#import "FINMenuCell.h"
#import "FINAboutVC.h"
#import "FINMailComposer.h"
#import "FINFaqVC.h"
#import "Help_A_Paw-Swift.h"
#import "MBProgressHUD.h"

#define kMenuCell @"MenuCell"

@interface FINMenuVC () <UITableViewDataSource, UITableViewDelegate>

enum
{
    kLogin,
    kMySignals,
    kSettings,
    kFAQ,
    kFeedback,
    kPrivacyPolicy,
    kAbout,
    kShare,
    kMenuItemsCount
};

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;

@end

@implementation FINMenuVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [_tableView registerNib:[UINib nibWithNibName:@"FINMenuCell" bundle:nil] forCellReuseIdentifier:kMenuCell];
    
    UITapGestureRecognizer *adminVCtapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showAdminVC)];
    adminVCtapGR.numberOfTapsRequired = 7;
    _usernameLabel.userInteractionEnabled = YES;
    [_usernameLabel addGestureRecognizer:adminVCtapGR];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self refreshLoginStatus];
}

- (void)refreshLoginStatus
{
    [self setupUsernameLabel];
    [self reloadLoginCell];
}

- (void)setupUsernameLabel
{
    FINDataManager *dataManager = [FINDataManager sharedManager];
    if ([dataManager userIsLogged])
    {
        NSString *userName = [dataManager getUserName];
        NSString *userEmail = [dataManager getUserEmail];
        
        NSString *labelText;
        if ([InputValidator isValidEmail:userEmail])
        {
            labelText = [NSString stringWithFormat:@"%@ (%@)", userName, userEmail];
        }
        else
        {
            labelText = userName;
        }
        
        _usernameLabel.text = labelText;
        _usernameLabel.hidden = NO;
    }
    else
    {
        _usernameLabel.hidden = YES;
    }
}

- (void)reloadLoginCell
{
    NSIndexPath *loginIndexPath = [NSIndexPath indexPathForRow:kLogin inSection:0];
    [_tableView reloadRowsAtIndexPaths:@[loginIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return kMenuItemsCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FINMenuCell *cell = [tableView dequeueReusableCellWithIdentifier:kMenuCell];
    
    NSString *title;
    switch (indexPath.row)
    {
        case kLogin:
        {
            if ([[FINDataManager sharedManager] userIsLogged])
            {
                title = NSLocalizedString(@"Logout",nil);
            }
            else
            {
                title = NSLocalizedString(@"Login",nil);
            }
            break;
        }
        case kMySignals:
            title = NSLocalizedString(@"My Signals",nil);
            break;
        case kSettings:
            title = NSLocalizedString(@"Settings",nil);
            break;
        case kFAQ:
            title = NSLocalizedString(@"FAQ",nil);
            break;
        case kFeedback:
            title = NSLocalizedString(@"Feedback",nil);
            break;
        case kPrivacyPolicy:
            title = NSLocalizedString(@"Privacy Policy",nil);
            break;
        case kAbout:
            title = NSLocalizedString(@"About",nil);
            break;
        case kShare:
            title = NSLocalizedString(@"Share",nil);
            break;
            
        default:
            break;
    }
    
    [cell setTitle:title];
    
    cell.indentationLevel = 2;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row)
    {
        case kLogin:
        {
            if ([[FINDataManager sharedManager] userIsLogged])
            {
                MBProgressHUD *loadingIndicator = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                [[FINDataManager sharedManager] logoutWithCompletion:^(FINError *error) {
                    [loadingIndicator hideAnimated:YES];
                    if (error == nil) {
                        [self refreshLoginStatus];
                    } else {
                        [self showAlertViewControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                       message:error.message
                                                       actions:nil];
                    }
                }];
            }
            else
            {
                [self.viewDeckController closeSide:YES];
                
                FINLoginVC *loginVC = [[FINLoginVC alloc] init];
                loginVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
                [self presentViewController:loginVC animated:YES completion:^{}];
            }
            break;
        }
        case kMySignals:
        {
            if ([[FINDataManager sharedManager] userIsLogged]) {
                FINMySignalsVC *mySignalsVC = [[FINMySignalsVC alloc] initWithNibName:nil bundle:nil];
                mySignalsVC.modalPresentationStyle = UIModalPresentationFullScreen;
                [self presentViewController:mySignalsVC animated:YES completion:nil];
            }
            else {
                UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                 style:UIAlertActionStyleCancel
                                                               handler:nil];
                UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                                 style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * _Nonnull action) {
                    FINLoginVC *loginVC = [[FINLoginVC alloc] init];
                    loginVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
                    [self presentViewController:loginVC animated:YES completion:^{}];
                }];
                [self showAlertViewControllerWithTitle:@""
                                               message:NSLocalizedString(@"login_is_needed_to_view_section", nil)
                                               actions:@[cancel, ok]];
            }
            
            break;
        }
        case kSettings:
        {
            FINSettingsVC *settingsVC = [[FINSettingsVC alloc] initWithNibName:nil bundle:nil];
            UINavigationController *navC = [[UINavigationController alloc] initWithRootViewController:settingsVC];
            navC.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:navC animated:YES completion:nil];
            break;
        }
        case kFAQ:
        {
            FINFaqVC *facVC = [[FINFaqVC alloc] initWithNibName:nil bundle:nil];
            facVC.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:facVC animated:YES completion:nil];
            break;
        }
        case kFeedback:
        {
            [[FINMailComposer sharedComposer] presentMailComposerFrom:self];
            break;
        }
        case kPrivacyPolicy:
        {
            FINPrivacyPolicyVC *ppVC = [[FINPrivacyPolicyVC alloc] initWithNibName:nil bundle:nil];
            ppVC.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:ppVC animated:YES completion:nil];
            break;
        }
        case kAbout:
        {
            FINAboutVC *aboutVC = [[FINAboutVC alloc] initWithNibName:nil bundle:nil];
            aboutVC.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:aboutVC animated:YES completion:nil];
            break;
        }
        case kShare:
        {
            FINShareVC *aboutVC = [[FINShareVC alloc] initWithNibName:nil bundle:nil];
            aboutVC.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:aboutVC animated:YES completion:nil];
            break;
        }
          
        default:
            break;
    }
}

- (void)showAdminVC
{
    FINAdminVC *adminVC = [[FINAdminVC alloc] init];
    [self presentViewController:adminVC animated:true completion:nil];
}

@end
