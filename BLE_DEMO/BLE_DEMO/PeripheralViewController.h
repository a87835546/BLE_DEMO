//
//  PeripheralViewController.h
//  BLE_DEMO
//
//  Created by eason on 2017/9/27.
//  Copyright © 2017年 carey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
@interface PeripheralViewController : UIViewController
@property (nonatomic,strong) NSMutableArray *peripheralServers;
@property (nonatomic,strong) NSMutableArray *seversCharateristic;
@property (nonatomic,strong) CBPeripheral *peripheral;
@end
