//
//  QNBSSDP.h
//  QNBDLNA
//
//  Created by milodeng on 2017/3/22.
//  Copyright © 2017年 limodeng. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol QNBSSDPDelegate <NSObject>
@required
-(void)browserType:(NSString*)type withFoundService:(NSDictionary*)service;
@end
@interface QNBSSDP : NSObject
@property(weak,nonatomic) id <QNBSSDPDelegate> delegate;

-(instancetype)initWithBrowserType:(NSString*)browserType;

/**
 开始搜索dlna设备
 */
-(void)startSSDPScanning;


/**
 停止搜索dlna设备
 */
-(void)stopSSDPScanning;

@end
