//
//  Predictions.h
//  CoreMLSSD
//
//  Created by Chris Morgan on 20/12/2018.
//  Copyright © 2018 Chris Morgan. All rights reserved.
//

#ifndef Predictions_h
#define Predictions_h

@interface Predictions : NSObject {
    
}

- (id)initWithPoints:(uint)box_id class_id:(uint)class_id score:(float)score ty:(double)ty tx:(double)tx th:(double)th tw:(double)tw;
- (CGRect) get_scaled_box:(CGSize) destination;
- (float) get_score;
- (double) get_width;
- (double) get_height;
- (int) get_class_id;
- (BOOL) IOUGreaterThanThreshold:(Predictions*) test  iou_threshold:(float) iou_threshold;

@property (nonatomic) float ymin;
@property (nonatomic) float xmin;
@property (nonatomic) float ymax;
@property (nonatomic) float xmax;
@property (nonatomic) float score;
@property (nonatomic) int class_id;

@end

#endif /* Predictions_h */
