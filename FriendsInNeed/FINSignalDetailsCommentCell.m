//
//  FINSignalDetailsCommentCell.m
//  FriendsInNeed
//
//  Created by Milen on 16/03/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import "FINSignalDetailsCommentCell.h"
#import <SDWebImage/SDWebImage.h>

@interface FINSignalDetailsCommentCell()

@property (weak, nonatomic) IBOutlet UILabel *lbAuthorLabel;
@property (weak, nonatomic) IBOutlet UILabel *lbDateLabel;
@property (weak, nonatomic) IBOutlet UITextView *tvCommentText;
@property (weak, nonatomic) IBOutlet UIView *vCellContainer;
@property (weak, nonatomic) IBOutlet UIImageView *sdImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *lcImageHeight;

@end

@implementation FINSignalDetailsCommentCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    self.vCellContainer.layer.cornerRadius = 5.0f;
    self.vCellContainer.layer.borderWidth = 1.0f;
    self.vCellContainer.layer.borderColor = [UIColor colorWithWhite:0.8f alpha:1.0f].CGColor;
    self.vCellContainer.layer.shadowOffset = CGSizeMake(0, 0);
//    self.vCellContainer.layer.shadowOpacity = 0.5;
    self.vCellContainer.layer.shadowColor = [UIColor colorWithWhite:0.8f alpha:1.0f].CGColor;
    self.backgroundColor = [UIColor clearColor];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void)setCommentText:(NSString *)text
{
    _tvCommentText.text = text;
}

- (void)setAuthor:(NSString *)author
{
    _lbAuthorLabel.text = author;
}

- (void)setDate:(NSString *)date
{
    _lbDateLabel.text = date;
}

- (void)setImageUrl:(NSURL *)imageUrl
{
    if (imageUrl != nil) {
        _lcImageHeight.constant = kCommentPhotoHeight;
        _sdImageView.sd_imageIndicator = SDWebImageActivityIndicator.grayIndicator;
        [_sdImageView sd_setImageWithURL:imageUrl placeholderImage:nil];
        
        UITapGestureRecognizer *tapGestureRecognizer =
        [[UITapGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(onImageTapped:)];
        _sdImageView.userInteractionEnabled = true;
        [_sdImageView setGestureRecognizers:@[tapGestureRecognizer]];
    }
    else {
        _lcImageHeight.constant = 0;
    }
}

- (void)onImageTapped:(UITapGestureRecognizer *)recognizer
{
    [_delegate onImageTapped:_sdImageView.image];
}

@end
