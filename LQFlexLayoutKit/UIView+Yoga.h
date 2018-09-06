/**
 * Copyright (c) 2014-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <UIKit/UIKit.h>
#import "YGLayout.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^YGLayoutConfigurationBlock)(YGLayout *layout);

@interface UIView (Yoga)

/**
 The YGLayout that is attached to this view. It is lazily created.
 */
@property (nonatomic, readonly, strong) YGLayout *yoga;
/**
 Indicates whether or not Yoga is enabled
 */
@property (nonatomic, readonly, assign) BOOL isYogaEnabled;

/**
 In ObjC land, every time you access `view.yoga.*` you are adding another `objc_msgSend`
 to your code. If you plan on making multiple changes to YGLayout, it's more performant
 to use this method, which uses a single objc_msgSend call.
 */
- (void)configureLayoutWithBlock:(YGLayoutConfigurationBlock)block;

/*
 * bugfix: UILabel重设text后调用applyLayoutPreservingOrigin:也无法重置label的size（label的size为适应上一个text的size），
 * 经过排查发现，在YGApplyLayoutToViewHierarchy方法中的YGNodeLayoutGetWidth(node)/YGNodeLayoutGetHeight(node)
 * 返回了重设text之前的size，查看Yoga的源码后发现，YGNodeLayoutGetWidth(node)的方法最终转化为以下调用
 * YGNodeLayoutGetWidth(const YGNodeRef node) {
        return node->getLayout().YGDimensionWidth;
    }
 * getLayout()函数返回一个YGLayout对象，在YGLayout中对UIView的某些layout做了缓存（Instead of recomputing the entire layout every single time, we
   cache some information to break early when nothing changed），对于新的text，该函数返回了缓存的size,猜测是这个原因导致label的size没有根据新的text变化，这里重设label的yoga,让其根据新的text生成layout。
 */
- (void)resetYogaIfNeeded;

@end

NS_ASSUME_NONNULL_END
