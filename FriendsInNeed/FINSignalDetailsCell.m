//
//  SignalDetailsCell.m
//  FriendsInNeed
//
//  Created by Milen on 14/03/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import "FINSignalDetailsCell.h"

@interface FINSignalDetailsCell ()

@property (weak, nonatomic) IBOutlet UIImageView *imgPhotoView;
@property (weak, nonatomic) IBOutlet UILabel *lbPhotoNumber;
@property (weak, nonatomic) IBOutlet UILabel *lbTitle;
@property (weak, nonatomic) IBOutlet UILabel *lbAuthor;
@property (weak, nonatomic) IBOutlet UILabel *lbDate;
@property (weak, nonatomic) IBOutlet UIButton *btnCall;

@end

@implementation FINSignalDetailsCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if(self)
    {
        //Changes here after init'ing self
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.backgroundColor = [UIColor clearColor];
    _imgPhotoView.layer.cornerRadius = 5.0f;
    _imgPhotoView.layer.borderWidth = 0.5f;
    _imgPhotoView.layer.borderColor = [UIColor blackColor].CGColor;
    
    _lbPhotoNumber.layer.cornerRadius = _lbPhotoNumber.frame.size.height / 2;
    _lbPhotoNumber.layer.borderWidth = 0.5f;
    _lbPhotoNumber.layer.borderColor = [UIColor blackColor].CGColor;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setTitle:(NSString *)title
{
    _lbTitle.text = title;
}

- (void)setAuthor:(NSString *)author
{
    _lbAuthor.text = [NSString stringWithFormat:@"%@", author];
}

- (void)setDate:(NSString *)date
{
    _lbDate.text = [NSString stringWithFormat:@"%@", date];
}

- (IBAction)onCallButton:(id)sender
{
    NSString *phoneNumber = [@"telprompt://" stringByAppendingString:@"0887379576"];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumber]];
}

@end
