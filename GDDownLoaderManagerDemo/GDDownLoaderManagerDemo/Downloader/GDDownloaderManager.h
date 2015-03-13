//
//  GDDownloaderManager.h
//  01-下载管理器
//
//  Created by apple on 15/1/20.
//  Copyright (c) 2015年 zhouguodong. All rights reserved.
//
//  负责管理所有的下载任务 － 单例
//

#import <Foundation/Foundation.h>

@interface GDDownloaderManager : NSObject

+ (instancetype)sharedDownloaderManager;

/**
 *  下载指定的 URL
 *
 *  block － 可以当作参数传递
 */
- (void)downloadWithURL:(NSURL *)url progress:(void (^)(float progress))progress completion:(void (^)(NSString *filePath))completion failed:(void (^)(NSString *errorMessage))failed;

/**
 *  暂停下载
 */
- (void)pauseWithURL:(NSURL *)url;

@end
