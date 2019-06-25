//
//  ActivityManagerService.h
//  RectangleDetection
//
//  Created by Todd Mathison on 6/25/19.
//  Copyright © 2019 Todd Mathison. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ActivityManagerService : NSObject

@property (nonatomic, class, readonly) ActivityManagerService *shared;
-(void)incrementActivityCount;
-(void)decrementActivityCount;

@end

NS_ASSUME_NONNULL_END
