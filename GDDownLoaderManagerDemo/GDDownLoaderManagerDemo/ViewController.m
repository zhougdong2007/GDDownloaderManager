//
//  ViewController.m
//  GDDownLoaderManagerDemo
//
//  Created by zhouguodong on 15/3/13.
//  Copyright (c) 2015年 zhouguodong. All rights reserved.
//

#import "ViewController.h"

// 1、导入头文件
#import "GDDownloaderManager.h"
#import "GDProgressButton.h"

@interface ViewController ()

// 2、创建下载管理器属性
@property GDDownloaderManager *downloadmager;
@property NSURL *fullurl;

// 3、创建进度跟进视图按钮
@property (weak, nonatomic) IBOutlet GDProgressButton *progressBtn;

// 4、创建下载和暂停按钮
- (IBAction)download:(id)sender;
- (IBAction)stop:(id)sender;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

// 开始下载
- (IBAction)download:(id)sender {
    // 1、提供需要下载的url
    self.fullurl = [NSURL URLWithString:@"http://free2.macx.cn:8182/Tools/System/BetterZip234.dmg"];
    
    // 2、利用主方法进行下载
    [[GDDownloaderManager sharedDownloaderManager] downloadWithURL:self.fullurl progress:^(float progress) {
        // 进度
        self.progressBtn.progress = progress;
    } completion:^(NSString *filePath) {
        // 下载完成
        NSLog(@"完成下载");
    } failed:^(NSString *errorMessage) {
        // 下载失败
        NSLog(@"下载失败");
    }];
}

// 暂停下载
- (IBAction)stop:(id)sender {
    // 利用单例暂停下载
    [[GDDownloaderManager sharedDownloaderManager]pauseWithURL:self.fullurl];
}

@end

