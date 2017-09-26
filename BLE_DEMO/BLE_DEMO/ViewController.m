//
//  ViewController.m
//  BLE_DEMO
//
//  Created by eason on 2017/9/25.
//  Copyright © 2017年 carey. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
@interface ViewController ()<CBCentralManagerDelegate,UITableViewDelegate,UITableViewDataSource,CBPeripheralDelegate>
@property (nonatomic, strong) CBCentralManager *manager;
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSMutableArray *peripheralArray;
@property (nonatomic,strong) NSMutableArray *connectedPeripheralArray;
@end

@implementation ViewController
-(NSMutableArray *)peripheralArray {
    if (!_peripheralArray) {
        _peripheralArray = [NSMutableArray array];
    }
    return _peripheralArray;
}
-(NSMutableArray *)connectedPeripheralArray {

    if (!_connectedPeripheralArray) {
        _connectedPeripheralArray = [NSMutableArray array];
    }
    return _connectedPeripheralArray;
}
- (void)viewDidLoad {
    [super viewDidLoad];
//    UIButton *btn = [[UIButton alloc] init];
//    btn.frame = CGRectMake(100,50, 100, 50);
//    [btn setTitle:@"add_ble" forState:UIControlStateNormal];
//    [btn setBackgroundColor:[UIColor redColor]];
//    [self.view addSubview:btn];
//    [btn addTarget:self action:@selector(addBLE) forControlEvents:UIControlEventTouchUpInside];
    
    
    self.tableView = [[UITableView alloc] init];
    self.tableView.frame =self.view.frame;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    self.manager = [[CBCentralManager alloc] init];
    self.manager.delegate = self;
    
    [self.manager scanForPeripheralsWithServices:nil options:nil];
    
}
- (void)addBLE {
    NSLog(@"addBLE");
    self.manager = [[CBCentralManager alloc] init];
    self.manager.delegate = self;
 
    [self.manager scanForPeripheralsWithServices:nil options:nil];
    
}

#pragma mark - CBCentralManagerDelegate
//监听蓝牙状态,蓝牙状态改变时调用
//不同状态下可以弹出提示框交互
//如果单独封装了这个类,可以设置代理或block或通知向控制器传值
-(void)centralManagerDidUpdateState:(CBCentralManager *)central{
    switch (central.state) {
        case CBCentralManagerStateUnknown:
            NSLog(@">>>蓝牙未知状态");
            break;
        case CBCentralManagerStateResetting:
            NSLog(@">>>蓝牙重启");
            break;
        case CBCentralManagerStateUnsupported:
            NSLog(@">>>不支持蓝牙");
            break;
        case CBCentralManagerStateUnauthorized:
            NSLog(@">>>未授权");
            break;
        case CBCentralManagerStatePoweredOff:
            NSLog(@">>>蓝牙关闭");
            break;
        case CBCentralManagerStatePoweredOn:
            NSLog(@">>>蓝牙打开");
            //蓝牙打开时,再去扫描设备
            [self.manager scanForPeripheralsWithServices:nil options:nil];
            break;
        default:
            break;
    }
}
//发现外设时调用
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    
    if (![_peripheralArray containsObject:peripheral]) {
        NSLog(@"发现外设:%@", peripheral);
        //打印结果:
        //发现外设:<CBPeripheral: 0x15f5bac80, identifier = 955A5FFD-790E-BA3C-2A94-29FEA8A14A58, name = TF1603(BLE), state = disconnected>
        //发现设备后,需要持有他
        [_peripheralArray addObject:peripheral];
        // NSLog(@"信号强度:%@", RSSI);
        //如果之前调用扫描外设的方法时,设置了相关参数,只会扫描到指定设备,可以考虑自动连接
        //[_cbManager connectPeripheral:peripheral options:nil];
        //刷新表格显示扫描到的设备
        [self.tableView reloadData];
        //如果这是单独封装的类,这里需要用代理或block或通知传值给控制器来刷新视图
    }
}

//外设连接成功时调用
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"连接成功");
    //将连接的设备添加到_connectedPeripheralArray
    [self.connectedPeripheralArray addObject: peripheral];
    //如果tableView展示的是已经连接的设备
    //[tableView reloadData];
    //如果这是单独封装的类,这里需要用代理或block或通知传值给控制器来刷新视图
    //设置外设代理
    peripheral.delegate = self;
    //搜索服务
    [peripheral discoverServices:nil];
}
//外设连接失败时调用
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"连接失败,%@", [error localizedDescription]);
}
//断开连接时调用
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"断开连接");
    //移除断开的设备
    [_connectedPeripheralArray removeObject:peripheral];
    //这里可以进行一些操作,如之前连接时,监听了某个特征的通知,这里可以取消监听
}
//发现服务时调用
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        NSLog(@"%@发现服务时出错: %@", peripheral.name, [error localizedDescription]);
        return;
    }
    //遍历外设的所有服务
    for (CBService *service in peripheral.services) {
        NSLog(@"外设服务: %@", service);
        //打印结果
        //外设服务: <CBService: 0x15f5d0be0, isPrimary = YES, UUID = 6666>
        //外设服务: <CBService: 0x15f5d1f60, isPrimary = YES, UUID = 7777>
        //我定义了两个宏
        //#define SeriveID6666 @"6666"
        //#define SeriveID7777 @"7777"
        //每个服务又包含一个或多个特征,搜索服务的特征
        [peripheral discoverCharacteristics:nil forService:service];
    }
}
//发现特征时调用,由几个服务,这个方法就会调用几次
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        NSLog(@"扫描特征出错:%@", [error localizedDescription]);
        return;
    }
    //获取Characteristic的值
    for (CBCharacteristic *characteristic in service.characteristics) {
        NSLog(@"服务server:%@ 的特征:%@, 读写属性:%ld", service.UUID.UUIDString, c, c.properties);
        //第一次调用,打印结果:
        //服务server:6666 的特征:<CBCharacteristic: 0x135e37410, UUID = 8888, properties = 0xDE, value = (null), notifying = NO>, 读写属性:->222
        //如果一个服务包含多种特征,会循环打出其他特征,我的设备正好一个服务只包含一个特征,处理起来方便了许多.
        //第二次调用,打印结果:
        //服务server:7777 的特征:<CBCharacteristic: 0x135e3d260, UUID = 8877, properties = 0x4E, value = (null), notifying = NO>, 读写属性:->78
        //特征也用UUID来区分,注意和service的UUID区别开来
        //和厂家确认,server(uuid=6666)的特征characteristic(uuid=8888)是监控蓝牙设备往APP发数据的,
        //server(uuid=7777)的特征characteristic(uuid=8877)向蓝牙发送指令的.
        //对特征定义宏
        //#define CID8888 @"8888"  //读指令(监控蓝牙设备往APP发数据),6666提供
        //#define CID8877 @"8877"  //APP向蓝牙发指令,7777提供
        //UUID=8888的特征有通知权限,在我的项目中是实时接收蓝牙状态发送过来的数据
        if ([service.UUID.UUIDString isEqualToString:SeriveID6666]) {
            for (CBCharacteristic *c in service.characteristics) {
                if ([c.UUID.UUIDString isEqualToString:CID8888]) {
                    //设置通知,接收蓝牙实时数据
                    [self notifyCharacteristic:peripheral characteristic:c];
                }
            }
        }
        if ([service.UUID.UUIDString isEqualToString:SeriveID7777]) {
            [peripheral readValueForCharacteristic:characteristic];
            //获取数据后,进入代理方法:
            //- peripheral: didUpdateValueForCharacteristic: error:
            //根据蓝牙协议发送指令,写在这里是自动发送,也可以写按钮方法,手动操作
            //我将指令封装了一个类,以下三个方法是其中的三个操作,具体是啥不用管,就知道是三个基本操作,返回数据后,会进入代理方法
            //校准时间
            [CBCommunication cbCorrectTime:peripheral characteristic:characteristic];
            //获取mac地址
            [CBCommunication cbGetMacID:peripheral characteristic:characteristic];
            //获取脱机数据
            [CBCommunication cbReadOfflineData:peripheral characteristic:characteristic];
        }
    }
    //描述相关的方法,代理实际项目中没有涉及到,只做了解
    //搜索Characteristic的Descriptors
    for (CBCharacteristic *characteristic in service.characteristics){
        [peripheral discoverDescriptorsForCharacteristic:characteristic];
        //回调方法:
        // - peripheral: didDiscoverDescriptorsForCharacteristic: error:;
        //还有写入读取描述值的方法和代理函数
    }
}
#pragma mark - 设置通知
//设置通知
-(void)notifyCharacteristic:(CBPeripheral *)peripheral
             characteristic:(CBCharacteristic *)characteristic{
    
    if (characteristic.properties & CBCharacteristicPropertyNotify) {
        [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        //设置通知后,进入代理方法:
        //- peripheral: didUpdateNotificationStateForCharacteristic: characteristic error:
    }
}
//取消通知
-(void)cancelNotifyCharacteristic:(CBPeripheral *)peripheral
                   characteristic:(CBCharacteristic *)characteristic{
    [peripheral setNotifyValue:NO forCharacteristic:characteristic];
}
//设置通知后调用,监控蓝牙传回的实时数据
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"错误: %@", error.localizedDescription);
    }
    if (characteristic.isNotifying) {
        [peripheral readValueForCharacteristic:characteristic];
        //获取数据后,进入代理方法:
        //- peripheral: didUpdateValueForCharacteristic: error:
    } else {
        NSLog(@"%@停止通知", characteristic);
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return self.peripheralArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    }
    return cell;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
