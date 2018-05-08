//  Created by Chris Morgan on 26/4/18.
//  Copyright © 2018 Chris Morgan. All rights reserved.
#import "BoxLayers.h"
#import "NSBezierPath+QuartzPath.h"

@interface BoxLayers () {
}

@property (nonatomic, strong) BEZIERPATH* path;
@property (nonatomic, strong) CATextLayer *text_layer;
@property (nonatomic, strong) CAShapeLayer *shape_layer;
@property (nonatomic, assign) VIEW* view;

@end

@implementation BoxLayers {
}


- (id)initWithView:(VIEW *)view {
    self.view = view;
    if (view.layer == nil) {
        view.wantsLayer = YES;
        view.layer = [[CALayer alloc] init];
    }
    
    self.shape_layer = [[CAShapeLayer alloc] init];
    self.shape_layer.fillColor = [[COLOR clearColor] CGColor];
    self.shape_layer.lineWidth = 4;
    self.shape_layer.zPosition = 1;
    
    self.text_layer = [[CATextLayer alloc] init];
    self.text_layer.fontSize = 16;
    self.text_layer.alignmentMode = kCAAlignmentCenter;
    self.text_layer.zPosition = 1;
    
    [self.view.layer addSublayer:self.shape_layer];
    [self.view.layer addSublayer:self.text_layer];
    
    return self;
}

- (void) clear {
    self.shape_layer.hidden = YES;
    self.shape_layer.path = nil;
    self.path = nil;
}

- (void) add:(const Prediction *)prediction {
    if (self.path == nil) {
        self.path = [[BEZIERPATH alloc] init];
    }
    
    CGSize destination = self.view.frame.size;
    CGRect frame = prediction->get_scaled_box(destination);
#if TARGET_OS_IPHONE
    [self.path appendPath:[BEZIERPATH bezierPathWithRect:frame]];
#else
    [self.path appendBezierPath:[BEZIERPATH bezierPathWithRect:frame]];
#endif
}

- (void) draw {
#if TARGET_OS_IPHONE
    self.shape_layer.path = self.path.CGPath;
#else
    self.shape_layer.path = [self.path quartzPath];
#endif
    self.shape_layer.strokeColor = [[COLOR redColor] CGColor];
    self.shape_layer.hidden = NO;
}

@end



