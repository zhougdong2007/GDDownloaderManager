//
//  GDProgressButton.m
//  09-URLSession下载
//
//  Created by apple on 15/1/19.
//  Copyright (c) 2015年 zhouguodong. All rights reserved.
//

#import "GDProgressButton.h"

@implementation GDProgressButton

- (void)setProgress:(float)progress {
    _progress = progress;
    
    // 设置标题
    [self setTitle:[NSString stringWithFormat:@"%.02f%%", _progress * 100] forState:UIControlStateNormal];
    
    // 刷新视图
    [self setNeedsDisplay];
}

/** 使用 Storyboard & XIB 设置初始属性的方法 */
- (void)awakeFromNib {
    self.lineWidth = 4.0;
}

// rect = self.bounds
- (void)drawRect:(CGRect)rect {

    CGSize s = rect.size;
    CGPoint center = CGPointMake(s.width * 0.5, s.height * 0.5);
    CGFloat r = (s.height > s.width) ? s.width * 0.5 : s.height * 0.5;
    r -= self.lineWidth * 0.5;
    
    CGFloat startAng = - M_PI_2;
    CGFloat endAng = self.progress * 2 * M_PI + startAng;
    
    /**
     1. 圆心
     2. 半径
     3. 起始弧度
     4. 结束弧度
     5. 顺时针
     */
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:r startAngle:startAng endAngle:endAng clockwise:YES];
    
    // 设置线宽
    path.lineWidth = self.lineWidth;
    path.lineCapStyle = kCGLineCapRound;
    
    // 设置颜色
    [[UIColor blueColor] setStroke];
    
    // 绘制路径
    [path stroke];
}

@end
