//
//  FTPCatFileModel.h
//  LJFTPCat
//
//  Created by 刘瑾 on 2016/11/3.
//  Copyright © 2016年 刘瑾. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    LJFTPCatFileTypeFolders,
    LJFTPCatFileTypeImage,
    LJFTPCatFileTypeMusic,
    LJFTPCatFileTypeVideo,
    LJFTPCatFileTypeDocument,
    LJFTPCatFileTypeUndefined,
} LJFTPCatFileType;

typedef enum : NSUInteger {
    LJFTPCatFileSizeTypeWithKB,
    LJFTPCatFileSizeTypeWithMB,
    LJFTPCatFileSizeTypeWithGB,
} LJFTPCatFileSizeType;

@interface FTPCatFileModel : NSObject

@property (nonatomic) NSString *fileName;
@property (nonatomic) LJFTPCatFileType *fileType;
@property (nonatomic, assign) float fileSize;
@property (nonatomic) LJFTPCatFileSizeType sizeType;
@property (nonatomic) NSDate *fileDate;

+(instancetype )createFileFromString:(NSString *)fileDescribe;

@end
