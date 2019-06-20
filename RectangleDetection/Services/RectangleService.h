//
//  RectangleService.h
//  RectangleDetection
//
//  Created by Todd Mathison on 6/12/19.
//  Copyright © 2019 Todd Mathison. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Vision/Vision.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol RectangleServiceDelegate;

@interface RectangleService : NSObject

@property(nonatomic, weak) id<RectangleServiceDelegate> delegate;
-(void)request:(CMSampleBufferRef)sampleBuffer;
-(CGPoint)convertToUIView:(CGPoint)point forSize:(CGSize)size;
@end


@protocol RectangleServiceDelegate <NSObject>

-(void)rectanglesFound:(NSArray <VNRectangleObservation *>*) rectangles;

@end

NS_ASSUME_NONNULL_END




