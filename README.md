## GDDownloaderManager
这是一个非常实用的下载管理器，可以完成下载进度跟进，界面显示进度以及断点续传功能！

## 如何使用？
* 将`Downloader文件夹`下面的所有文件夹添加到你的项目中
* 导入主头文件：`GDDownloaderManager.h`

## 开始下载
```objc
- (IBAction)download:(id)sender {
```
### 1、提供需要下载的url  
```objc
self.fullurl = [NSURL URLWithString:@"http://free2.macx.cn:8182/Tools/System/BetterZip234.dmg"];
```
### 2、利用主方法进行下载 
```objc
[[GDDownloaderManager sharedDownloaderManager] downloadWithURL:self.fullurl progress:^(float progress) {
```
#### 进度 
```objc
self.progressBtn.progress = progress;  
} completion:^(NSString *filePath) {
```
#### 下载完成回调 
```objc
} failed:^(NSString *errorMessage) {
```
#### 下载失败 
```objc
NSLog(@"下载失败"); 
  }];  
}
```

## 暂停下载
```objc
- (IBAction)stop:(id)sender {
    [[GDDownloaderManager sharedDownloaderManager]pauseWithURL:self.fullurl];
}
```
