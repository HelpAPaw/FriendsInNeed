//
//  FINSignalDetailsVC.m
//  FriendsInNeed
//
//  Created by Milen on 08/03/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import "FINSignalDetailsVC.h"
#import "FINDataManager.h"
#import "FINSignalDetailsCell.h"

#define kTitleIndex     0
#define kAuthorIndex    1
#define kDateIndex      2

#define kTitleLabel     @"Title"
#define kAuthorLabel    @"Author"
#define kDateLabel      @"Date"

#define kCellIdentifierGeneral    @"GeneralCell"
#define kCellIdentifierDetails    @"DetailsCell"


#define kCellIdentifierTitle    @"TitleCell"
#define kCellIdentifierAuthor   @"AuthorCell"
#define kCellIdentifierDate     @"DateCell"

@interface FINSignalDetailsVC () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIView *detailsView;

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
    [_tableView registerNib:[UINib nibWithNibName:@"FINSignalDetailsCell" bundle:nil] forCellReuseIdentifier:kCellIdentifierDetails];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

#pragma mark - TableView data source and delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
//{
//    UILabel *label = [[UILabel alloc] init];
//    label.textColor = [UIColor grayColor];
//    [label sizeToFit];
//    
//    NSString *labelText = @"";
//    switch (section) {
//        case kTitleIndex:
//            labelText = kTitleLabel;
//            break;
//        case kAuthorIndex:
//            labelText = kAuthorLabel;
//            break;
//        case kDateIndex:
//            labelText = kDateLabel;
//            break;
//            
//        default:
//            break;
//    }
//    
//    label.text = labelText;
//    
//    CGRect containerFrame = label.frame;
//    containerFrame.size.height += 10;
//    containerFrame.size.width  += 10;
//    UIView *container = [[UIView alloc] initWithFrame:containerFrame];
////    container.backgroundColor = [UIColor blueColor];
//    
//    [container addSubview:label];
//    
//    return container;
//}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    switch (indexPath.row) {
        case 0:
        {
            FINSignalDetailsCell *detailsCell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifierDetails];
            if (!detailsCell)
            {
                detailsCell = [[FINSignalDetailsCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifierDetails];
                detailsCell.backgroundColor = [UIColor clearColor];
                detailsCell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            
            cell = detailsCell;
        }
            break;
        case 1:
            cell.textLabel.text = @"I'm here but I don't see the dog...";
        case 2:
            cell.textLabel.text = @"Found it! Now I need a car! Somebody?";
        case 3:
            cell.textLabel.text = @"I'm coming!";
            
        default:
            break;
    }
    
//    NSString *cellText = @"";
//    switch (indexPath.section)
//    {
//        case kTitleIndex:
//            cellText = [_geoPoint.metadata objectForKey:kSignalTitleKey];
//            break;
//            
//        case kAuthorIndex:
//        {
//            BackendlessUser *user = [_geoPoint.metadata objectForKey:kSignalAuthorKey];
//            cellText = user.name;
//        }
//            break;
//            
//        case kDateIndex:
//            cellText = [_geoPoint.metadata objectForKey:kSignalDateSubmittedKey];
//            break;
//            
//        default:
//            break;
//    }
//    
//    cell.textLabel.text = cellText;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    return 150.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
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
