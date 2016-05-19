//
//  ViewController.m
//  CityLocation
//
//  Created by RichyLeo on 16/5/19.
//  Copyright © 2016年 WTC. All rights reserved.
//

#import "ViewController.h"
#import "CityLocationViewController.h"

@interface ViewController ()

@property (strong, nonatomic) IBOutlet UIBarButtonItem *currRightItem;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

#pragma mark - 城市列表选择

- (IBAction)chooseCityAction:(id)sender {
    
    CityLocationViewController * cityLVC = [[CityLocationViewController alloc] init];
    UINavigationController * nav = [[UINavigationController alloc] initWithRootViewController:cityLVC];
    cityLVC.navigationItem.title = @"城市选择";
    cityLVC.cityBlock = ^(NSString * cityName){
        
        // 将选择结果通过Block形式，回传
        // 这里我简单将其展示在导航右侧Item
        self.currRightItem.title = cityName;
        
    };
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
