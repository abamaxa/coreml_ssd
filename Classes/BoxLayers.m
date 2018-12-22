//  Created by Chris Morgan on 26/4/18.
//  Copyright © 2018 Chris Morgan. All rights reserved.
#import "BoxLayers.h"
#if !TARGET_OS_IPHONE
#import "NSBezierPath+QuartzPath.h"
#endif

@interface BoxLayers () {
}

@property (nonatomic, strong) BEZIERPATH* path;
@property (nonatomic, strong) CAShapeLayer *shape_layer;
@property (nonatomic, assign) VIEW* view;
@property (nonatomic, strong) NSMutableArray *text;
@property (nonatomic) int currentTextLayer;
@end

#define MAX_TEXT_LABEL 10

@implementation BoxLayers {
}

- (id)initWithView:(VIEW *)view {
    self.view = view;

    [self ensure_view_has_layer];
    
    self.currentTextLayer = 0;
    self.text = [[NSMutableArray alloc] init];

    self.shape_layer = [[CAShapeLayer alloc] init];
    self.shape_layer.fillColor = [[COLOR clearColor] CGColor];
    self.shape_layer.strokeColor = [[COLOR redColor] CGColor];
    self.shape_layer.lineWidth = 1;
    self.shape_layer.zPosition = 1;

    [self.view.layer addSublayer:self.shape_layer];
    
    for (int i = 0;i < MAX_TEXT_LABEL;i++) {
        CATextLayer *text_layer = text_layer = [[CATextLayer alloc] init];
        text_layer.fontSize = 14;
        text_layer.font = (__bridge CFTypeRef _Nullable)([UIFont systemFontOfSize:text_layer.fontSize]);
        text_layer.alignmentMode = kCAAlignmentCenter;
        text_layer.zPosition = 1;
        text_layer.hidden = YES;
        text_layer.contentsScale = UIScreen.mainScreen.scale;
        
        [self.view.layer addSublayer:text_layer];
        [self.text addObject:text_layer];
    }

    return self;
}

- (void) clear {
    self.shape_layer.path = nil;
    self.path = nil;
    [self show:NO];
    self.currentTextLayer = 0;
}

- (void) add:(CGRect)frame {
    if (self.path == nil) {
        self.path = [[BEZIERPATH alloc] init];
    }

    [self append_to_path:frame];
}

- (void) addWithLabel:(CGRect)frame label:(NSString*)label {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    if (self.path == nil) {
        self.path = [[BEZIERPATH alloc] init];
    }
    
    [self append_to_path:frame];
    
    if (self.currentTextLayer < self.text.count) {
        CATextLayer* text_layer = [self.text objectAtIndex:self.currentTextLayer];
        self.currentTextLayer++;
    
        text_layer.string = label;
        text_layer.frame = frame;
    }
    
    [CATransaction commit];
}


- (void) add_bezier_path:(BEZIERPATH*)new_path {
    if (self.path == nil) {
        self.path = [[BEZIERPATH alloc] init];
    }
    
    [self append_bezier_path:new_path];
}

- (void) draw:(CGColorRef) color {
    [self add_path_to_shape_layer];
    self.shape_layer.strokeColor = color;
    self.shape_layer.hidden = NO;

    for (CATextLayer* layer in self.text) {
        layer.foregroundColor = color;
        layer.hidden = NO;
    }
}

- (void) show:(BOOL)visible {
    self.shape_layer.hidden = !visible;
    for (CATextLayer* layer in self.text) {
        layer.hidden = !visible;
        layer.string = @"";
    }
}

-(void) ensure_view_has_layer {
#if !TARGET_OS_IPHONE
    if (self.view.layer == nil) {
        self.view.wantsLayer = YES;
        self.view.layer = [[CALayer alloc] init];
    }
#endif
}

-(void) append_to_path:(CGRect)frame {
    BEZIERPATH* new_path = [BEZIERPATH bezierPathWithRect:frame];
    [self append_bezier_path:new_path];
}

-(void) append_bezier_path:(BEZIERPATH*)new_path {
#if TARGET_OS_IPHONE
    [self.path appendPath:new_path];
#else
    [self.path appendBezierPath:new_path];
#endif
}

-(void) add_path_to_shape_layer {
#if TARGET_OS_IPHONE
    self.shape_layer.path = self.path.CGPath;
#else
    self.shape_layer.path = [self.path quartzPath];
#endif
}

@end
