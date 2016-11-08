//
//  FTPCatFileModel.m
//  LJFTPCat
//
//  Created by 刘瑾 on 2016/11/3.
//  Copyright © 2016年 刘瑾. All rights reserved.
//

#import "FTPCatFileModel.h"

@implementation FTPCatFileModel

+(instancetype)createFileFromString:(NSString *)fileDescribe{
    if (!fileDescribe) {
        return nil;
    }else{
//        NSLog(@"%@", fileDescribe);
        //移除字符串尾部的 \n
        fileDescribe = [fileDescribe stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        FTPCatFileModel *model = [FTPCatFileModel new];
        
        NSMutableArray <NSString *> *modelListData = [NSMutableArray arrayWithArray:[fileDescribe componentsSeparatedByString:@" "]];
        [modelListData removeObject:@""];
        [modelListData enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isEqualToString:@""]) {
                [modelListData removeObjectAtIndex:idx];
            }else{
//                NSLog(@"---%ld---%@---", idx, obj);
                
            }
        }];
        
        [model setupModelName:modelListData];
        [model setupModelFileType];
//        [model setupModelSize:modelListData[4]];
        return model;
    }
}

-(void )setupModelFileType{
    
    if (self.fileName) {
        NSString *typeStr = [self.fileName componentsSeparatedByString:@"."].lastObject;
        NSLog(@"%@", typeStr);
        
    }
    
    
}

-(void )setupModelName:(NSArray <NSString *> *)modeDatas{
    if (modeDatas.count > 9) {
        NSMutableString *fileName = [NSMutableString new];
        for (int i = 8; i < modeDatas.count; i++) {
            [fileName appendString:modeDatas[i]];
        }
        self.fileName = fileName;
    }else{
        self.fileName = modeDatas.lastObject;
    }
    NSLog(@"%@", self.fileName);
}

-(void )setupModelSize:(NSString *)modelSize{
    long size = [modelSize integerValue];
    if (size == 0) {
        return;
    }
    
    if (size / (1024 * 1024 * 1024)) {
        self.fileSize = size / (1024.0 * 1024 * 1024);
        self.sizeType = LJFTPCatFileSizeTypeWithGB;
        NSLog(@"%.2fGB", self.fileSize);
        return;
        
    }else if (size / (1024 * 1024)) {
        self.fileSize = size / (1024.0 * 1024);
        self.sizeType = LJFTPCatFileSizeTypeWithMB;
        NSLog(@"%.2fMB", self.fileSize);
        return ;
        
    }else if (size / 1024){
        self.fileSize = size / 1024.0;
        self.sizeType = LJFTPCatFileSizeTypeWithKB;
        NSLog(@"%.2fKB", self.fileSize);
        return;
    }
    
}

@end
