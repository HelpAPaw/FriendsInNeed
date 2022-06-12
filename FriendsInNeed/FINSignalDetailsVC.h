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

- (void)setCommentText:(NSString * _Nonnull)text;
- (void)setDate:(NSString * _Nonnull)date;

@end

@protocol FINPhotoDelegate

- (void)onImageTapped:(UIImage * _Nonnull)image;

@end

@protocol FINNavigationDelegate

- (void)onNavigateButtonTapped;

@end

@protocol FINSignalDetailsVCDelegate <NSObject>

- (void)refreshAnnotation:(FINAnnotation * _Nonnull)annotation;
- (void)removeAnnotation:(FINAnnotation * _Nonnull)annotation;
- (void)focusAnnotation:(FINAnnotation * _Nonnull)annotation
         andCenterOnMap:(BOOL)moveToCenter;

@end

@interface FINSignalDetailsVC : UIViewController

@property (weak, nonatomic) id <FINSignalDetailsVCDelegate> _Nullable delegate;

- (FINSignalDetailsVC * _Nonnull)initWithSignal:(FINSignal * _Nonnull)signal
                                  andAnnotation:(FINAnnotation * _Nullable)annotation;

@end
