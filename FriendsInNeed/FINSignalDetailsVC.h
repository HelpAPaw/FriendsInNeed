//
//  FINSignalDetailsVC.h
//  FriendsInNeed
//
//  Created by Milen on 08/03/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FINAnnotation.h"

@protocol FINSignalDetailsCommentCellProtocol <NSObject>

- (void)setCommentText:(NSString *)text;
- (void)setDate:(NSString *)date;

@end

@protocol FINPhotoDelegate

- (void)onImageTapped:(UIImage *)image;

@end

@protocol FINNavigationDelegate

- (void)onNavigateButtonTapped;

@end

@protocol FINSignalDetailsVCDelegate <NSObject>

- (void)refreshAnnotation:(FINAnnotation *)annotation;
- (void)removeAnnotation:(FINAnnotation *)annotation;
- (void)focusAnnotation:(FINAnnotation *)annotation andCenterOnMap:(BOOL)moveToCenter;

@end

@interface FINSignalDetailsVC : UIViewController

@property (weak, nonatomic) id <FINSignalDetailsVCDelegate> delegate;

- (FINSignalDetailsVC *)initWithAnnotation:(FINAnnotation *)annotation;

@end
