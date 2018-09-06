/**
 * Copyright (c) 2014-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "UIView+Yoga.h"
#import "YGLayout+Private.h"
#import <objc/runtime.h>

static const void *kYGYogaAssociatedKey = &kYGYogaAssociatedKey;

@interface UIView ()

@property (nonatomic, copy) YGLayoutConfigurationBlock layoutConfigBlock;

@end

@implementation UIView (Yoga)

- (YGLayout *)yoga
{
    YGLayout *yoga = objc_getAssociatedObject(self, kYGYogaAssociatedKey);
    if (!yoga) {
        yoga = [[YGLayout alloc] initWithView:self];
        objc_setAssociatedObject(self, kYGYogaAssociatedKey, yoga, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return yoga;
}

- (YGLayoutConfigurationBlock)layoutConfigBlock {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setLayoutConfigBlock:(YGLayoutConfigurationBlock)layoutConfigBlock {
    objc_setAssociatedObject(self, @selector(layoutConfigBlock), layoutConfigBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)resetYogaIfNeeded {
    // 1. remove previous yoga object
    if (self.yoga) {
        objc_setAssociatedObject(self, kYGYogaAssociatedKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    // 2. reset yoga config by previous layout config
    YGLayoutConfigurationBlock configBlock = self.layoutConfigBlock;
    if (configBlock) {
        configBlock(self.yoga);
    }
}

- (BOOL)isYogaEnabled
{
    return objc_getAssociatedObject(self, kYGYogaAssociatedKey) != nil;
}

- (void)configureLayoutWithBlock:(YGLayoutConfigurationBlock)block
{
    if (block != nil) {
        block(self.yoga);
        if (self.yoga.shouldIgnoreCachedLayout) {
            self.layoutConfigBlock = block;
        }
    }
}

@end
