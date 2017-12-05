//
//  QNBSSDPDefine.h
//  QNBDLNA
//
//  Created by milodeng on 2017/3/22.
//  Copyright © 2017年 limodeng. All rights reserved.
//
#import <Foundation/Foundation.h>

#ifndef QNBSSDPDefine_h
#define QNBSSDPDefine_h


//搜索类型
#define SSDP_ALL @"ssdp:all"
#define UPNP_MEDIASERVER @"urn:schemas-upnp-org:device:MediaServer:1"
#define UPNP_MEDIARENDER @"urn:schemas-upnp-org:device:MediaRenderer:1"


//广播地址
static const NSString* SSDP_DISCOVER_IP = @"239.255.255.250";
//端口号
static const NSUInteger SSDP_DISCOVER_PORT = 1900;
//搜索设置
static const NSString* SSDP_DISCOVER_DEVICES = @"M-SEARCH * HTTP/1.1\r\n\
HOST: 239.255.255.250:1900 \r\n\
Man: \"ssdp:discover\"\r\n\
MX: 5\r\n\
ST: %@\r\n\
\r\n";


#define  QNBSSDPSearchCount 3
#define  QNBSSDPSearchLockTime 3
#define  QNBSSDPSearchGapTime 1

#endif /* QNBSSDPDefine_h */
