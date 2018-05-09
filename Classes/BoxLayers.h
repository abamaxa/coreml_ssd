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

#import "Prediction.h"

@interface BoxLayers : NSObject {

}

- (id)initWithView:(VIEW *)view;
- (void) clear;
- (void) draw;
#ifdef __cplusplus
- (void) add:(const Prediction *)prediction;
#endif

@end

#endif /* BoxLayers_h */
