//
//  LJFTPClient.m
//  LJFTPClientDemo
//
//  Created by 刘瑾 on 2016/11/1.
//  Copyright © 2016年 刘瑾. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "LJFTPClient.h"
#import "LJFTPCatModel/FTPCatFileModel.h"

#define kFTPServer @"www.liujinxixi.cn"
#define kFTPPort 21

@interface LJFTPClient ()<NSStreamDelegate>
{
    uint64_t numberOfBytesReceived;
    uint64_t numberOfBytesSent;
    
}

@property (nonatomic) NSString *dataIPAddress;
@property (nonatomic, assign) UInt16 dataPort;

@property (nonatomic) NSString *FTPUserName;
@property (nonatomic) NSString *FTPUserPassword;

//指令输入输出流
@property (nonatomic) NSInputStream *inputStream;
@property (nonatomic) NSOutputStream *outputStream;
//数据输入输出流
@property (nonatomic) NSInputStream *dataInputStream;
@property (nonatomic) NSOutputStream *dataOutputStream;

//上一次接收响应的响应码
@property (nonatomic) NSString *lastResponseCode;
@property (nonatomic,assign) int lastResponseCodeInt;
//上一次接收响应的信息
@property (nonatomic) NSString *lastResponseMessage;

//上一次发送的命令
@property (nonatomic) NSString *lastCommandSent;

//标识FTPClient的状态
@property (nonatomic,assign) BOOL isConnected;
@property (nonatomic,assign) BOOL loggedOn;
@property (nonatomic,assign) BOOL isDataStreamConfigured;
@property (nonatomic,assign) BOOL isDataStreamAvailable;

//标识命令输入输出流的连接状态
@property (nonatomic,assign) BOOL isInputStreamConnected;
@property (nonatomic,assign) BOOL isOutputStreamConnected;

//标识数据输入输出流的连接状态
@property (nonatomic,assign) BOOL isInputDataStreamConnected;
@property (nonatomic,assign) BOOL isOutputDataStreamConnected;

@end

@implementation LJFTPClient

#pragma mark - FTPClient Method

-(instancetype )initFTPClientWithUserName:(NSString *)userName andUserPassword:(NSString *)userPassword{
    
    if (self = [super init]) {
        _isConnected = NO;
        
        _isInputStreamConnected = NO;
        _isOutputStreamConnected = NO;
        _isInputDataStreamConnected = NO;
        _isOutputDataStreamConnected = NO;
        
        self.FTPUserName = userName;
        self.FTPUserPassword = userPassword;
        
    }
    return self;
}

-(void )connectFTPServer{
    if (!self.isConnected) {
        [self openFTPNetworkCommunication];
    }
}

-(void )disconnectFTPServer{
    if (self.isConnected) {
        [self closeFTPNetworkCommunication];
    }
}

-(void )setupStream:(NSStream *)aStream WithConnectionStatus:(BOOL)connectionStatus{
    
    if (aStream == self.inputStream) {
        self.isInputStreamConnected = connectionStatus;
    }else if (aStream == self.outputStream){
        self.isOutputStreamConnected = connectionStatus;
    }else if (aStream == self.dataInputStream){
        self.isInputDataStreamConnected = connectionStatus;
    }else if (aStream == self.dataOutputStream){
        self.isOutputDataStreamConnected = connectionStatus;
    }
    
}

#pragma mark - thread management

+(NSThread *)networkThread{
    static NSThread *networkThread = nil;
    static dispatch_once_t multiThreadSingleton;
    
    dispatch_once(&multiThreadSingleton, ^{
        networkThread = [[NSThread alloc] initWithTarget:self selector:@selector(networkThreadMain) object:nil];
        [networkThread start];
    });
    return networkThread;
}

+(void )networkThreadMain{
    do{
        @autoreleasepool {
            [[NSRunLoop currentRunLoop] run];
        }
    }while(YES);
}

-(void )scheduleInCurrentThread:(NSStream *)senderStream{
    [senderStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

#pragma mark - FTPConnection

-(void )openFTPNetworkCommunication{
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    
    //打开流连接
    CFStreamCreatePairWithSocketToHost(NULL,(__bridge CFStringRef) kFTPServer, kFTPPort, &readStream, &writeStream);
    
    self.inputStream = (__bridge_transfer NSInputStream *)readStream;
    self.outputStream = (__bridge_transfer NSOutputStream *)writeStream;
    
    self.inputStream.delegate = self;
    self.outputStream.delegate = self;
    
    [self performSelector:@selector(scheduleInCurrentThread:) onThread:[[self class] networkThread] withObject:self.inputStream waitUntilDone:YES];
    
    [self performSelector:@selector(scheduleInCurrentThread:) onThread:[[self class] networkThread] withObject:self.outputStream waitUntilDone:YES];
    
    [self.inputStream open];
    [self.outputStream open];
    
    self.isConnected = YES;
    self.isDataStreamConfigured = NO;
}

-(void )closeFTPNetworkCommunication{
    [self sendCommand:@"QUIT"];
    [self closeFTPDataCommnunication];
    [self closeNSStream:self.inputStream];
    [self closeNSStream:self.outputStream];
    self.isConnected = NO;
    self.isDataStreamConfigured = NO;
    self.isDataStreamAvailable = NO;
    
}

-(void )openFTPDataCommnunication{
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)self.dataIPAddress, self.dataPort, &readStream, &writeStream);
    
    self.dataInputStream = (__bridge_transfer NSInputStream *)readStream;
    self.dataOutputStream = (__bridge_transfer NSOutputStream *)writeStream;
    
    self.dataInputStream.delegate = self;
    self.dataOutputStream.delegate = self;
    
    [self performSelector:@selector(scheduleInCurrentThread:) onThread:[[self class] networkThread] withObject:self.dataInputStream waitUntilDone:YES];
    [self performSelector:@selector(scheduleInCurrentThread:) onThread:[[self class] networkThread] withObject:self.dataOutputStream waitUntilDone:YES];
    
    [self.dataInputStream open];
    [self.dataOutputStream open];
    
    self.isDataStreamAvailable = YES;
}

-(void )closeFTPDataCommnunication{
    [self closeNSStream:self.dataInputStream];
    [self closeNSStream:self.dataOutputStream];
}

-(void )closeNSStream:(NSStream *)aStream{
    if (aStream.streamStatus != NSStreamStatusClosed) {
        [aStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        aStream.delegate = nil;
        [aStream close];
    }
}

#pragma mark - NSStreamDelegate

-(void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode{
    
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
//            NSLog(@"连接成功 %@", aStream);
            [self setupStream:aStream WithConnectionStatus:YES];
            
            break;
            
        case NSStreamEventHasBytesAvailable:
//            NSLog(@"接收数据 %@", aStream);
            //输入流，接收命令信息
            if (aStream == self.inputStream) {
                uint8_t buffer[1024];
                long len;
                while ([self.inputStream hasBytesAvailable]) {
                    len = [self.inputStream read:buffer maxLength:sizeof(buffer)];
                    numberOfBytesReceived += len;
                    if (len > 0) {
                        NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
                        if (output) {
                            [self parseResponseMessage:output];
                        }
                    }
                }
            }else if (aStream == self.dataInputStream){
                uint8_t buffer[8192];
                long len;
                while ([self.dataInputStream hasBytesAvailable]) {
                    len = [self.dataInputStream read:buffer maxLength:sizeof(buffer)];
                    numberOfBytesReceived += len;
                    if (len > 0) {
                        NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSUTF8StringEncoding];
                        
                        if ([self.lastCommandSent isEqualToString:@"LIST"]) {
                            NSLog(@"-----%@-----", self.lastCommandSent);
                            NSArray <NSString *> *listString = [output componentsSeparatedByString:@"\n"];
                            NSMutableArray <NSString *> *listDataString = [NSMutableArray arrayWithArray:listString];
                            [listDataString removeLastObject];
                            [listDataString enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//                               NSLog(@"%ld  %@", idx ,obj);
                                [FTPCatFileModel createFileFromString:obj];
                            }];
                            
                        }
                        
                    }
                }
            }
            
            break;
        
        case NSStreamEventHasSpaceAvailable:
//            NSLog(@"发送数据 %@", aStream);
            break;
            
        case NSStreamEventErrorOccurred:
            NSLog(@"连接关闭 %@", aStream);
            [self setupStream:aStream WithConnectionStatus:NO];
            
            break;
            
        case NSStreamEventEndEncountered:
            NSLog(@"连接失败 %@", aStream);
            break;
        
        case NSStreamEventNone:
            NSLog(@"待用 %@", aStream);
            break;
            
    }
    
}

#pragma mark - FTPDataCmdCommunication

-(NSArray *)parseLISTCmdData:(NSString *)ListData{
    
    
    return [NSArray new];
}

-(void )parseResponseMessage:(NSString *)stringData{
    NSLog(@"%@", stringData);
    self.lastResponseCode = [stringData substringToIndex:3];
    self.lastResponseMessage = stringData;
    self.lastResponseCodeInt = [self.lastResponseCode intValue];
    
    switch (self.lastResponseCodeInt) {
        case 150:
            //打开连接
            break;
            
        case 200:
            //成功
            [self sendCommand:@"PASV"];
            break;
            
        case 220:
            //服务就绪 需要输入账号
            [self sendUserName];
            break;
            
        case 226:
            //结束数据连接
            break;
        
        case 227:
            //进入被动模式（IP 地址、ID 端口
            
            [self acceptDataStreamConfiguration:stringData];
            [self sendCmdList];
            break;
            
        case 230:
            //登录因特网
            
            [self sendCommand:@"PASV"];
            
            break;
            
        case 331:
            //要求密码
            [self sendUserPassword];
            break;
            
        case 530:
            //未登录网络 用户名或密码错误
            break;
            
        default:
            
            break;
    }
    
    
}

-(void )acceptDataStreamConfiguration:(NSString *)serverResponse{
    
    NSString *pattern=  @"([-\\d]+),([-\\d]+),([-\\d]+),([-\\d]+),([-\\d]+),([-\\d]+)";
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    NSTextCheckingResult *match = [regex firstMatchInString:serverResponse options:0 range:NSMakeRange(0, [serverResponse length])];
    
    self.dataIPAddress = [NSString stringWithFormat:@"%@.%@.%@.%@",
                          [serverResponse substringWithRange:[match rangeAtIndex:1]],
                          [serverResponse substringWithRange:[match rangeAtIndex:2]],
                          [serverResponse substringWithRange:[match rangeAtIndex:3]],
                          [serverResponse substringWithRange:[match rangeAtIndex:4]]];
    self.dataPort = ([[serverResponse substringWithRange:[match rangeAtIndex:5]] intValue] * 256) + [[serverResponse substringWithRange:[match rangeAtIndex:6]] intValue];
    
    NSLog(@"%@:%d", self.dataIPAddress, self.dataPort);
    self.isDataStreamConfigured = YES;
    [self openFTPDataCommnunication];
}

-(void )sendCommand:(NSString *)cmd{
    if (self.isConnected) {
        
        if (self.outputStream) {
            self.lastCommandSent = cmd;
            NSString *cmdToSend = [NSString stringWithFormat:@"%@\n", cmd];
            NSData *data = [[NSData alloc] initWithData:[cmdToSend dataUsingEncoding:NSASCIIStringEncoding]];
            numberOfBytesSent += [data length];
            [self.outputStream write:[data bytes] maxLength:[data length]];
        }else{
            NSLog(@"输出流不存在，无法发送指令");
        }
        
    }
}

#pragma mark - FTPCommand

-(void )sendUserName{
    NSLog(@"发送命令：用户名%@", @"guest");
    [self sendCommand:[NSString stringWithFormat:@"USER %@", self.FTPUserName]];
}

-(void )sendUserPassword{
    NSLog(@"发送命令：密码%@", @"123456");
    [self sendCommand:[NSString stringWithFormat:@"PASS %@", self.FTPUserPassword]];
}

-(void )sendCmdList{
    NSLog(@"发送命令：LIST");
    [self sendCommand:@"LIST"];
}



@end
