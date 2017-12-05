//
//  QNBSSDPSearch.m
//  QNBDLNA
//
//  Created by milodeng on 2017/3/22.
//  Copyright © 2017年 limodeng. All rights reserved.
//

#import "QNBSSDPSearch.h"
#import "QNBSSDP.h"
#import "QNBSSDPDefine.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import "QNBDeviceRender.h"


typedef void(^delayBlock)();

@interface QNBSSDPSearch()<QNBSSDPDelegate>
@property(strong,nonatomic)NSMutableDictionary *renderDic;
@property(strong,nonatomic)NSMutableDictionary *serverDic;
@property(strong,nonatomic)dispatch_queue_t searchSerialQueue;
@property(strong,nonatomic)QNBSSDP *renderSSDP;
@property(strong,nonatomic)QNBSSDP *serverSSDP;
@property(strong,nonatomic)NSString *wifiSSID;
@property(assign,nonatomic)BOOL isSearching;
@property(strong,nonatomic,readwrite) NSHashTable <id<QNBSSDPSearchDelegate>>* delegates;

@end
@implementation QNBSSDPSearch

static QNBSSDPSearch* instance = nil;
+ (QNBSSDPSearch*) shareInstance{
    @synchronized(self) {
        if (instance == nil) {
            instance = [[super alloc] init];
        }
    }
    return instance;
}
-(instancetype)init{
    self = [super init];
    if(self){
        [self createData];
        [self createSerialQueue];
    }
    return self;
}
-(void)createData{
    if(!_renderDic){
        _renderDic = [NSMutableDictionary dictionary];
    }
    if(!_serverDic){
        _serverDic = [NSMutableDictionary dictionary];
    }
    _delegates = [NSHashTable weakObjectsHashTable];
    _renderSSDP = [[QNBSSDP alloc] initWithBrowserType:UPNP_MEDIARENDER];
    _serverSSDP = [[QNBSSDP alloc] initWithBrowserType:UPNP_MEDIASERVER];
    _renderSSDP.delegate = self;
    _serverSSDP.delegate = self;
}
-(dispatch_queue_t)createSerialQueue{
    if (!_searchSerialQueue) {
        _searchSerialQueue = dispatch_queue_create("tentcent.com.milo.dlna.search", DISPATCH_QUEUE_SERIAL);//创建串行队列
        dispatch_set_target_queue(_searchSerialQueue,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0));
    }
    return _searchSerialQueue;
}
- (void)delayExcuteSearchTime:(float)delaytime withBlock:(delayBlock)block {
    dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaytime * NSEC_PER_SEC));
    dispatch_after(when, _searchSerialQueue, block);
}

#pragma mark --QNBSSDPDelegate

-(void)browserType:(NSString *)type withFoundService:(NSDictionary *)serviceDic{
    if(serviceDic.count<=0){
        return;
    }
    //wifi改变，清除设备
    NSString *offsetSSID = [self fetchSSIDInfo];
    if (!offsetSSID || ![offsetSSID isEqualToString:_wifiSSID]) {
        [_renderDic removeAllObjects];
        [_serverDic removeAllObjects];
        _wifiSSID = offsetSSID;
        return;
    }
    if([type isEqualToString:UPNP_MEDIARENDER]){
      NSLog(@"render:%@", serviceDic);
        //处理服务列表数据
    }
    if([type isEqualToString:UPNP_MEDIASERVER]){
        NSLog(@":server%@", serviceDic);
        //处理服务列表数据

    }
}


#pragma 网络判断
- (NSString *)fetchSSIDInfo{
    NSString *info = nil;
    CFArrayRef supportedInterfacesArrayRef = CNCopySupportedInterfaces();
    NSArray *netArray = (__bridge NSArray *) supportedInterfacesArrayRef;
    for (NSString *netItem in netArray) {
        CFDictionaryRef dicRef = CNCopyCurrentNetworkInfo((__bridge CFStringRef) netItem);
        if (dicRef != NULL) {
            CFStringRef ssid = CFDictionaryGetValue(dicRef, kCNNetworkInfoKeySSID);
            info = (__bridge id) ssid;
        }
    }
    return info;
}


#pragma 公共方法
- (void)registerDelegate:(id <QNBSSDPSearchDelegate>)delegate {
    if (delegate) {
        @synchronized (_delegates) {
            if (![_delegates containsObject:delegate]) {
                [_delegates addObject:delegate];
            }
        }
    }
}

- (void)unregisterDelegate:(id <QNBSSDPSearchDelegate>)delegate {
    if (delegate) {
        @synchronized (_delegates) {
            [_delegates removeObject:delegate];
        }
    }
}

-(void)callDelegate:(NSDictionary*)dic{
    NSHashTable< id<QNBSSDPSearchDelegate> > *copy = nil;
    @synchronized (self.delegates) {
        if ([self.delegates count] > 0) {
            copy = [self.delegates copyWithZone:nil];
        }
    }
    if (copy) {
        for(id<QNBSSDPSearchDelegate> del in copy) {
            if ([del respondsToSelector:@selector(deviceCallBack:withDictionary:)]) {
                [del deviceCallBack:self withDictionary:dic];
            }
        }
    }

}
-(void)startSearch{
    //无网络返回
    self.isSearching = YES;
    if (![self fetchSSIDInfo]) {
        //抛出回调
        [self callDelegate:nil];
        return;
    };
    for (int row =0; row <QNBSSDPSearchCount; row++) {
        [self delayExcuteSearchTime:row*(QNBSSDPSearchLockTime) withBlock:^{
            if(self.isSearching)
            [_renderSSDP startSSDPScanning];
        }];
        [self delayExcuteSearchTime:row*(QNBSSDPSearchLockTime+QNBSSDPSearchGapTime) withBlock:^{
            if(self.isSearching)
            [_serverSSDP startSSDPScanning];
        }];
    }
}
-(void)stopSearch{
    self.isSearching = NO;
    [_renderSSDP stopSSDPScanning];
    [_serverSSDP stopSSDPScanning];
}
@end
