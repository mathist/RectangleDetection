//
//  CaptureVideoService.h
//  RectangleDetection
//
//  Created by Todd Mathison on 6/19/19.
//  Copyright © 2019 Todd Mathison. All rights reserved.
//

#import "VideoService.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CaptureVideoServiceDelegate;

@interface CaptureVideoService : VideoService

@property(nonatomic, weak) id<CaptureVideoServiceDelegate> delegate;

@end

@protocol CaptureVideoServiceDelegate <NSObject>

-(void)captureVideoServiceSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end



NS_ASSUME_NONNULL_END