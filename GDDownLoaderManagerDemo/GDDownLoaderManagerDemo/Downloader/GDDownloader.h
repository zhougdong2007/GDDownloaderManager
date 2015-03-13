//
//  GDDownloader.h
//  01-下载管理器
//
//  Created by apple on 15/1/20.
//  Copyright (c) 2015年 zhouguodong. All rights reserved.
//
//  下载任务管理器 - 下载一个文件
//

#import <Foundation/Foundation.h>

@interface GDDownloader : NSObject

/**
 *  下载指定 url 的文件
 *
 *  需要扩展：通知调用方下载的相关信息
 *
 *  1. 进度，通知下载的百分比
 *  2. 是否完成，通知下载保存的路径
 *  3. 错误，通知错误信息
 *
 *  代理通知 / block 
 *  1. “调用方”预先准备好的代码，在需要的时候执行
 *  2. 是一个特殊的数据类型，可以当作参数被传递 
 *
 *  @param url 要下载文件的 url
 *
 *  补充，在很多第三方框架中，有一个共同的特点（SDWebImage/AFN/ASI）
 *  进度的回调，是在异步线程回调的 
        - 通常很多网络下载操作，并不会下载太大的文件，很多开发人员不会监听进度！
        - 进度回调会很多次，如果在主线程回调，会影响主线程UI的交互
 *  完成的回调，是在主线程回调的 - 通常调用方不需要关心线程间通讯，一旦完成直接更新UI更方便
 */
- (void)downloadWithURL:(NSURL *)url progress:(void (^)(float progress))progress completion:(void (^)(NSString *filePath))completion failed:(void (^)(NSString *errorMessage))failed;

/** 暂停当前的下载操作 */
- (void)pause;

@end
