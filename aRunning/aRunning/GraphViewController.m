//
//  GraphViewController.m
//  aRunning
//
//  Created by Shinya Hirai on 3/4/14.
//  Copyright (c) 2014 Shinya Hirai. All rights reserved.
//

#import "GraphViewController.h"

@interface GraphViewController () {
    CPTGraphHostingView* _hostingView;
    CPTGraph* _graph;
    CPTScatterPlot* _scatterPlot;
    NSMutableArray* _scatterPlotData;
    
    int _direction;
}

@end

@implementation GraphViewController

NSString *const kData   = @"Data Source Plot";

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
    
    // locationの使い回しテスト用
    AppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];
    NSLog(@"標高 = %f",appDelegate.location.altitude);
    
    // ホスティングビューを生成
    _hostingView = [[CPTGraphHostingView alloc] init];
    
    
    // 画面の向きによって表示を分岐
    _direction = self.interfaceOrientation;
    if(_direction == UIInterfaceOrientationPortrait){
        _hostingView.frame = CGRectMake(20, 20, 280, 280);
    } else {
        _hostingView.frame = CGRectMake(20, 20, 528, 240);
    }
    
    // 画面にホスティングビューを追加
    [self.view addSubview:_hostingView];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    if (toInterfaceOrientation == UIInterfaceOrientationPortrait) {
        _hostingView.frame = CGRectMake(20, 20, 280, 280);
    } else {
        _hostingView.frame = CGRectMake(20, 20, 528, 240);
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    _hostingView.hostedGraph = nil;
    [_scatterPlotData removeAllObjects];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // グラフに表示するデータを生成
    // X軸とY軸の両方を設定する必要がある。キーを設定し、次のようなデータ構造になっている
    // [{ x = 0; y = 0; }, { x = 1; y = 1; }, { x = 2; y = 7; },
    // { x = 3; y = 4; }, { x = 4; y = 5; }, { x = 5; y = 2; },
    // { x = 6; y = 0; }, { x = 7; y = 6; }, { x = 8; y = 6; },
    // { x = 9; y = 9; }, { x = 10: y = 3 }]
    _scatterPlotData = [NSMutableArray array];
    
    for ( NSUInteger i = 0; i < 11; i++ ) {
        NSNumber *x = [NSNumber numberWithDouble:i];
        NSNumber *y = [NSNumber numberWithDouble:(int)(rand() / (double)RAND_MAX * 10)]; // 1〜10の値のランダム値(int)
        [_scatterPlotData addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:x, @"x", y, @"y", nil]];
    }

    // グラフを生成
    _graph = [[CPTXYGraph alloc] initWithFrame:_hostingView.bounds];
    _hostingView.hostedGraph = _graph;
    
    // グラフのテーマを作成して、設定
    // その他のテーマ名　kCPTPlainBlackTheme:黒いテーマ, kCPTDarkGradientTheme:グレーなテーマ
    //                kCPTSlateTheme:グレーなテーマ, kCPTStocksTheme
    CPTTheme *theme = [CPTTheme themeNamed:kCPTPlainWhiteTheme];    // シンプルな白いテーマ
    [_graph applyTheme:theme];
    
    
	CPTMutableLineStyle *borderLineStyle = [CPTMutableLineStyle lineStyle];
	borderLineStyle.lineColor = [CPTColor grayColor];
	borderLineStyle.lineWidth = 1.0f;

    // グラフのボーダー設定
    _graph.plotAreaFrame.borderLineStyle = borderLineStyle;
    _graph.plotAreaFrame.cornerRadius    = 10.0f;
    _graph.plotAreaFrame.masksToBorder   = YES;
    
    // パディング
    _graph.paddingLeft   = 0.0f;
    _graph.paddingRight  = 0.0f;
    _graph.paddingTop    = 0.0f;
    _graph.paddingBottom = 0.0f;
    
    _graph.plotAreaFrame.paddingLeft   = 60.0f;
    _graph.plotAreaFrame.paddingTop    = 40.0f;
    _graph.plotAreaFrame.paddingRight  = 20.0f;
    _graph.plotAreaFrame.paddingBottom = 60.0f;
    
    //プロット間隔の設定
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)_graph.defaultPlotSpace;
    //Y軸は0〜10の値で設定
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(0) length:CPTDecimalFromInt(10)];
    //X軸は0〜10の値で設定
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(0) length:CPTDecimalFromInt(10)];
    
    // Axes
	CPTXYAxisSet *axisSet = (CPTXYAxisSet *)_graph.axisSet;
    
	// Axes Line Style
	CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
	lineStyle.lineColor = [CPTColor greenColor];
	lineStyle.lineWidth = 2.0f;
    
	// X Axis
	CPTXYAxis *x = axisSet.xAxis;
	x.majorIntervalLength = CPTDecimalFromString(@"5");
	x.minorTicksPerInterval = 4;
	x.majorTickLineStyle = lineStyle;
	x.minorTickLineStyle = lineStyle;
	x.axisLineStyle = lineStyle;
	x.minorTickLength = 5.0f;
	x.majorTickLength = 14.0f;

    //	Y Axis
	lineStyle.lineColor = [CPTColor yellowColor];
    
	CPTXYAxis *y = axisSet.yAxis;
	y.majorIntervalLength = CPTDecimalFromString(@"5");
	y.minorTicksPerInterval = 4;
	y.majorTickLineStyle = lineStyle;
	y.minorTickLineStyle = lineStyle;
	y.axisLineStyle = lineStyle;
	y.minorTickLength = 5.0f;
	y.majorTickLength = 14.0f;
	y.title = @"Y Title";
	y.titleOffset = 35.0f;	//	move left from y axis. negative value is go right.
	lineStyle.lineWidth = 0.5f;
	y.majorGridLineStyle = lineStyle;

    // Graph タイトル
    _graph.title = @"Ranning Data";

    // テキストスタイル
    CPTMutableTextStyle *textStyle = [CPTTextStyle textStyle];
    textStyle.color                = [CPTColor colorWithComponentRed:0.447f green:0.443f blue:0.443f alpha:1.0f];
    textStyle.fontSize             = 16.0f;
    textStyle.textAlignment        = CPTTextAlignmentCenter;
    _graph.titleTextStyle = textStyle;
	_graph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
	_graph.titleDisplacement = CGPointMake(80.0f, -30.0f);

    
    // 折れ線グラフのインスタンスを生成
    _scatterPlot = [[CPTScatterPlot alloc] init];
    _scatterPlot.identifier      = kData;    // 折れ線グラフを識別するために識別子を設定
    _scatterPlot.dataSource      = self;     // 折れ線グラフのデータソースを設定
    
    // 折れ線グラフのスタイルを設定
    CPTMutableLineStyle *graphlineStyle = [_scatterPlot.dataLineStyle mutableCopy];
    graphlineStyle.lineWidth = 3;                    // 太さ
    graphlineStyle.lineColor = [CPTColor colorWithComponentRed:0.573f green:0.82f blue:0.831f alpha:0.50f];// 色
    _scatterPlot.dataLineStyle = graphlineStyle;
    
    // グラフに折れ線グラフを追加
    [_graph addPlot:_scatterPlot];

}

#pragma mark - Plot Data Source Methods

// グラフに使用する折れ線グラフのデータ数を返す
-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    NSUInteger numRecords = 0;
    NSString *identifier  = (NSString *)plot.identifier;
    
    // 折れ線グラフのidentifierにより返すデータ数を変える（複数グラフを表示する場合に必要）
    if ( [identifier isEqualToString:kData] ) {
        numRecords = _scatterPlotData.count;
    }
    
    return numRecords;
}

// グラフに使用する折れ線グラフのX軸とY軸のデータを返す
-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSNumber *num        = nil;
    NSString *identifier = (NSString *)plot.identifier;
    
    // 折れ線グラフのidentifierにより返すデータ数を変える（複数グラフを表示する場合に必要）
    if ( [identifier isEqualToString:kData] ) {
        switch (fieldEnum) {
            case CPTScatterPlotFieldX:  // X軸の場合
                num = [[_scatterPlotData objectAtIndex:index] valueForKey:@"x"];
                break;
            case CPTScatterPlotFieldY:  // Y軸の場合
                num = [[_scatterPlotData objectAtIndex:index] valueForKey:@"y"];
                break;
        }
    }
    
    return num;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
