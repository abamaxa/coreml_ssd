//
//  BoxLayers.h
//  confital-ios
//
//  Created by Chris Morgan on 26/4/18.
//  Copyright © 2018 Chris Morgan. All rights reserved.
//

#ifndef BoxLayers_h
#define BoxLayers_h

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#define VIEW UIView
#define BEZIERPATH UIBezierPath
#define COLOR UIColor
#else
#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>
#define VIEW NSView
#define BEZIERPATH NSBezierPath
#define COLOR NSColor
#endif

@interface BoxLayers : NSObject {
}

- (id)initWithView:(VIEW *)view;
- (void) clear;
- (void) show:(BOOL)visible;
- (void) draw:(CGColorRef)color;
- (void) add:(CGRect)frame;
- (void) add_bezier_path:(BEZIERPATH*)new_path;
- (void) addWithLabel:(CGRect)frame label:(NSString*)label;

@end

#endif /* BoxLayers_h */
