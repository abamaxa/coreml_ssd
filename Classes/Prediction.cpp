//
//  Prediction.cpp
//  confital-ios
//
//  Created by Chris Morgan on 26/4/18.
//  Copyright © 2018 Chris Morgan. All rights reserved.
//

#include "Prediction.h"
#include "Anchors.h"

#include <cmath>
#include <algorithm>
#include <sstream>

Prediction::Prediction() :
xmin(0.01), ymin(0.01), xmax(0.99), ymax(0.99)
{
    
}

Prediction::Prediction
(
    uint box_id,
    uint _class_id,
    float _score,
    double ty,
    double tx,
    double th,
    double tw
 ) :
    class_id(_class_id),
    score(_score)
{
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
    
    ymin = ycenter - h / 2.;
    xmin = xcenter - w / 2.;
    ymax = ycenter + h / 2.;
    xmax = xcenter + w / 2.;
}

CGRect Prediction::get_scaled_box(CGSize destination) const {
    CGPoint origin;
    
    //float y_offset = ((destination.height - destination.width) / 2);
    //float y_scale = destination.width;
    float y_offset = 0; //((destination.height - destination.width) / 2);
    float y_scale = destination.height;
    
    CGSize size;
    size.width = get_width() * destination.width;
    size.height = get_height() * y_scale;
    
    origin.x = (xmin * destination.width);
#if TARGET_OS_IPHONE
     origin.y = y_offset + (ymin * y_scale);
#else
    // OSX is upside down!
    //origin.y = y_scale - (y_offset + (ymin * y_scale)) - size.height;
    origin.y = y_scale - (y_offset + (ymax * y_scale));
#endif
    
    CGRect rect;
    rect.origin = origin;
    rect.size = size;
    
    return rect;
}

const char* Prediction::get_class() const {
    return "???";
}

float Prediction::get_score() const {
    return score;
}

double Prediction::get_width() const {
    return (xmax - xmin);
}

double Prediction::get_height() const {
    return (ymax - ymin);
}

std::string Prediction::to_string() const {
    std::ostringstream string_stream;
    string_stream << "{ \"ymin\":" << ymin << ", \"xmin\":" << xmin
                  << ", \"ymax\":" << ymax << ", \"xmax\":" << xmax << " }";
    
    return string_stream.str();
} 

bool Prediction::IOUGreaterThanThreshold
(
 const Prediction& test,
 float iou_threshold
) const
{
    double areaA = get_height() * get_width();
    double areaB = test.get_height() * test.get_width();
    
    if (areaA <= 0.0 || areaB <= 0.0)
        return false;
        
    double intersectionMinx = std::max(xmin, test.xmin);
    double intersectionMiny = std::max(ymin, test.ymin);
    double intersectionMaxx = std::min(xmax, test.xmax);
    double intersectionMaxy = std::min(ymax, test.ymax);
    
    double intersectionArea = std::max(intersectionMaxy - intersectionMiny, 0.0);
    intersectionArea *= std::max(intersectionMaxx - intersectionMinx, 0.0);
    
    double iou = (intersectionArea / (areaA + areaB - intersectionArea));
    
    return (iou > iou_threshold);
}

