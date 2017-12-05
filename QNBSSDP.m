//
//  QNBSSDP.m
//  QNBDLNA
//
//  Created by milodeng on 2017/3/22.
//  Copyright © 2017年 limodeng. All rights reserved.
//

#import "QNBSSDP.h"
#include <arpa/inet.h>
#import "QNBSSDPDefine.h"

@interface QNBSSDP()
@property(copy,nonatomic) NSString* browserType;

@end

@implementation QNBSSDP{
    struct sockaddr_in destination;
    size_t echolen;
    const char *cmsg;
    int sock;
    BOOL searchingActive;
}
-(instancetype)initWithBrowserType:(NSString*)browserType{
    self = [super init];
    if(self){
        _browserType = browserType;
    }
    return self;
}

-(int)createSocket{
    if ((sock = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP)) < 0) {
        NSLog(@"Failed to create socket");
        return -1;
    }
    memset(&destination, 0, sizeof(destination));
    destination.sin_family = AF_INET;
    destination.sin_addr.s_addr = inet_addr([SSDP_DISCOVER_IP UTF8String]);
    destination.sin_port = htons(SSDP_DISCOVER_PORT);
    setsockopt(sock, IPPROTO_IPIP, IP_MULTICAST_IF, &destination, sizeof(destination)); // IPPROTO_IP
    
    cmsg = [[self discoverDeviceString] UTF8String];
    echolen = strlen(cmsg);
    int broadcast = 1;
    struct timeval tv;
    tv.tv_sec = 2;
    tv.tv_usec = 0;
    if (setsockopt(sock, SOL_SOCKET, SO_BROADCAST, &broadcast, sizeof(broadcast)) == -1) {
        perror("setsockopt");
        return -1;
    }
    return sock;
}

- (NSString *)discoverDeviceString {
    NSString *str = [NSString stringWithFormat:(NSString *) SSDP_DISCOVER_DEVICES, self.browserType];
    NSLog(@"SearchString:%@", str);
    return str;
}

-(int)sendBroadCast{
    if (sendto(sock, cmsg, echolen, 0, (struct sockaddr *) &destination, sizeof(destination)) != echolen) {
        printf("Sent the wrong number of bytes\n");
        return 0;
    }
    if (sock > 0) {
        [self receiveSsdpResponsesOnSocket];
    }
    return 0;
}

- (void)receiveSsdpResponsesOnSocket {
    struct sockaddr_in myaddr;
    int repeatcount = 0; //每次搜索查询3次
    
    myaddr.sin_family = PF_INET;
    myaddr.sin_addr.s_addr = INADDR_ANY;
    myaddr.sin_port = htons(SSDP_DISCOVER_PORT);
    memset(&(myaddr.sin_zero), '\0', 8);
    
    fd_set readfs;
    struct sockaddr addr;
    socklen_t fromlen;
    char buf[512];
    size_t len = 0;
    
    FD_ZERO(&readfs);
    FD_SET(sock, &readfs);
    
    struct timeval timeout;
    timeout.tv_sec = 2;
    timeout.tv_usec = 0;
    int n = sock + 1;
    
    while (repeatcount < 3) {
        if (!searchingActive) {
            NSLog(@"Finished SSDP scan");
            [self stopSSDPScanning];
            break;
        }
        repeatcount++;
        int s = select(n, &readfs, NULL, NULL, &timeout);
        if (s > 0) {
            if (FD_ISSET(sock, &readfs)) {
                len = recvfrom(sock, &buf, sizeof(buf), 0, &addr, &fromlen);
                if (len<=0) {
                    [self stopSSDPScanning];
                    return;
                }
                buf[len] = '\0';
                
                NSString *dataString = [[NSString alloc] initWithBytes:buf length:len encoding:NSUTF8StringEncoding];
                @synchronized(dataString){
                    NSLog(@"datastring:%@", dataString);
                    if (!dataString) {
                        NSLog(@"没有数据包返回，数据丢失，等级警告");
                        [self stopSSDPScanning];
                        return;
                    }
                    NSDictionary *serviceDict = [self fetchDicFromString:dataString];
                    if (!_delegate||!serviceDict) {
                        [self stopSSDPScanning];
                        return;
                    }
                    if([self.delegate respondsToSelector:@selector(browserType:withFoundService:)]){
                        [self.delegate browserType:self.browserType withFoundService:serviceDict];
                    }
                }
            }
        } else {
            [self stopSSDPScanning];
            return;
        }
        repeatcount++;
        if (repeatcount>=3) {
            [self stopSSDPScanning];
            return;
        }
    }
}

-(NSDictionary*)fetchDicFromString:(NSString*)dataString{
    NSArray *lines = [dataString componentsSeparatedByString:@"\r\n"];
    NSMutableDictionary *renderDic = [NSMutableDictionary dictionary];
    for (int row = 0; row < lines.count; row++) {
        NSString *line = lines[row];
        NSString *trimmed = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (row == 0) {
            if ([trimmed isEqualToString:@"HTTP/1.1 200 OK"] || [trimmed isEqualToString:@"NOTIFY * HTTP/1.1"]) {
                
            } else {
                return nil;
            }
        }
        NSUInteger colonLocation = [trimmed rangeOfString:@":"].location;
        if (colonLocation == NSNotFound) {
            continue;
        }
        NSString *key = [[trimmed substringToIndex:colonLocation] uppercaseString];
        NSString *value = nil;
        if (colonLocation + 1 < [trimmed length]) {
            value = [trimmed substringWithRange:NSMakeRange(colonLocation + 1, [trimmed length] - (colonLocation + 1))];
        }
        
        if (key && value) {
            renderDic[key] = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
    }
    
    return renderDic;

}
#pragma 公共方法

-(void)startSSDPScanning{
    searchingActive = YES;
    [self createSocket];
    [self sendBroadCast];
}
-(void)stopSSDPScanning{
    searchingActive = NO;
    close(sock);
    shutdown(sock,SHUT_RDWR);
    NSThread * searchThread = [NSThread currentThread];
    [searchThread cancel];
    searchThread = nil;
    if (![NSThread isMainThread]) {
        [NSThread exit]; //解决切换网络搜索不设备的问题
    }

}
@end
