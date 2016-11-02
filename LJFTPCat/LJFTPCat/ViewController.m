//
//  ViewController.m
//  LJFTPCat
//
//  Created by 刘瑾 on 2016/11/2.
//  Copyright © 2016年 刘瑾. All rights reserved.
//

#import "ViewController.h"
#import "LJFTPCat/LJFTPCat.h"

@interface ViewController ()

@property (nonatomic) LJFTPClient *ftpCat;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.ftpCat connectFTPServer];
    [self.ftpCat sendCommandAboutData:@"LIST"];
}

-(LJFTPClient *)ftpCat{
    if (!_ftpCat) {
        _ftpCat = [[LJFTPClient alloc] initFTPClientWithUserName:@"guest" andUserPassword:@"123456"];
    }
    return _ftpCat;
}


@end
