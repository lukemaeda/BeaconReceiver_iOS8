//
//  ViewController.m
//  BeaconReceiver
//
//  Created by Christopher Ching on 2014-04-27.
//  Copyright (c) 2014 AppCoda. All rights reserved.
//
//  領域観測:CLlocationManagerdelegate
//  距離観測
//  [iOS 7] 新たな領域観測サービス iBeacon を使ってみる
//  http://dev.classmethod.jp/references/ios7-ibeacon-api/
//
//  iOS8からはロケーションマネージャの権限取得
//  http://it.senatus.jp/post-210/
//
//  iBeaconsを触ってみた
//  http://atsu666.com/memo/entry-45.html

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

#define kMaxRadius 160

@interface ViewController () {
    
    // 画像配列
    NSArray *YOME_IMAGE;
    
    // 音声読み上げ配列
    NSArray *YOME_SPEECH;
    
    // 音声読み上げ
    AVSpeechSynthesizer *_speechSynthesizer;
    
    // 画像 配列の添字
    int _yomePhase;
    
    // 相対距離:proximity
    CLProximity _privProximity;
    
}

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

// 領域メッセージ
@property (weak, nonatomic) IBOutlet UILabel *statusLabel01;

@property (strong, nonatomic) IBOutlet UIImageView *yomeImage;

@property (weak, nonatomic) IBOutlet UILabel *lbNearest;

@property (weak, nonatomic) IBOutlet UILabel *lbUUID;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // 準備処理　画像・音声
    [self doReady];
    
    // 領域観測判定処理
    [self doCLLocation];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// 準備処理　画像・音声
- (void)doReady {
    
    // 背景画像
    //    UIImage *image = [UIImage imageNamed:@"bag01"];
    //    self.view.backgroundColor = [UIColor colorWithPatternImage:image];
    
    // 画像
    YOME_IMAGE = @[@"xmas_001.png", @"xmas_001.png", @"xmas_002.png", @"xmas_003.png", @"xmas_004.png"];
    
    // 音声読み上げ
    YOME_SPEECH = @[@"このモデルでは、Beaconは利用できません",
                    @"ここはショッピングモールの外です",
                    @"いらっしゃいませ　ショッピングモールにようこそ",
                    @"エルメスのサンダルです？",
                    @"このサンダルは79ドルです"];
    
    // 音声読み上げ AVSpeechSynthesizer
    _speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
}


// 領域観測判定処理
- (void)doCLLocation {
    
    // iBeaconによる領域観測が可能かのチェック（BLEに対応しているデバイスが対象）
    // isMonitoringAvailableForClass: で Beacon による領域観測が可能であるかチェック
    // CLRegion クラスのサブクラスの Objective-C クラス構造体を引数にとって、アプリを実行中のデバイスが引数で渡されたクラスに対応する領域観測を実行できるかを判定します。今回は、Beacon による領域観測を実行するので、CLBeaconRegion のクラス構造体を渡しています。
    if (![CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
        
        // 画像表示・音声合成 初期数[0]
        [self updateYome:0];
        
        //Monitoring not available
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"このモデルでは、Beaconは利用できません"
                              message:nil
                              delegate:nil
                     cancelButtonTitle:@"Ok"
                     otherButtonTitles: nil];
        [alert show];
        return;
        
    } else {
        
        // 画像表示・音声合成[1]
        [self updateYome:1];
        
        // Initialize location manager and set ourselves as the delegate
        // ロケーションマネージャを初期化し、デリゲートとして自分自身を設定する
        // 領域観測の設定
        self.locationManager = [[CLLocationManager alloc] init];
        // delegateの実装
        self.locationManager.delegate = self;
        
        // Create a NSUUID with the same UUID as the broadcasting beacon
        // 放送ビーコンと同じUUIDを持つNSUUIDを作成します。
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"A77A1B68-49A7-4DBF-914C-760D07FBB87B"];
        
        // 領域観測 セットアップ放送ビーコンとしてそのUUIDと同じ識別子を持つ新しい領域
        self.myBeaconRegion = [[CLBeaconRegion alloc]
               initWithProximityUUID:uuid
                               major:1
                               minor:1
                               identifier:@"com.appcoda.testregion"];
        
        self.myBeaconRegion.notifyOnEntry               = NO; // 領域に入った事を監視 YES
        self.myBeaconRegion.notifyOnExit                = NO; // 領域を出た事を監視
        self.myBeaconRegion.notifyEntryStateOnDisplay   = YES; // デバイスのディスプレイがオンのとき、ビーコン通知が送信されない NO
        
        /////////////////////////////////
        // iOS8の追加
        // 位置情報の取得許可を求めるメソッド
        if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            // requestAlwaysAuthorizationメソッドが利用できる場合(iOS8以上の場合)
            // 位置情報の取得許可を求めるメソッド
            [self.locationManager requestAlwaysAuthorization];
        } else {
            // requestAlwaysAuthorizationメソッドが利用できない場合(iOS8未満の場合)
            [self.locationManager startMonitoringForRegion: self.myBeaconRegion];
        }
        /////////////////////////////////
        
        // UUIDの表示
        NSString *lbuuid = self.myBeaconRegion.proximityUUID.UUIDString;
        self.lbUUID.text = [NSString stringWithFormat:@"UUID: %@", lbuuid];
        
        // Tell location manager to start monitoring for the beacon region
        // アドバタイズ(発信、公開) 領域監視を開始
        //[self.locationManager startMonitoringForRegion:self.myBeaconRegion];
        
        // iBeaconとの距離測定を開始
        //[self.locationManager startRangingBeaconsInRegion:self.myBeaconRegion];
        
    }
}

// iOS8 ユーザの位置情報の許可状態を確認するメソッド
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusNotDetermined) {
        // ユーザが位置情報の使用を許可していない
    } else if(status == kCLAuthorizationStatusAuthorizedAlways) {
        // ユーザが位置情報の使用を常に許可している場合
        [self.locationManager startMonitoringForRegion: self.myBeaconRegion];
    } else if(status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        // ユーザが位置情報の使用を使用中のみ許可している場合
        [self.locationManager startMonitoringForRegion: self.myBeaconRegion];
    }
}


// 新しい領域のモニタリングを開始　モニタリング開始が正常に始まった時に呼ばれるdelegateメソッド
-         (void)locationManager:(CLLocationManager *)manager
    didStartMonitoringForRegion:(CLRegion *)region {
    
    // ここでiOS7から追加された”CLLocationManager requestStateForRegion:”を呼び出し、現在自分が、iBeacon監視でどういう状態にいるかを知らせてくれるように要求します。
    [self.locationManager startRangingBeaconsInRegion:self.myBeaconRegion];
}


// 領域に関する状態を取得する
- (void)locationManager:(CLLocationManager *)manager
      didDetermineState:(CLRegionState)state
              forRegion:(CLRegion *)region
{
    
    // CLRegionStateInside が渡ってきていれば、すでになんらかのiBeaconのリージョン内にいるので、iOS7から追加された”CLLocationManager startRangingBeaconsInRegion:”を呼び、通知の受け取りを開始します。
    switch (state) {
        case CLRegionStateInside: // 領域(リージョン)内にいる
            // 領域内にいるので、測距を開始する
            if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
                
                // 通知の受け取りを開始
                [self.locationManager startRangingBeaconsInRegion:self.myBeaconRegion];
                //Beacon の範囲内に入った時に行う処理を記述する
                [self sendLocalNotificationForMessage:@"すでに入っている"];
                self.statusLabel01.text = @"領域内(リージョン)測距開始";
            }
            break;
            
        case CLRegionStateOutside: // 領域(リージョン)の外側
            //NSLog(@"state is 領域(リージョン)の外側");
            self.statusLabel01.text = @"領域(リージョン)の外側";
            break;
        case CLRegionStateUnknown: // 領域(リージョン)不明
            //NSLog(@"state is 領域(リージョン)不明");
            self.statusLabel01.text = @"領域(リージョン)不明";
            break;
        default:
            //NSLog(@"state is 不明");
            self.statusLabel01.text = @"不明";
            break;
    }
}


// メソッドの２番目の引数には、距離測定中の Beacon の配列が渡されてきます。この配列は、Beacon までの距離が近い順にソートされていますので、先頭に格納されている CLBeacon のインスタンスが最も距離が近い Beacon の情報となります
// Beacon距離観測 定期的イベント発生（距離の測定を開始）
-(void)locationManager:(CLLocationManager*)manager
       didRangeBeacons:(NSArray*)beacons
              inRegion:(CLBeaconRegion*)region {
    
    // Beacon found!
    self.statusLabel.text = @"Beacon 検索中!";
    
    //CLBeacon *foundBeacon = [beacons firstObject];
    
    // You can retrieve the beacon data from its properties
    // あなたは、そのプロパティからのビーコンデータを取得することができます
    //NSString *uuid = foundBeacon.proximityUUID.UUIDString;
    
    // major：同一proximityUUIDを持つBeaconの識別子
    // ショッピングモールなどの単位で同一の値を割り当てて、グルーピングするといったような用途が想定されている。
    // Beaconがアドバタイズするデータに、この値を含めるかどうかは任意である。
    // アドバタイズとは、自分の存在を他のデバイスに知らせるために自デバイスや対応サービスの情報を公開する仕組み
    //NSString *major = [NSString stringWithFormat:@"%@", foundBeacon.major];
    
    // major：同一proximityUUIDを持つBeaconの識別子
    // ショッピングモールの各店舗などの単位で値を割り当てて、店舗を識別するといったような用途が想定されている。
    // Beaconがアドバタイズするデータに、この値を含めるかどうかは任意である。
    // アドバタイズとは、自分の存在を他のデバイスに知らせるために自デバイスや対応サービスの情報を公開する仕組み
    //NSString *minor = [NSString stringWithFormat:@"%@", foundBeacon.minor];
    
    //---------------------------------------------//
    
    if (beacons.count > 0) {
        
        // 最も距離の近いBeaconについて処理する
        CLBeacon *beacon = beacons.firstObject;
        // 相対距離:proximity
        if (_privProximity != beacon.proximity) {
            
            //NSLog(@"beacon %ld", (long)beacon.proximity);
            //NSLog(@"privProximity %ld", _privProximity);
            
            // Beacon の距離でメッセージを変える 相対距離:proximity
            switch (beacon.proximity) {
                case CLProximityImmediate: // 1
                    
                    // 必要に応じてより近い判定を外すことで挙動を防ぐ
                    // タイマーを付けて挙動を防ぐテスト必要
                    
                    // Immediate : すぐ近く 4番目
                    //NSLog(@"すぐ近く(1)Immediate %ld", (long)CLProximityImmediate); // 1
                    self.lbNearest.text = @"すぐ近く";
                    [self sendLocalNotificationForMessage:@"50%OFFのシューズです"];
                    [self updateYome:4];
                    break;
                case CLProximityNear: // 2
                    // Near : 近い 3番目
                    //NSLog(@"近い(2)Near %ld", (long)CLProximityNear); // 2
                    self.lbNearest.text = @"近い";
                    [self sendLocalNotificationForMessage:@"セール中のシューズ展示売り場です"];
                    [self updateYome:3];
                    break;
                case CLProximityFar: // 3
                    // Far : 遠い 2番目
                    //NSLog(@"遠い(3)Far %ld", (long)CLProximityFar); // 3
                    self.lbNearest.text = @"遠い";
                    [self sendLocalNotificationForMessage:@"セール中のシューズ展示売り場まで50メートル先です"];
                    [self updateYome:2];
                    break;
                default: // unknown
                    // Unknown : 測距エラー 1番目
                    
                    //NSLog(@"測距エラー");
                    self.lbNearest.text = @"測距エラー";
                    [self sendLocalNotificationForMessage:@"シューズショッピングモール店から離れています"];
                    [self updateYome:1];
                    break;
            }
            //最も距離の近いBeacon 相対距離:proximity
            _privProximity = beacon.proximity;
            
            //-------------------------------------------------------------
            // iBeaconの電波強度を調べて、近距離に来た場合
//            if (  _privProximity == CLProximityImmediate && beacon.rssi > -40 ) {
//                self.lbNearest.text   = @"TOUCH";
//            }
        }
    }
    
    //---------------------------------------------//

}

// ローカル通知内容のメソッド
- (void)sendLocalNotificationForMessage:(NSString *)message
{
    UILocalNotification *localNotification = [UILocalNotification new];
    
    // いつ通知するか、何を表示するかのプロパティをセットする。
    //NSInteger minutes = 2 * 60;
    // 0.1秒
    NSDate *fireDate = [[NSDate alloc]
                        initWithTimeInterval:0.1 // 秒数 minutes
                        sinceDate:[NSDate date]];
    // アクションの有無
    localNotification.hasAction = YES;
    // タイトルを設定する（Apple Watch）
    localNotification.alertTitle = @"[シューズショッピングモール店]";
    // アラートの内容（Apple Watch）
    //localNotification.alertBody = @"シューズ50%セール中";
    localNotification.alertBody = message;
    
    //localNotification.fireDate = [NSDate date];
    // 通知時刻 10秒
    localNotification.fireDate = fireDate;
    // サウンドネーム
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    // アプリケーションに登録する。
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    
    // 準備処理　画像・音声
    [self doReady];
}

#pragma mark - CLLocationManagerDelegate Method

//-------------------------------------
// 領域に入った時
// Beacon内の領域に入る（領域観測）Region（レンジング）　ローカル通知を送っている
- (void)locationManager:(CLLocationManager*)manager
         didEnterRegion:(CLRegion *)region
{
    // We entered a region, now start looking for our target beacons!
    //私たちは、地域に入って、今私たちの目標ビーコンを探し始める！
    // self.statusLabel.text=@"ビーコンを見つける。";
    
    //NSLog(@"ローカル通知 Beacon内の領域に入る %@", region);
    
    // ローカル通知
    [self sendLocalNotificationForMessage:@"いらしゃいませ。"];
    
    self.statusLabel.text = @"Beaconsを見つける。";
    // ローカル通知内容
    [self.locationManager startRangingBeaconsInRegion:self.myBeaconRegion];
    
    // Beaconの距離測定を開始する
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [self.locationManager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
}

//-------------------------------------
// 領域から出た時
// Beacon内の領域から離脱（領域観測）　ローカル通知を送っている
-(void)locationManager:(CLLocationManager*)manager
         didExitRegion:(CLRegion *)region
{
    
    //NSLog(@"ローカル通知 Beacon内の領域から離脱 %@", region);
    
    // ローカル通知
    [self sendLocalNotificationForMessage:@"ありがとうございました。またのお越しをお待ちしております。"];
    // Exited the region
    // 地域を終了しました
    //self.statusLabel.text = @"None found.";
    self.statusLabel.text = @"Beacon範囲から離脱";
    // ローカル通知内容
    [self.locationManager stopRangingBeaconsInRegion:self.myBeaconRegion];
    
    // Beaconの距離測定を終了する
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [self.locationManager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
}


#pragma mark - 画像表示・音声合成 Method

// 画像表示・音声合成
- (void) updateYome:(int)phase {
    
    // 配列の添字[_yomePhase]
    _yomePhase = phase;
    //NSLog(@"%d", phase);
    
    // 配列の画像表示
    self.yomeImage.image = [UIImage imageNamed:YOME_IMAGE[_yomePhase]];
    
    // AVSpeechSynthesizer による音声読み上げ
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:YOME_SPEECH[_yomePhase]];
    // デフォルトは早すぎるので
    utterance.rate = 0.3f;
    // 男性ぽく
    utterance.pitchMultiplier = 1.4f;
    // 再生開始
    [_speechSynthesizer speakUtterance:utterance];
}

@end
