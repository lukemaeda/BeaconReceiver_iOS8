//
//  ViewController.h
//  BeaconReceiver
//
//  Created by Christopher Ching on 2014-04-27.
//  Copyright (c) 2014 AppCoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface ViewController : UIViewController<CLLocationManagerDelegate>


@property (strong, nonatomic) CLBeaconRegion *myBeaconRegion;
@property (strong, nonatomic) CLLocationManager *locationManager;

@end
