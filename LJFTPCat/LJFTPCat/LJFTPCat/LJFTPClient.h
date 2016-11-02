//
//  LJFTPClient.h
//  LJFTPClientDemo
//
//  Created by 刘瑾 on 2016/11/1.
//  Copyright © 2016年 刘瑾. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LJFTPClient : NSObject

-(instancetype )initFTPClientWithUserName:(NSString *)userName andUserPassword:(NSString *)userPassword;
-(void )connectFTPServer;
-(void )disconnectFTPServer;
-(void )sendCommandAboutData:(NSString *)cmd;

@end
