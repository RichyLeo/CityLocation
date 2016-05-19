//
//  CityLocationViewController.m
//  LOL
//
//  Created by RichyLeo on 16/3/14.
//  Copyright © 2016年 WTC. All rights reserved.
//

#import "CityLocationViewController.h"
// 系统框架 定位
#import <CoreLocation/CoreLocation.h>

#define SCREEN_WIDTH    [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT    [UIScreen mainScreen].bounds.size.height

@interface CityLocationViewController () <UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate>
{
    UITableView *_tableView;
    
    NSMutableArray *_arrayDS;   // 列表数据源
    NSMutableArray *_sectionDS; // 列表右侧索引选项
    
    BOOL _isLocationed; // 是否已经获得定位信息
    NSString *_currentCity; // 当前定位城市名
}

//
@property (nonatomic, strong) CLLocationManager* locationManager;

@end

@implementation CityLocationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStyleDone target:self action:@selector(closeCityPage)];
    
    [self initData];
    [self initUI];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // 立即开启定位
    [self findMe];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // 当“城市选择”页面，即将消失时，随之应将定位停止
    [self.locationManager stopUpdatingLocation];
}

#pragma mark - Apple原生定位功能

// 懒加载方式，_locationManager要定义为成员变量形式，保证其生命周期
-(CLLocationManager *)locationManager
{
    if(!_locationManager){
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    }
    return _locationManager;
}

- (void)findMe
{
    
    if([CLLocationManager locationServicesEnabled]){
        /** 由于IOS8中定位的授权机制改变 需要进行手动授权
         * 获取授权认证，两个方法：
         * [self.locationManager requestWhenInUseAuthorization];
         * [self.locationManager requestAlwaysAuthorization];
         */
        if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            NSLog(@"requestWhenInUseAuthorization");
            [self.locationManager requestWhenInUseAuthorization];
        }
        
        //开始定位，不断调用其代理方法
        [self.locationManager startUpdatingLocation];
        NSLog(@"start gps");
    }
    else{
        NSLog(@"提醒用户：定位服务未开启，可在设置中进行修改。");
    }
}

#pragma mark - CLLocationManagerDelegate

// 当定位到地理位置，回调的方法
- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    // 此判断的目的：避免多次定位的处理
    if(!_isLocationed){
        // 1.获取用户位置的对象
        CLLocation *location = [locations lastObject];
        CLLocationCoordinate2D coordinate = location.coordinate;
        NSLog(@"纬度:%f 经度:%f", coordinate.latitude, coordinate.longitude);
        
        // 逆地理编码得到当前定位城市
        [self reGeoCodeLocation:coordinate];
        
        _isLocationed = YES;
    }
    
    // 2.停止定位
    [self.locationManager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    if (error.code == kCLErrorDenied) {
        // 提示用户出错原因，可按住Option键点击 KCLErrorDenied的查看更多出错信息，可打印error.code值查找原因所在
        NSLog(@"Error : %@", error);
    }
}

#pragma mark - Apple原生逆地理编码

-(void)reGeoCodeLocation:(CLLocationCoordinate2D)coordinate
{
    // 获取当前所在的城市名
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    //根据经纬度反向地理编译出地址信息
    CLLocation * location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *array, NSError *error)
     {
         if (array.count > 0)
         {
             CLPlacemark *placemark = [array objectAtIndex:0];
             
             //将获得的所有信息显示到label上
//             self.location.text = placemark.name;
             
             //获取城市
             NSString *city = placemark.locality;
             if (!city) {
                 //四大直辖市的城市信息无法通过locality获得，只能通过获取省份的方法来获得（如果city为空，则可知为直辖市）
                 city = placemark.administrativeArea;
             }
             NSLog(@"city = %@", city);
             _currentCity = city;
             
             // 刷新
             NSIndexPath * indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
             [_tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
             
         }
         else if (error == nil && [array count] == 0)
         {
             NSLog(@"No results were returned.");
         }
         else if (error != nil)
         {
             NSLog(@"An error occurred = %@", error);
         }
     }];
}

#pragma mark - Inits

-(void)initData
{
    NSString * path = [[NSBundle mainBundle] pathForResource:@"cityGroups" ofType:@"plist"];
    _arrayDS = [[NSMutableArray alloc] initWithContentsOfFile:path];
    
    _sectionDS = [[NSMutableArray alloc] init];
    for(NSDictionary * dic in _arrayDS){
        [_sectionDS addObject:dic[@"title"]];
    }
    [_sectionDS replaceObjectAtIndex:0 withObject:@"当前"];
}

-(void)initUI
{
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) style:UITableViewStyleGrouped];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];
}

#pragma mark - UITableview Delegate

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _arrayDS.count;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_arrayDS[section][@"cities"] count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * cellIndentif = @"cityListCell";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIndentif];
    if(!cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIndentif];
    }
    
    NSString * city = [_arrayDS[indexPath.section][@"cities"] objectAtIndex:indexPath.row];
    cell.textLabel.text = city;
    
    if(indexPath.section == 0 && indexPath.row == 0){
        if(_currentCity.length > 0){
            cell.textLabel.text = [NSString stringWithFormat:@"%@%@", city, _currentCity];
        }
        else{
            cell.textLabel.text = [NSString stringWithFormat:@"%@%@", city, @"定位中..."];
        }
    }
    
    return cell;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return _arrayDS[section][@"title"];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString * city = [_arrayDS[indexPath.section][@"cities"] objectAtIndex:indexPath.row];
    
    if(self.cityBlock){
        if(indexPath.section == 0 && indexPath.row == 0){
            if(_currentCity.length > 0){
                self.cityBlock(_currentCity);
            }
        }
        else{
            self.cityBlock(city);
        }
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (nullable NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return _sectionDS;
}

#pragma mark - nav 事件

-(void)closeCityPage
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
