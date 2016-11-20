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

@end

@implementation FINMenuVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kMenuCell];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMenuCell];
    
    NSString *title;
    switch (indexPath.row)
    {
        case kLogin:
            title = @"Login";
            break;
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
    cell.textLabel.text = title;
    
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = [UIColor whiteColor];
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
            [self.viewDeckController closeSide:YES];
            
            FINLoginVC *loginVC = [[FINLoginVC alloc] init];
            loginVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            [self presentViewController:loginVC animated:YES completion:^{}];
            break;
        }
            
        default:
            break;
    }
}

@end
