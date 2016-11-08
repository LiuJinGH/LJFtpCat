//
//  LJFTPClient.h
//  LJFTPClientDemo
//
//  Created by 刘瑾 on 2016/11/1.
//  Copyright © 2016年 刘瑾. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class LJFTPClient;

typedef enum : NSUInteger {
    FTPClientErrorNoConnection,
    FTPClientErrorLoginFailure,
    FTPClientErrorDataPassagewayFailure,
} FTPClientErrorOption;

@protocol LJFTPClientDelegate <NSObject>

-(void )FTPClient:(LJFTPClient *) ftpClient occurErrorWithType:(FTPClientErrorOption)ftpErrorType;



@end

@protocol LJFTPClientDataSource <NSObject>

//-(void )FTPClient:(LJFTPClient *) ftpClient 

@end

@interface LJFTPClient : NSObject

-(instancetype )initFTPClientWithUserName:(NSString *)userName andUserPassword:(NSString *)userPassword;
-(void )connectFTPServer;
-(void )disconnectFTPServer;

@end
