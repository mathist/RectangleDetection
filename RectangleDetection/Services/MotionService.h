//
//  MotionService.h
//  RectangleDetection
//
//  Created by Todd Mathison on 6/12/19.
//  Copyright © 2019 Todd Mathison. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MotionServiceDelegate;



@interface MotionService : NSObject

@property (nonatomic, class, readonly) MotionService *shared;

@property(nonatomic, weak) id<MotionServiceDelegate> delegate;

-(void)stop;
-(void)start;

@end



@protocol MotionServiceDelegate <NSObject>

-(void)currentPitch:(double)pitch currentRoll:(double)roll currentYaw:(double)yaw;

@end


NS_ASSUME_NONNULL_END
