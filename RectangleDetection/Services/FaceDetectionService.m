//
//  FaceDetectionService.m
//  RectangleDetection
//
//  Created by Todd Mathison on 6/24/19.
//  Copyright © 2019 Todd Mathison. All rights reserved.
//

#import "FaceDetectionService.h"

@implementation FaceDetectionService

- (instancetype)init
{
    if (!(self = [super init])) return nil;
    
    return self;
}

-(void)dealloc
{
    NSLog(@"%@", @"FaceDetectionService Dealloc");
}

-(void)request:(CMSampleBufferRef)sampleBuffer;
{
    CVImageBufferRef buffer = CMSampleBufferGetImageBuffer(sampleBuffer);

    VNDetectFaceRectanglesRequest *request = [[VNDetectFaceRectanglesRequest alloc] initWithCompletionHandler:^(VNRequest * _Nonnull request , NSError * _Nullable error)
    {
        if (error)
        {
            NSLog(@"%@", error.localizedDescription);
            return;
        }

        if(request.results && request.results.count > 0 && self.delegate && [self.delegate respondsToSelector:@selector(facesFound:)])
            [self.delegate facesFound:request.results];
    }];
  
    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCVPixelBuffer:buffer orientation:kCGImagePropertyOrientationRight options:@{}];
    
    NSError *error;
    [handler performRequests:@[request] error:&error];
    
    if (error)
    {
        NSLog(@"%@", error.localizedDescription);
    }
}

-(CGPoint)convertToUIView:(CGPoint)point forSize:(CGSize)size
{
    CGPoint newPoint = CGPointApplyAffineTransform(point, CGAffineTransformMakeScale(size.width, size.height));
    newPoint = CGPointApplyAffineTransform(newPoint, CGAffineTransformMakeTranslation(0, -size.height));
    newPoint = CGPointApplyAffineTransform(newPoint, CGAffineTransformMakeScale(1, -1));
    
    return newPoint;
}
@end
