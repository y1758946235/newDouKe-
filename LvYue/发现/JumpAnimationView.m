//
//  JumpAnimationView.m
//  LvYue
//
//  Created by Olive on 15/12/30.
//  Copyright © 2015年 OLFT. All rights reserved.
//

#import "JumpAnimationView.h"

@interface JumpAnimationView ()

@property (strong, nonatomic) CADisplayLink *displayLink;
@property (nonatomic) CGFloat from;
@property (nonatomic) CGFloat to;
@property (nonatomic) BOOL animating;

@end

@implementation JumpAnimationView

- (void)startAnimationFrom:(CGFloat)from to:(CGFloat)to {
    self.from = from;
    self.to = to;
    self.animating = YES;
    if (self.displayLink == nil) {
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
}

- (void)completeAnimation {
    self.animating = NO;
    [self.displayLink invalidate];
    self.displayLink = nil;
}


- (void)tick:(CADisplayLink *)displayLink {
    [self setNeedsDisplay];
}


- (void)drawRect:(CGRect)rect {
    
    CALayer *layer =self.layer.presentationLayer;
    
    CGFloat progress = 1;
    if (!self.animating) {
        progress = 1;
    } else {
        progress = 1 - (layer.position.y - self.to) / (self.from - self.to);
    }
    
    CGFloat height = CGRectGetHeight(rect);
    CGFloat deltaHeight = height / 2 * (0.5 - fabs(progress - 0.5));
    
    CGPoint topLeft = CGPointMake(0, deltaHeight);
    CGPoint topRight = CGPointMake(CGRectGetWidth(rect), deltaHeight);
    CGPoint bottomLeft = CGPointMake(0, height);
    CGPoint bottomRight = CGPointMake(CGRectGetWidth(rect), height);
    
    UIBezierPath* path = [UIBezierPath bezierPath];
    [[UIColor clearColor] setFill];
    [path moveToPoint:topLeft];
    [path addQuadCurveToPoint:topRight controlPoint:CGPointMake(CGRectGetMidX(rect), 0)];
    [path addLineToPoint:bottomRight];
    [path addQuadCurveToPoint:bottomLeft controlPoint:CGPointMake(CGRectGetMidX(rect), height - deltaHeight)];
    [path closePath];
    [path fill];
}


@end
