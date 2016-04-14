//
//  FINSignalDetailsVC.h
//  FriendsInNeed
//
//  Created by Milen on 08/03/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Backendless.h"
#import "FINAnnotation.h"

@protocol FINSignalDetailsVCDelegate <NSObject>

- (void)refreshAnnotation:(FINAnnotation *)annotation;

@end

@interface FINSignalDetailsVC : UIViewController

@property (weak, nonatomic) id <FINSignalDetailsVCDelegate> delegate;

- (FINSignalDetailsVC *)initWithGeoPoint:(GeoPoint *)geoPoint;
- (FINSignalDetailsVC *)initWithAnnotation:(FINAnnotation *)annotation;

@end
