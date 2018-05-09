//  Created by Chris Morgan on 26/4/18.
//  Copyright © 2018 Chris Morgan. All rights reserved.

#ifndef prediction_h
#define prediction_h

#ifdef __cplusplus

#import "CoreGraphics/CoreGraphics.h"
#import <vector>
#import <string>

class Prediction {
public:
    Prediction();
    Prediction(uint box_id, uint class_id, float score, double ty, double tx, double th, double tw);

    CGRect get_scaled_box(CGSize destination) const;
    const char* get_class() const;
    float get_score() const;
    double get_width() const;
    double get_height() const;

    std::string to_string() const;

    bool operator < (const Prediction& test) const;

    bool IOUGreaterThanThreshold(const Prediction& test, float iou_threshold) const;
private:
    float ymin;
    float xmin;
    float ymax;
    float xmax;
    float score;
    int class_id;
};

typedef std::vector<Prediction> PredictionList;

#endif /* __cplusplus */
#endif /* prediction_h */
