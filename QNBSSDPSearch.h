//
//  QNBSSDPSearch.h
//  QNBDLNA
//
//  Created by milodeng on 2017/3/22.
//  Copyright © 2017年 limodeng. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QNBSSDPSearch;

@protocol QNBSSDPSearchDelegate <NSObject>

-(void)deviceCallBack:(QNBSSDPSearch*)ssdpSearch withDictionary:(NSDictionary*)deviceList;

@end
@interface QNBSSDPSearch : NSObject

+ (QNBSSDPSearch*)shareInstance;

- (void)startSearch;

- (void)stopSearch;

- (void)registerDelegate:(id <QNBSSDPSearchDelegate>)delegate;

- (void)unregisterDelegate:(id <QNBSSDPSearchDelegate>)delegate;
@end
