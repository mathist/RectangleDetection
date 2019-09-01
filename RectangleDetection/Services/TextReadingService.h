//
//  TextReadingService.h
//  RectangleDetection
//
//  Created by Todd Mathison on 8/30/19.
//  Copyright © 2019 Todd Mathison. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Vision/Vision.h>

NS_ASSUME_NONNULL_BEGIN

@protocol TextReadingServiceDelegate;

@interface TextReadingService : NSObject

@property(nonatomic, weak) id<TextReadingServiceDelegate> delegate;

-(void)readText:(UIImage *)image;

@end


@protocol TextReadingServiceDelegate <NSObject>

-(void)textFound:(NSArray <VNRecognizedTextObservation *>*) texts API_AVAILABLE(ios(13.0));

@end

NS_ASSUME_NONNULL_END
