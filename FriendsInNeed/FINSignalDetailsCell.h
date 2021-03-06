//
//  SignalDetailsCell.h
//  FriendsInNeed
//
//  Created by Milen on 14/03/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FINSignalPhotoDelegate
- (void)imageTapped:(UIImage*)image;
- (void)didTapUploadPhotoButton:(UIView *)sender;
@end

@interface FINSignalDetailsCell : UITableViewCell
@property (nonatomic, weak) id <FINSignalPhotoDelegate> delegate;

@property (strong, nonatomic) NSString *phoneNumber;

- (void)setTitle:(NSString *)title;
- (void)setType:(NSString *)typeString;
- (void)setAuthor:(NSString *)author;
- (void)setDate:(NSString *)date;
- (void)setPhoto:(UIImage *)photo;
- (void)setUploadPhotoButtonIsVisible:(BOOL)isVisible;

@end
