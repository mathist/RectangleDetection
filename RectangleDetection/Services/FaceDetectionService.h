//
//  FaceDetectionService.h
//  RectangleDetection
//
//  Created by Todd Mathison on 6/24/19.
//  Copyright © 2019 Todd Mathison. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Vision/Vision.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FaceDetectionServiceDelegate;

@interface FaceDetectionService : NSObject

@property(nonatomic, weak) id<FaceDetectionServiceDelegate> delegate;
-(void)request:(CMSampleBufferRef)sampleBuffer;
-(CGPoint)convertToUIView:(CGPoint)point forSize:(CGSize)size;
@end


@protocol FaceDetectionServiceDelegate <NSObject>

-(void)facesFound:(NSArray <VNFaceObservation *>*) faces;

@end


NS_ASSUME_NONNULL_END


