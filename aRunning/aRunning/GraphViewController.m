//
//  GraphViewController.m
//  aRunning
//
//  Created by Shinya Hirai on 3/4/14.
//  Copyright (c) 2014 Shinya Hirai. All rights reserved.
//

#import "GraphViewController.h"

@interface GraphViewController ()

@end

@implementation GraphViewController

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
    
    //ホスティングビューを生成する---------------------------------------------
    CPTGraphHostingView *hostingView = [[CPTGraphHostingView alloc] init];
    hostingView.collapsesLayers = NO;
    self.view = hostingView;
    
    // グラフのテーマを生成-----------------------------------
    
    self.barChart = [[CPTXYGraph alloc] initWithFrame:CGRectZero];
    CPTTheme *theme = [CPTTheme themeNamed:kCPTPlainWhiteTheme]; //kCPTPlainWhiteTheme
    [self.barChart applyTheme:theme];
    hostingView.hostedGraph = self.barChart;
    
    // ボーダー設定------------------------------------------------------
    self.barChart.plotAreaFrame.borderLineStyle = nil;
    self.barChart.plotAreaFrame.cornerRadius    = 0.0f;
    
    
    
    // Paddings----------------------------------------------------
    self.barChart.paddingLeft   = 0.0f;
    self.barChart.paddingRight  = 0.0f;
    self.barChart.paddingTop    = 0.0f;
    self.barChart.paddingBottom = 0.0f;
    
    self.barChart.plotAreaFrame.paddingLeft   = 60.0f;
    self.barChart.plotAreaFrame.paddingTop    = 60.0f;
    self.barChart.plotAreaFrame.paddingRight  = 20.0f;
    self.barChart.plotAreaFrame.paddingBottom = 65.0f;
    
    // テキストスタイル------------------------------------------------------------------------------------------------
    CPTMutableTextStyle *textStyle = [CPTTextStyle textStyle];
    textStyle.color                = [CPTColor colorWithComponentRed:0.447f green:0.443f blue:0.443f alpha:1.0f];
    textStyle.fontSize             = 13.0f;
    textStyle.textAlignment        = CPTTextAlignmentCenter;
    
    // ラインスタイル--------------------------------------------------------------------------------------------------
    CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
    lineStyle.lineColor            = [CPTColor colorWithComponentRed:0.788f green:0.792f blue:0.792f alpha:1.0f];
    lineStyle.lineWidth            = 2.0f;
    
    
    
    //プロット間隔の設定 ----------------------------------------------------
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.barChart.defaultPlotSpace;
    //Y軸は0〜10
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(0) length:CPTDecimalFromInt(10)];
    //X軸は0〜5
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInt(0) length:CPTDecimalFromInt(5)];
    
    
    
    // X軸のメモリ・ラベルなどの設定----------------------------------------------------------------------------------
    
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.barChart.axisSet;
    CPTXYAxis *x          = axisSet.xAxis;
    
    x.axisLineStyle               = lineStyle;
    x.majorTickLineStyle          = lineStyle;
    x.minorTickLineStyle          = lineStyle;
    x.majorIntervalLength         = CPTDecimalFromString(@"1");
    x.orthogonalCoordinateDecimal = CPTDecimalFromString(@"0");
    x.title                       = @"X軸";
    x.titleTextStyle = textStyle;
    x.titleLocation               = CPTDecimalFromFloat(5.0f);
    x.titleOffset                 = 36.0f;
    x.minorTickLength = 5.0f;
    x.majorTickLength = 9.0f;
    x.labelRotation  = M_PI / 4; // 表示角度
    x.labelTextStyle = textStyle;
    
    // Y軸のメモリ・ラベルなどの設定----------------------------------------------------------------------------------
    CPTXYAxis *y = axisSet.yAxis;
    
    y.axisLineStyle               = lineStyle;
    y.minorTickLength = 5.0f;
    y.majorTickLength = 9.0f;
    y.majorTickLineStyle          = lineStyle;
    y.minorTickLineStyle          = lineStyle;
    y.majorIntervalLength         = CPTDecimalFromFloat(2.0f);
    y.orthogonalCoordinateDecimal = CPTDecimalFromFloat(0.0f);
    y.title                       = @"Y軸";
    y.titleTextStyle = textStyle;
    y.titleRotation = M_PI*2;
    y.titleLocation               = CPTDecimalFromFloat(10.5f);
    y.titleOffset                 = 25.0f;
    lineStyle.lineWidth = 0.5f;
    y.majorGridLineStyle = lineStyle;
    y.labelTextStyle = textStyle;
    
    
    // バー表示設定---------------------------------------------------------------------------------------------
    CPTBarPlot *barPlot = [CPTBarPlot tubularBarPlotWithColor:[CPTColor colorWithComponentRed:1.0f green:1.0f blue:0.88f alpha:1.0f] horizontalBars:NO];
    
    barPlot.fill = [CPTFill fillWithColor:[CPTColor colorWithComponentRed:0.573f green:0.82f blue:0.831f alpha:0.50f]];
    
    barPlot.lineStyle = lineStyle;
    barPlot.baseValue  = CPTDecimalFromString(@"0");
    barPlot.dataSource = self;
    barPlot.barWidth = CPTDecimalFromFloat(0.5f);
    barPlot.barOffset  = CPTDecimalFromFloat(0.5f);
    [self.barChart addPlot:barPlot toPlotSpace:plotSpace];
}

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    return 5;
}


-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSDecimalNumber *num = nil;
    
    if ( [plot isKindOfClass:[CPTBarPlot class]] ) {
        
        switch ( fieldEnum ) {
                //X方向の位置を指定
            case CPTBarPlotFieldBarLocation:
                num = (NSDecimalNumber *)[NSDecimalNumber numberWithUnsignedInteger:index];
                break;
                
                //棒の高さを指定
            case CPTBarPlotFieldBarTip:
                if(index == 0){
                    num = (NSDecimalNumber *)[NSDecimalNumber numberWithUnsignedInteger:1];
                }else if(index == 1){
                    num = (NSDecimalNumber *)[NSDecimalNumber numberWithUnsignedInteger:3];
                }else if(index == 2){
                    num = (NSDecimalNumber *)[NSDecimalNumber numberWithUnsignedInteger:5];
                }else if(index == 3){
                    num = (NSDecimalNumber *)[NSDecimalNumber numberWithUnsignedInteger:7];
                }else if(index == 4){
                    num = (NSDecimalNumber *)[NSDecimalNumber numberWithUnsignedInteger:9];
                }
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
