//
//  MotionService.m
//  RectangleDetection
//
//  Created by Todd Mathison on 6/12/19.
//  Copyright © 2019 Todd Mathison. All rights reserved.
//

#import "MotionService.h"
#import <CoreMotion/CoreMotion.h>

@interface MotionService ()

@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, strong) NSOperationQueue *motionQueue;

@end

@implementation MotionService


+ (MotionService *)shared {
    static id retval;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        retval = [[MotionService alloc] init];
    });
    return retval;
}

- (instancetype)init
{
    if (!(self = [super init])) return nil;

    self.motionQueue = [[NSOperationQueue alloc] init];
    
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.deviceMotionUpdateInterval = 0.25;

    
    return self;
}

-(void)stop
{
    [self.motionManager stopDeviceMotionUpdates];
}

-(void)start
{
    if ([self.motionManager isDeviceMotionAvailable])
    {
        [self.motionManager startDeviceMotionUpdatesToQueue:self.motionQueue withHandler:^(CMDeviceMotion *motionData, NSError *error)
        {
            if (!error && self.delegate && [self.delegate respondsToSelector:@selector((currentPitch:currentRoll:currentYaw:))])
                [self.delegate currentPitch:motionData.attitude.pitch currentRoll:motionData.attitude.roll currentYaw:motionData.attitude.yaw];
        }];
    }
}

@end
