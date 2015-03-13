//
//  GDProgressButton.h
//  09-URLSession下载
//
//  Created by apple on 15/1/19.
//  Copyright (c) 2015年 zhouguodong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GDProgressButton : UIButton
/** 进度 0.0~1.0 */
@property (nonatomic, assign) float progress;
/** 线宽 */
@property (nonatomic, assign) float lineWidth;
@end
