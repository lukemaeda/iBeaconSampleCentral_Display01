//
//  ViewController.m
//  iBeaconSampleCentral
//
//  Created by iScene on 2015/06/07.
//  Copyright (c) 2015年 iScene. All rights reserved.
//
//  iOS8からはロケーションマネージャの権限取得
//  http://it.senatus.jp/post-210/
//
//  [iOS 7] 新たな領域観測サービス iBeacon を使ってみる
//  http://dev.classmethod.jp/references/ios7-ibeacon-api/
//
//  セントラル受信側
//  情報を受取るセントラル(デバイス)

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>

#define UUID        @"D456894A-02F0-4CB0-8258-81C187DF45C2"
#define IDENTIFIER  @"jp.classmethod.testregion"

@interface ViewController () <CLLocationManagerDelegate>

@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) CLBeaconRegion *beaconRegion;

@property (nonatomic) NSUUID                        *proximityUUID;
@property (strong, nonatomic) NSString              *identifier;
@property uint16_t                                  major;
@property uint16_t                                  minor;

@property (weak, nonatomic) IBOutlet UILabel *beaconFoundLabel;
@property (weak, nonatomic) IBOutlet UILabel *proximityUUIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *majorLabel;
@property (weak, nonatomic) IBOutlet UILabel *minorLabel;
@property (weak, nonatomic) IBOutlet UILabel *accuracyLabel;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *rssiLabel;

@property (weak, nonatomic) IBOutlet UITextView *tvdisply;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //self.tvdisply.text = nil;
    
    if ([CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]]) {
        
        // CLLocationManagerの生成とデリゲートの設定
        self.locationManager = [CLLocationManager new];
        self.locationManager.delegate = self;
        
        // 生成したUUIDからNSUUIDを作成
        self.proximityUUID      = [[NSUUID alloc]initWithUUIDString:UUID];
        self.identifier         = IDENTIFIER;
        
        self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:self.proximityUUID
                                                               identifier:self.identifier];
        
        self.beaconRegion.notifyOnEntry               = YES; // 領域に入った事を監視 YES
        self.beaconRegion.notifyOnExit                = NO; // 領域を出た事を監視
        self.beaconRegion.notifyEntryStateOnDisplay   = YES; // デバイスのディスプレイがオンのとき、ビーコン通知が送信されない NO
        
        /////////////////////////////////
        // iOS8の追加
        // 位置情報の取得許可を求めるメソッド
        if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            // requestAlwaysAuthorizationメソッドが利用できる場合(iOS8以上の場合)
            // 位置情報の取得許可を求めるメソッド
            [self.locationManager requestAlwaysAuthorization];
        } else {
            // requestAlwaysAuthorizationメソッドが利用できない場合(iOS8未満の場合)
            [self.locationManager startMonitoringForRegion: self.beaconRegion];
        }
        /////////////////////////////////
        
        // Beaconによる領域観測を開始
        //[self.locationManager startMonitoringForRegion:self.beaconRegion];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    [self sendLocalNotificationForMessage:@"地域の監視を開始 Start Monitoring Region"];
}

//-------------------------------------
// 領域に入った時
// Beacon内の領域に入る（領域観測）Region（レンジング）　ローカル通知を送っている
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    // ローカル通知
    [self sendLocalNotificationForMessage:@"地域入力 Enter Region"];
    // Beaconの距離測定を開始する
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [self.locationManager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
}

//
- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    // ローカル通知
    [self sendLocalNotificationForMessage:@"出口エリア Exit Region"];
    // Beaconの距離測定を終了する
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [self.locationManager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
}

// メソッドの２番目の引数には、距離測定中の Beacon の配列が渡されてきます。この配列は、Beacon までの距離が近い順にソートされていますので、先頭に格納されている CLBeacon のインスタンスが最も距離が近い Beacon の情報となります
// Beacon距離観測 定期的イベント発生（距離の測定を開始）
- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    
    if (beacons.count > 0) {
        // 最も距離の近いBeaconについて処理する
        CLBeacon *nearestBeacon = beacons.firstObject;
        
        NSString *rangeMessage;
        
        // Beacon の距離でメッセージを変える
        switch (nearestBeacon.proximity) {
            case CLProximityImmediate:
                rangeMessage = @"より近い\n ";
                self.distanceLabel.text = @"より近い";
                break;
            case CLProximityNear:
                rangeMessage = @"近い\n ";
                self.distanceLabel.text = @"近い";
                break;
            case CLProximityFar:
                rangeMessage = @"遠い\n ";
                self.distanceLabel.text = @"遠い";
                break;
            default:
                rangeMessage = @"測距エラー\n ";
                self.distanceLabel.text = @"測距エラー";
                break;
        }
        
        //-------------------------------------------------------------
        // iBeaconの電波強度を調べて、近距離に来た場合
        if ( nearestBeacon.proximity == CLProximityImmediate && nearestBeacon.rssi > -40 ) {
            self.distanceLabel.text   = @"よりより近い";
        }
        
        self.beaconFoundLabel.text = @"Yes";
        // UUID
        self.proximityUUIDLabel.text = self.beaconRegion.proximityUUID.UUIDString;
        // メジャー
        self.majorLabel.text = [NSString stringWithFormat:@"グルーピング %@", nearestBeacon.major];
        // マイナー
        self.minorLabel.text = [NSString stringWithFormat:@"店舗 %@", nearestBeacon.minor];
        // 距離・精度
        self.accuracyLabel.text = [NSString stringWithFormat:@"%f", nearestBeacon.accuracy];
        // RSSI:電波強度
        self.rssiLabel.text = [NSString stringWithFormat:@"%li", (long)nearestBeacon.rssi];

        // ローカル通知
        NSString *message = [NSString stringWithFormat:@"メジャー:%@,\n マイナー:%@,\n 距離:%f,\n 感度:%ld\n",
                             nearestBeacon.major, nearestBeacon.minor, nearestBeacon.accuracy, (long)nearestBeacon.rssi];
        
        [self.tvdisply.text stringByAppendingFormat:@"メジャー:%@,\n マイナー:%@,\n 距離:%f,\n 感度:%ld\n",
         nearestBeacon.major, nearestBeacon.minor, nearestBeacon.accuracy, (long)nearestBeacon.rssi];
        
        [self sendLocalNotificationForMessage:[rangeMessage stringByAppendingString:message]];
    }
}

// iOS8 ユーザの位置情報の許可状態を確認するメソッド
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusNotDetermined) {
        // ユーザが位置情報の使用を許可していない
    } else if(status == kCLAuthorizationStatusAuthorizedAlways) {
        // ユーザが位置情報の使用を常に許可している場合
        [self.locationManager startMonitoringForRegion: self.beaconRegion];
    } else if(status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        // ユーザが位置情報の使用を使用中のみ許可している場合
        [self.locationManager startMonitoringForRegion: self.beaconRegion];
    }
}


- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    [self sendLocalNotificationForMessage:@"出口エリア Exit Region"];
}

#pragma mark - Private methods

- (void)sendLocalNotificationForMessage:(NSString *)message
{
    UILocalNotification *localNotification = [UILocalNotification new];
    localNotification.alertBody = message;
    localNotification.fireDate = [NSDate date];
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

@end
