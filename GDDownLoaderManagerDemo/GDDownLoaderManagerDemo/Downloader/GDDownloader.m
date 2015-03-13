//
//  GDDownloader.m
//  01-下载管理器
//
//  Created by apple on 15/1/20.
//  Copyright (c) 2015年 zhouguodong. All rights reserved.
//

#import "GDDownloader.h"

// 网络访问超时时长
#define kTimeOut    20.0

/**
 NSURLSession 的下载
 
 1. 跟踪进度
 2. 断点续传，问题：基于resumeData，一旦resumeData丢失，再次下载的时候，无法续传！
    考虑解决思路：
    - 将文件保存在固定的位置
    - 再次下载文件前，首先检查固定位置是否存在文件
    - 如果存在，就直接续传！这样就不再需要依赖 resumeData
 */

@interface GDDownloader() <NSURLConnectionDataDelegate>

/** 下载文件的 URL */
@property (nonatomic, strong) NSURL *downloadURL;
/** 下载的连接 */
@property (nonatomic, strong) NSURLConnection *downloadConnection;

/** 文件总大小 */
@property (nonatomic, assign) long long expectedContentLength;
/** 本地文件当前大小 */
@property (nonatomic, assign) long long currentLength;

/** 文件保存在本地的路径 */
@property (nonatomic, copy) NSString *filePath;

/** 文件输出流 */
@property (nonatomic, strong) NSOutputStream *fileStrem;

/** 下载的运行循环 */
@property (nonatomic, assign) CFRunLoopRef downloadRunloop;

// --- 定义 block 属性 ---
@property (nonatomic, copy) void (^progressBlock)(float);
@property (nonatomic, copy) void (^completionBlock)(NSString *);
@property (nonatomic, copy) void (^failedBlock)(NSString *);

@end

@implementation GDDownloader

// block 定义对比
//void hello(float progress) {
//    
//}

// 提示：download方法是主方法，供外部调用
// 技巧：不要在主方法中写碎代码
/**
 block 可以在需要的时候执行
 
 技巧：
 1. 如果本方法中，可以直接执行，就不用定义属性记录block
 2. 如果本方法中，不能直接执行，就需要定义属性记录block，然后在需要的时候执行
 */
- (void)downloadWithURL:(NSURL *)url progress:(void (^)(float))progress completion:(void (^)(NSString *))completion failed:(void (^)(NSString *))failed {
    // 0. 保存属性
    self.downloadURL = url;
    self.progressBlock = progress;
    self.completionBlock = completion;
    self.failedBlock = failed;
    
    // 1. 检查服务器上的文件大小
    [self serverFileInfoWithURL:url];
    
    NSLog(@"%lld %@", self.expectedContentLength, self.filePath);
    
    // 2. 检查本地文件大小
    if (![self checkLocalFileInfo]) {
        // 如果下载已经完成，直接通过block回调，并且传回filePath，供调用方使用！
        if (completion) {
            completion(self.filePath);
        }
        return;
    };
    
    // 3. 如果需要，从服务器开始续传下载文件
    NSLog(@"需要下载文件，从 %lld", self.currentLength);
    [self downloadFile];
}

- (void)pause {
    // 取消当前的连接
    [self.downloadConnection cancel];
}

#pragma mark - 下载文件
// 从 self.currentLength 开始下载文件
- (void)downloadFile {
    
    // 将connection放在异步执行，运行循环(手动开启)&代理工作的线程会统一都在异步开启
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // 1. 建立请求
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.downloadURL cachePolicy:1 timeoutInterval:kTimeOut];
        // 设置下载的字节范围，从 self.cuurentLength 开始之后的所有字节
        NSString *rangeStr = [NSString stringWithFormat:@"bytes=%lld-", self.currentLength];
        // 设置请求头字段
        [request setValue:rangeStr forHTTPHeaderField:@"Range"];
        
        // 2. 开始网络连接
        self.downloadConnection = [NSURLConnection connectionWithRequest:request delegate:self];
        
        // 3. 启动网络连接
        [self.downloadConnection start];
        
        // 4. 利用运行循环实现多线程
        self.downloadRunloop = CFRunLoopGetCurrent();
        CFRunLoopRun();
    });
}

#pragma mark - NSURLConnectionDataDelegate
// 1. 接收到响应，做准备工作
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // 打开输出流
    self.fileStrem = [[NSOutputStream alloc] initToFileAtPath:self.filePath append:YES];
    [self.fileStrem open];
}

// 2. 接收到数据，用输出流拼接，计算下载进度
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // 追加数据
    [self.fileStrem write:data.bytes maxLength:data.length];
    
    // 记录文件长度以及下载进度
    self.currentLength += data.length;
    
    float progress = (float)self.currentLength / self.expectedContentLength;
    // 判断block是否定义
    if (self.progressBlock) {
        self.progressBlock(progress);
    }
}

// 3. 所有下载完成
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // 关闭流
    [self.fileStrem close];
    
    // 停止运行循环
    CFRunLoopStop(self.downloadRunloop);
    
    // 判断block是否定义
    if (self.completionBlock) {
        // 主线程回调
        dispatch_async(dispatch_get_main_queue(), ^ {self.completionBlock(self.filePath);});
    }
}

// 4. 出错
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // 关闭流
    [self.fileStrem close];
    
    // 停止运行循环
    CFRunLoopStop(self.downloadRunloop);
    
    NSLog(@"%@", error.localizedDescription);
    
    // 几乎第三方框架的错误回调都是异步的！能够保证做一些特殊操作，不会影响到主线程
    if (self.failedBlock) {
        self.failedBlock(error.localizedDescription);
    }
}

#pragma mark - 私有方法
/**
 检查本地文件信息 -> 判断是否需要下载！
 
 目标：检查文件是否存在，如果存在计算当前的大小
 
 返回 YES，需要下载，NO，不需要下载
 */
- (BOOL)checkLocalFileInfo {
    
    // 1. 文件是否存在
    long long fileSize = 0;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.filePath]) {
        // 2. 获取文件大小
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.filePath error:NULL];
        
        // 利用字典的 key 直接获取文件大小
//        fileSize = [attributes[NSFileSize] longLongValue];
        // 利用分类方法获取文件大小
        fileSize = [attributes fileSize];
    }
    
    // 2. 检查文件信息是否正确
    /**
     如果小于服务器上的大小，从本地文件的长度，开始下载，能够实现续传
     如果等于服务器上的大小，认为文件已经下载完毕，就不再下载！
     如果大于服务器上的大小，直接删除，重新下载
     */
    // 是否大于服务器上的文件
    if (fileSize > self.expectedContentLength) {
        // 删除文件
        [[NSFileManager defaultManager] removeItemAtPath:self.filePath error:NULL];
        fileSize = 0;
    }
    
    // 3. 判断是否和服务器的文件一样大
    self.currentLength = fileSize;
    if (fileSize == self.expectedContentLength) {
        return NO;
    }
    return YES;
}

// 检查服务器文件大小
- (void)serverFileInfoWithURL:(NSURL *)url {
    
    // 1. 请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:1 timeoutInterval:kTimeOut];
    // HEAD 方法，专门用来获取远程服务器上的文件信息
    // 使用了 HEAD 方法，就不会获取文件的完整数据！
    request.HTTPMethod = @"HEAD";
    
    // 2. 建立网络连接，发送同步方法！
    NSURLResponse *response = nil;
    
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:NULL];
    
    // 3. 记录服务器文件信息
    // 3.1 文件长度
    self.expectedContentLength = response.expectedContentLength;
    
    // 3.2 建议保存的文件名，将下载的文件保存在 tmp 目录中，系统会自动回收
    self.filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:response.suggestedFilename];
    
    return;
}

@end
