//
//  CityLocationViewController.h
//  LOL
//
//  Created by RichyLeo on 16/3/14.
//  Copyright © 2016年 WTC. All rights reserved.
//

#import <UIKit/UIKit.h>

// Block类型重定义
typedef void (^CityNameBlock) (NSString * cityName);

@interface CityLocationViewController : UIViewController

// 城市选择确认后，用作之后的传值
@property (nonatomic, copy) CityNameBlock cityBlock;

@end
