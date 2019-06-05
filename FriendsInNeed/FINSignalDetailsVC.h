//
//  FINSignalDetailsVC.h
//  FriendsInNeed
//
//  Created by Milen on 08/03/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FINAnnotation.h"
#import "Help_A_Paw-Swift.h"

@protocol FINSignalDetailsVCDelegate <NSObject>

- (void)refreshAnnotation:(FINAnnotation *)annotation;
- (void)focusAnnotation:(FINAnnotation *)annotation andCenterOnMap:(BOOL)moveToCenter;

@end

@interface FINSignalDetailsVC : UIViewController

@property (weak, nonatomic) id <FINSignalDetailsVCDelegate> delegate;

- (FINSignalDetailsVC *)initWithAnnotation:(FINAnnotation *)annotation;

@end
