
//
//  PeripheralViewController.m
//  BLE_DEMO
//
//  Created by eason on 2017/9/27.
//  Copyright © 2017年 carey. All rights reserved.
//
#define SeriveID6666 @"6666"
#define SeriveID7777 @"7777"
#define CID8888 @"8888"  //读指令(监控蓝牙设备往APP发数据),6666提供
#define CID8877 @"8877"  //APP向蓝牙发指令,7777提供
#import "PeripheralViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
@interface PeripheralViewController ()<UITableViewDelegate,UITableViewDataSource,CBCentralManagerDelegate>
@property (nonatomic,strong) UITableView *tableView;
@end

@implementation PeripheralViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    CBCentralManager *manager = [[CBCentralManager alloc] initWithDelegate:nil queue:nil];
//    [manager connectPeripheral:self.peripheral
//                              options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView  = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.tableView];
    self.tableView.backgroundColor = [UIColor whiteColor];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section==0) {
        return self.peripheral.services.count;

    }else{
        return self.seversCharateristic.count;
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell1"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:@"cell1"];
    }
    if(indexPath.section == 0){
        CBService *s = self.peripheral.services[indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"%@",s.UUID.UUIDString];
    }
    else{
        CBCharacteristic *c = self.seversCharateristic[indexPath.row];
        cell.textLabel.text  = [NSString stringWithFormat:@"服务:%@",c];
    }
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"外设的服务";
    }else{
        return @"每个服务的特征";
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - peripheralDelegate

//发现服务时调用
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        NSLog(@"%@发现服务时出错: %@", peripheral.name, [error localizedDescription]);
        return;
    }
    if (self.peripheralServers) {
        [self.peripheralServers removeAllObjects];
    }
    [self.peripheralServers addObjectsFromArray:peripheral.services];
    [self.tableView reloadData];
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
    if (self.seversCharateristic) {
        [self.seversCharateristic removeAllObjects];
    }
    [self.seversCharateristic addObjectsFromArray:service.characteristics];
    [self.tableView reloadData];
    //获取Characteristic的值
    for (CBCharacteristic *c in service.characteristics) {
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
            [peripheral readValueForCharacteristic:c];
            //获取数据后,进入代理方法:
            //- peripheral: didUpdateValueForCharacteristic: error:
            //根据蓝牙协议发送指令,写在这里是自动发送,也可以写按钮方法,手动操作
            //我将指令封装了一个类,以下三个方法是其中的三个操作,具体是啥不用管,就知道是三个基本操作,返回数据后,会进入代理方法
            //校准时间
            //            [CBCommunication cbCorrectTime:peripheral characteristic:characteristic];
            //获取mac地址
            //            [CBCommunication cbGetMacID:peripheral characteristic:characteristic];
            //获取脱机数据
            //            [CBCommunication cbReadOfflineData:peripheral characteristic:characteristic];
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
