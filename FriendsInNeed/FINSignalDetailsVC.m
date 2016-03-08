//
//  FINSignalDetailsVC.m
//  FriendsInNeed
//
//  Created by Milen on 08/03/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import "FINSignalDetailsVC.h"
#import "FINDataManager.h"

#define kCellIndexTitle     0
#define kCellIndexAuthor    1
#define kCellIndexDate      2

#define kCellIdentifierTitle    @"TitleCell"
#define kCellIdentifierAuthor   @"AuthorCell"
#define kCellIdentifierDate     @"DateCell"

@interface FINSignalDetailsVC () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) GeoPoint *geoPoint;

@end

@implementation FINSignalDetailsVC

- (FINSignalDetailsVC *)initWithGeoPoint:(GeoPoint *)geoPoint
{
    self = [self init];
    
    _geoPoint = geoPoint;
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _tableView.contentInset = UIEdgeInsetsMake(_toolbar.frame.size.height, 0.0f, 0.0f, 0.0f);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - TableView data source and delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    switch (indexPath.row)
    {
        case kCellIndexTitle:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifierTitle];
            if (!cell)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:kCellIdentifierTitle];
                cell.backgroundColor = [UIColor clearColor];
            }
            
            cell.textLabel.text = @"Title";
            cell.detailTextLabel.text = [_geoPoint.metadata objectForKey:kSignalTitleKey];
        }
            break;
            
        case kCellIndexAuthor:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifierAuthor];
            if (!cell)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:kCellIdentifierAuthor];
                cell.backgroundColor = [UIColor clearColor];
            }
            
            cell.textLabel.text = @"Author";
            BackendlessUser *author = [_geoPoint.metadata objectForKey:kSignalAuthorKey];
            cell.detailTextLabel.text = author.name;
        }
            break;
            
        case kCellIndexDate:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifierDate];
            if (!cell)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:kCellIdentifierDate];
                cell.backgroundColor = [UIColor clearColor];
            }
            
            cell.textLabel.text = @"Submitted on";
            cell.detailTextLabel.text = [_geoPoint.metadata objectForKey:kSignalDateSubmittedKey];
        }
            break;
            
        default:
            break;
    }
    
    return cell;
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (IBAction)onCloseButton:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}

@end
