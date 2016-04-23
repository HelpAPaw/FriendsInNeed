//
//  SignalDetailsCell.h
//  FriendsInNeed
//
//  Created by Milen on 14/03/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FINSignalDetailsCell : UITableViewCell

@property (strong, nonatomic) NSString *phoneNumber;

- (void)setTitle:(NSString *)title;
- (void)setAuthor:(NSString *)author;
- (void)setDate:(NSString *)date;
- (void)setPhoto:(UIImage *)photo;

@end
