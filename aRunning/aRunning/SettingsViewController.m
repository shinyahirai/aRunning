//
//  SettingsViewController.m
//  BeatRun
//
//  Created by Shinya Hirai on 3/2/14.
//  Copyright (c) 2014 Shinya Hirai. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController () {
    NSArray* _ageArray;
    AppDelegate* _appDelegate;
}

@end

@implementation SettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // tableView設定
    _tableView.dataSource = self;
    _tableView.delegate = self;
    
    _appDelegate = [[UIApplication sharedApplication] delegate];
    
    _ageArray = @[@"10", @"11", @"12", @"13", @"14", @"15", @"16", @"17",@"18", @"19", @"20", @"21", @"22", @"23", @"24", @"25", @"26", @"27",@"28", @"29"];
    
    UIPickerView *pickerView = [[UIPickerView alloc] init];
    // delegate,dataSource設定
    pickerView.delegate = self;
    pickerView.dataSource = self;
    // 選択状態のインジケーターを表示（デフォルト：NO）
    pickerView.showsSelectionIndicator = YES;
    // コンポーネント0の指定行を選択状態にする（初期選択状態の設定）
    [pickerView selectRow:8 inComponent:0 animated:NO];
    
    pickerView.center = self.view.center;
    [self.view addSubview:pickerView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString* cellIdentifier = @"Cell";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    cell.textLabel.text = @"年齢";
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // UIPickerViewで年齢を選ぶ
}

#pragma mark - UIPickerViewDataSource

// コンポーネント数（列数）
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 2;
}

// 行数
- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component
{
    switch (component) {
        case 0:
            return [_ageArray count];
            break;
            
        default:
            return 1;
            break;
    }
}

#pragma mark - UIPickerViewDelegate

// 表示内容
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    switch (component) {
        case 0:
            return _ageArray[row];
            break;
            
        default:
            return @"歳";
            break;
    }
    
}

// 選択時（くるくる回して止まった時に呼ばれる）
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSLog(@"selected: %@", _ageArray[row]);
    _appDelegate.ageInt = [_ageArray[row] intValue];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
