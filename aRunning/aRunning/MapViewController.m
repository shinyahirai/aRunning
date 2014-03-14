//
//  MapViewController.m
//  BeatRun
//
//  Created by Shinya Hirai on 3/3/14.
//  Copyright (c) 2014 Shinya Hirai. All rights reserved.
//

#import "MapViewController.h"

@interface MapViewController () {
    BOOL _doFollow; // フォローモードのハンドル
    
    NSMutableArray* _polylineList;  // MapViewに追加しているGMSPolylineオブジェクトを保持
    GMSMutablePath* _targetPath;    // 変更対象のpolylineオブジェクトの座標群を保持
}

@end

// マップで表示する最大のpolyline数
#define MAX_POLYLINE 10
// 1polylineあたりの最大座標軸
#define MAX_COORDINATE_PER_POLYLINE 300

@implementation MapViewController

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
    // 初期化
    _doFollow = YES;
    _polylineList = [[NSMutableArray alloc] init];
    _targetPath = [GMSMutablePath path];
    
    // Google Map
    GMSCameraPosition* camera = [GMSCameraPosition cameraWithLatitude:34.75144
                                                            longitude:135.369551
                                                                 zoom:5];
    _gMapView = [GMSMapView mapWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - 319) camera:camera];
//    [_gMapView animateToViewingAngle:45];
    _gMapView.delegate = self;
    _gMapView.settings.myLocationButton = YES;
    [self.view addSubview:_gMapView];
    
//    // LocationManager
//    AppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];
//	appDelegate.locationManager.delegate = self;
//    
//    if(appDelegate.locationManager == nil)
//	{
//		appDelegate.locationManager = [[CLLocationManager alloc] init];
//	}
//    appDelegate.locationManager.delegate = self;
//	appDelegate.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
//	appDelegate.locationManager.distanceFilter = 5.0f;
//    
//	[appDelegate.locationManager startUpdatingLocation];

    
    // 地図の中心位置更新のため、KVOで位置情報更新の監視を行う
    [_gMapView addObserver:self forKeyPath:@"myLocation" options:NSKeyValueObservingOptionNew context:NULL];
    
    // マーカーの設置
    GMSMarker *marker = [[GMSMarker alloc] init];
    marker.position = CLLocationCoordinate2DMake(10.328531, 123.903545);
    marker.title = @"La guardia";
    marker.snippet = @"Flat Ⅱ";
    marker.map = _gMapView;
    
    // 計測開始をviewDidLoad後に実行
    dispatch_async(dispatch_get_main_queue(), ^{
        _gMapView.myLocationEnabled = YES;
    });
}

//- (BOOL)mapView:(GMSMapView *)mapView didTapMarker:(id)marker {
//    NSLog(@"tap");
//    return YES;
//}

- (void)mapView:(GMSMapView *)mapView didTapInfoWindowOfMarker:(id)marker {
    NSLog(@"tap");
}
//#pragma mark - Manager
//-(void)locationManager:(CLLocationManager *)manager
//   didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
//{
//	NSLog(@"manager%@",newLocation.timestamp);
//}

#pragma mark - KVO update
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    AppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];
    appDelegate.location = [change objectForKey:NSKeyValueChangeNewKey];
    
    [self updatePolylines:appDelegate.location]; // 軌跡更新
    if (_doFollow) {
        // 現在地をMapの中心に表示(フォローモード)
        appDelegate.location = [change objectForKey:NSKeyValueChangeNewKey];
        [_gMapView animateToLocation:appDelegate.location.coordinate];
        _segmentedControl.selectedSegmentIndex = 0;
    } else {
        _segmentedControl.selectedSegmentIndex = 1;
    }
    
    // 標高表示
    _heightLabel.text = [NSString stringWithFormat:@"標高\n%fm",appDelegate.location.altitude];
}

#pragma mark - GMSMapViewDelegate
- (void)mapView:(GMSMapView *)mapView willMove:(BOOL)gesture {
    if (gesture) {
        _doFollow = NO;
    }
}

- (void)mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)position
{
    // アニメーションでのcameraの位置変更が終わったときに呼ばれるので、ここでmyLocationとマップ中心の座標を比較し、
    // フォローモードにするかどうかを判定する
    if(mapView.myLocation){
        CLLocationDegrees deltaLat = fabs(mapView.myLocation.coordinate.latitude - position.target.latitude);
        CLLocationDegrees deltaLon = fabs(mapView.myLocation.coordinate.longitude - position.target.longitude);
        // フォローモード解除
        _doFollow = (deltaLat < 0.000001 && deltaLon < 0.000001);
    }
}

// _targetPathからGMSPolylineオブジェクトを生成する
- (GMSPolyline*)createPolyline:(GMSPath*)path
{
    GMSPolyline* polyline = [GMSPolyline polylineWithPath:path];
    polyline.strokeWidth = 5;
    polyline.strokeColor = [UIColor colorWithRed:0.625 green:0.21875 blue:0.125 alpha:1.0];
    return polyline;
}

// CLLocationを追加して軌跡群を更新する
- (void)updatePolylines:(CLLocation*)location
{
    // 誤差が50mより大きければ軌跡に加えない
//    NSLog(@"horizontalAccuracy2 = %f",location.horizontalAccuracy); // デバッグ用
    if(location && location.horizontalAccuracy > 50) return;
    
    // 一番後ろのpolylineは再作成するためにMapViewとリストから削除する
//    NSLog(@"polylineList = %@",_polylineList); // 最初値が(null)であったので、任意の箇所で初期化
    if(_polylineList && _polylineList.count > 0){
        GMSPolyline* lastOne = [_polylineList lastObject];
        lastOne.map = nil; // mapプロパティをnilにすればMapViewから消える
        [_polylineList removeLastObject];
        /*
         ↑↑↑↑↑上記処理で、Mapに書かれた最後の線とlineのMutableArrayの最後のオブジェクトを削除
         */
    }
    
    // 座標をpathに追加して、polylineを作成する
    NSMutableArray* workList = [NSMutableArray array]; // 追加するGMSPolylineを一時的に保持
    [_targetPath addLatitude:location.coordinate.latitude longitude:location.coordinate.longitude];  //最初ここも(null)。初期化
    if (_targetPath.count >= MAX_COORDINATE_PER_POLYLINE) {
        // 一つのpolylineに保持可能な座標数に達したので、次のpolylineに切り替える
        [workList addObject:[self createPolyline:_targetPath]]; // pathからpolylineを作成し、一時リストに追加
        _targetPath = [GMSMutablePath path]; // pathを切り替え
        // 直前のPolylineの最後の座標と次の座標をつなぐため、最後の座標をこちらにもセットしておく
        [_targetPath addLatitude:location.coordinate.latitude longitude:location.coordinate.longitude];
    }
    [workList addObject:[self createPolyline:_targetPath]]; // pathからpolylineを作成し、一時リストに追加
    
    // 新規作成したpolyline群を上限数以内におさめる
    if (workList.count > MAX_POLYLINE) {
        [workList removeObjectsInRange: NSMakeRange(0, workList.count - MAX_POLYLINE)];
    }
    // 新規+既存のpolyline群を上限数以内におさめるために、既存のpolyline群の数を調整する
    if ((_polylineList.count + workList.count) > MAX_POLYLINE) {
        for (int left = _polylineList.count + workList.count - MAX_POLYLINE; left > 0; --left) {
            // 先頭のpolylineをMapViewから切り離し、リストからも削除する
            GMSPolyline* polyline = _polylineList[0];
            polyline.map = nil;
            [_polylineList removeObjectAtIndex:0];
        }
    }
    // 新規polylineをMapViewに追加し、既存リストに加える
    
//    NSLog(@"workList = %@",workList); // workListが何か検証
    for (GMSPolyline* polyline in workList){
//        NSLog(@"polyline1 = %@",polyline);
        polyline.map = _gMapView;
    }
    [_polylineList addObjectsFromArray:workList];
    
//    NSLog(@"_polylineList = %@",_polylineList); // データが入っているか最終確認
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// デバッグ用ボタン
- (IBAction)tapBtn:(id)sender {
    AppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];

    // 線の描画サンプル(上ではユーザーの移動に合わせて線を描画している)
    GMSMutablePath* path = [GMSMutablePath path];
    [path addCoordinate:CLLocationCoordinate2DMake(10.328531, 123.903545)];
    [path addCoordinate:CLLocationCoordinate2DMake(10.318283, 123.908551)];
    [path addCoordinate:CLLocationCoordinate2DMake(appDelegate.location.coordinate.latitude, appDelegate.location.coordinate.longitude)];
    GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
    polyline.map = _gMapView;
}

// マップの中心をユーザーにするか手動にするかのハンドル
- (IBAction)SegChanged:(id)sender {
    switch (_segmentedControl.selectedSegmentIndex) {
        case 0:
            _doFollow = YES;
            break;
            
        case 1:
            _doFollow = NO;
            break;
            
        default:
            break;
    }
}
@end
