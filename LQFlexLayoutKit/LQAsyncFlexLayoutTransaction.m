//
//  LQAsyncFlexLayoutTransaction.m
//  LQFlexLayoutKit
//
//  Created by cuilanqing on 2018/5/29.
//

#import "LQAsyncFlexLayoutTransaction.h"
#import <UIKit/UIKit.h>
#import <os/lock.h>
#import <pthread.h>

// transaction queue
static NSMutableArray *layoutQueue = nil;
static CFRunLoopSourceRef _runLoopSource = nil;
static pthread_mutex_t _lock;

static void atomOperation(dispatch_block_t block) {
    if (@available(iOS 10.0, *)) {
        // OSSpinLock存在优先级反转问题，使用os_unfair_lock
        static os_unfair_lock lockToken = OS_UNFAIR_LOCK_INIT;
        os_unfair_lock_lock(&lockToken);
        block();
        os_unfair_lock_unlock(&lockToken);
    } else {
        // Fallback on earlier versions
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            pthread_mutex_init(&_lock, NULL);
        });
        pthread_mutex_lock(&_lock);
        block();
        pthread_mutex_unlock(&_lock);
    }
}

static void enqueue(dispatch_block_t block) {
    atomOperation(^{
        if (!layoutQueue) {
            layoutQueue = [NSMutableArray array];
        }
        [layoutQueue addObject:block];
        CFRunLoopSourceSignal(_runLoopSource);
        CFRunLoopWakeUp(CFRunLoopGetMain());
    });
}

static void processQueue() {
    atomOperation(^{
        if (layoutQueue.count > 0) {
#ifdef DEBUG
            NSLog(@"start process one operation");
#endif
            dispatch_block_t operation = layoutQueue.firstObject;
            operation();
            [layoutQueue removeObjectAtIndex:0];
        }
    });
}

/// RunLoop事件回调
static void _runLoopObserverCallback() {
    processQueue();
}

static void addTransaction(dispatch_block_t calculate, dispatch_block_t layout) {
    dispatch_async(dispatch_get_main_queue(), ^{
        calculate();
        enqueue(layout);
    });
}

@implementation LQAsyncFlexLayoutTransaction

+(void)load {
    CFRunLoopRef runLoop = CFRunLoopGetMain();
    CFOptionFlags activities = kCFRunLoopBeforeWaiting | kCFRunLoopExit;
    
    CFRunLoopObserverRef observer = CFRunLoopObserverCreate(NULL, activities, YES, INT_MAX, &_runLoopObserverCallback, NULL);
    if (observer) {
        CFRunLoopAddObserver(runLoop, observer, kCFRunLoopCommonModes);
        CFRelease(observer);
    }
    
    CFRunLoopSourceContext *runLoopSourceContext = calloc(1, sizeof(CFRunLoopSourceContext));
    _runLoopSource = CFRunLoopSourceCreate(NULL, 0, runLoopSourceContext);
    if (_runLoopSource) {
        CFRunLoopAddSource(runLoop, _runLoopSource, kCFRunLoopCommonModes);
    }
}

+(void)addAsyncCalculateTransaction:(dispatch_block_t)calculate
                           complete:(dispatch_block_t)layout
{
    addTransaction(calculate, layout);
}

@end
