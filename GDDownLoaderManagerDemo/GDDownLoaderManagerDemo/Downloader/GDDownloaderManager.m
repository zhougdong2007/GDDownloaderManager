//
//  GDDownloaderManager.m
//  01-下载管理器
//
//  Created by apple on 15/1/20.
//  Copyright (c) 2015年 zhouguodong. All rights reserved.
//

#import "GDDownloaderManager.h"
#import "GDDownloader.h"

@interface GDDownloaderManager()
/** 下载操作缓冲池 */
@property (nonatomic, strong) NSMutableDictionary *downloaderCache;

/** 失败的回调属性 */
@property (nonatomic, copy) void (^failedBlock) (NSString *);
@end

@implementation GDDownloaderManager
/**
 每实例化一个 GDDownloader 对应一个文件的下载操作！
 
 如果该操作没有执行完成，不需要再次开启！
 
 解决思路：下载操作缓冲池
 */
+ (instancetype)sharedDownloaderManager {
    static id instance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (NSMutableDictionary *)downloaderCache {
    if (_downloaderCache == nil) {
        _downloaderCache = [[NSMutableDictionary alloc] init];
    }
    return _downloaderCache;
}

- (void)downloadWithURL:(NSURL *)url progress:(void (^)(float))progress completion:(void (^)(NSString *))completion failed:(void (^)(NSString *))failed {

    // 0. 记录失败的回调代码
    self.failedBlock = failed;
    
    // 1. 判断缓冲池中是否存在下载操作
    GDDownloader *downloader = self.downloaderCache[url.path];
    if (downloader != nil) {
        if (failed) {
            failed(@"下载操作已经存在，正在玩命下载中....");
        }
        return;
    }
    
    // 2. 新建下载，缓冲池中没有下载操作
    downloader = [[GDDownloader alloc] init];
    
    // 3. 将下载操作添加到缓冲池
    [self.downloaderCache setObject:downloader forKey:url.path];
    
    // 传递 block 的参数
    /**
     下载完成之后清除下载操作
     
     问题：下载完成是异步的回调
     */
    [downloader downloadWithURL:url progress:progress completion:^(NSString *filePath) {
        // 1. 从下载缓冲池中删除下载操作
        [self.downloaderCache removeObjectForKey:url.path];
        
        // 2. 判断调用方是否传递了 completion，如果传递了直接执行
        if (completion) {
            completion(filePath);
        }
    } failed:failed];
}

- (void)pauseWithURL:(NSURL *)url {
    // 1. 从缓冲池中取出下载操作
    GDDownloader *download = self.downloaderCache[url.path];
    
    // 1.1 判断操作是否存在，如果不存在，提示用户
    if (download == nil) {
        if (self.failedBlock) {
            self.failedBlock(@"操作不存在，无需暂停");
        }
        return;
    }
    
    // 2. 暂停
    [download pause];
    
    // 3. 从缓冲池中删除操作
    [self.downloaderCache removeObjectForKey:url.path];
}

@end
