//
//  LQAsyncFlexLayoutTransaction.h
//  LQFlexLayoutKit
//
//  Created by cuilanqing on 2018/5/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LQAsyncFlexLayoutTransaction : NSObject

+(void)addAsyncCalculateTransaction:(dispatch_block_t)transaction
                           complete:(nullable dispatch_block_t)complete;

@end

NS_ASSUME_NONNULL_END
