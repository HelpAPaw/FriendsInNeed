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

#define kMenuCell @"MenuCell"

@interface FINMenuVC () <UITableViewDataSource, UITableViewDelegate>

enum
{
    kLogin,
    kSettings,
    kFAQ,
    kFeedback,
    kAbout,
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
        _usernameLabel.text = [NSString stringWithFormat:@"%@ (%@)", userName, userEmail];
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
//    if (cell == nil)
//    {
//        cell = [FINMenuCell ini]
//    }
    
    NSString *title;
    switch (indexPath.row)
    {
        case kLogin:
        {
            if ([[FINDataManager sharedManager] userIsLogged])
            {
                title = @"Logout";
            }
            else
            {
                title = @"Login";
            }
            break;
        }
        case kSettings:
            title = @"Settings";
            break;
        case kFAQ:
            title = @"FAQ";
            break;
        case kFeedback:
            title = @"Feedback";
            break;
        case kAbout:
            title = @"About";
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
                // TODO: add loading indicator
                [[FINDataManager sharedManager] logoutWithCompletion:^(FINError *error) {
                    // TODO: handle error
                    
                    [self refreshLoginStatus];
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
            
        default:
            break;
    }
}

@end
