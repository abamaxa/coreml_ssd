//
//  Predictions.m
//  CoreMLSSD
//
//  Created by Chris Morgan on 20/12/2018.
//  Copyright © 2018 Chris Morgan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Predictions.h"
#import "Anchors.h"

@interface Predictions () {
}
@end

@implementation Predictions {
}

- (id)initWithPoints:(uint)box_id
             class_id:(uint) class_id
               score:(float) score
                  ty:(double) ty
                  tx:(double) tx
                  th:(double) th
                  tw:(double) tw
{
    self = [super init];
    if (self) {
        self.class_id = class_id;
        self.score = score;
        
        // From https://github.com/tensorflow/models/blob/master/research/object_detection/box_coders/keypoint_box_coder.py#L128
        const Anchor anchor = Anchor::get_center_coordinates_and_sizes(box_id);
        const double _scale_factors[] = { 10.0, 10.0, 5.0, 5.0 };
        
        ty /= _scale_factors[0];
        tx /= _scale_factors[1];
        th /= _scale_factors[2];
        tw /= _scale_factors[3];
        
        double w = exp(tw) * anchor.wa;
        double h = exp(th) * anchor.ha;
        double ycenter = ty * anchor.ha + anchor.ycenter_a;
        double xcenter = tx * anchor.wa + anchor.xcenter_a;
        
        self.ymin = ycenter - h / 2.;
        self.xmin = xcenter - w / 2.;
        self.ymax = ycenter + h / 2.;
        self.xmax = xcenter + w / 2.;
    }
    return self;
}


- (CGRect) get_scaled_box:(CGSize) destination {
    CGPoint origin;
    
    float y_offset = 0;
    float y_scale = destination.height;
    
    CGSize size;
    size.width = [self get_width] * destination.width;
    size.height = [self get_height] * y_scale;
    
    origin.x = (self.xmin * destination.width);
#if TARGET_OS_IPHONE
    origin.y = y_offset + (self.ymin * y_scale);
#else
    // OSX is upside down!
    origin.y = y_scale - (y_offset + (self.ymax * y_scale));
#endif
    
    CGRect rect;
    rect.origin = origin;
    rect.size = size;
    
    return rect;
}

- (float) get_score {
    return self.score;
}

- (double) get_width {
    return self.xmax - self.xmin;
}

- (double) get_height {
    return self.ymax - self.ymin;
}

- (BOOL) IOUGreaterThanThreshold:(Predictions*) test  iou_threshold:(float) iou_threshold {
    double areaA = [self get_height] * [self get_width];
    double areaB = [test get_height] * [test get_width];
    
    if (areaA <= 0.0 || areaB <= 0.0)
        return false;
    
    double intersectionMinx = fmax(self.xmin, test.xmin);
    double intersectionMiny = fmax(self.ymin, test.ymin);
    double intersectionMaxx = fmin(self.xmax, test.xmax);
    double intersectionMaxy = fmin(self.ymax, test.ymax);
    
    double intersectionArea = fmax(intersectionMaxy - intersectionMiny, 0.0);
    intersectionArea *= fmax(intersectionMaxx - intersectionMinx, 0.0);
    
    double iou = (intersectionArea / (areaA + areaB - intersectionArea));
    
    return (iou > iou_threshold);
}

@end

