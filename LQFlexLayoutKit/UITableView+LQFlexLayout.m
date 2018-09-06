//
//  UITableView+LQFlexLayout.m
//  LQFlexLayoutKit
//
//  Created by cuilanqing on 2018/5/29.
//

#import "UITableView+LQFlexLayout.h"
#import <objc/runtime.h>
#import "UIView+Yoga.h"
#import "LQAsyncFlexLayoutTransaction.h"

static NSString *kCellIdentifier = @"lq_kCellIdentifier";

typedef NSMutableArray<NSMutableArray<NSNumber *> *> LQIndexPathHeightBySections;

@implementation UITableView (LQFlexLayout)

-(CGFloat)constraintWidth {
    return [objc_getAssociatedObject(self, _cmd) floatValue];
}

-(void)setConstraintWidth:(CGFloat)constraintWidth {
    objc_setAssociatedObject(self, @selector(constraintWidth), @(constraintWidth), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(CGFloat)lq_heightForCellWithIdentifier:(NSString *)identifier configuration:(void (^)(id))configuration {
    if (!identifier) {
        return 0;
    }
    UITableViewCell *templateLayoutCell = [self lq_templateCellForReuseIdentifier:identifier];
    
    if (configuration) {
        configuration(templateLayoutCell);
    }
    
    if (templateLayoutCell.contentView.subviews.count > 0) {
        return [templateLayoutCell.contentView.yoga calculateLayoutWithSize:CGSizeMake(self.constraintWidth ? : self.frame.size.width, YGUndefined)].height;
    }else {
        return [templateLayoutCell.yoga calculateLayoutWithSize:CGSizeMake(self.constraintWidth ? : self.frame.size.width, YGUndefined)].height;
    }
}

-(CGFloat)lq_heightForCellWithIdentifier:(NSString *)identifier
                        cacheByIndexPath:(NSIndexPath *)indexPath
                           configuration:(void (^)(id))configuration
{
    if (!identifier || !indexPath) {
        return 0;
    }
    
    // Hit cache
    if ([self.lq_indexPathHeightCache existsHeightAtIndexPath:indexPath]) {
        return [self.lq_indexPathHeightCache heightForIndexPath:indexPath];
    }
    
    // cache height
    CGFloat height = [self lq_heightForCellWithIdentifier:identifier configuration:configuration];
    [self.lq_indexPathHeightCache cacheHeight:height byIndexPath:indexPath];
    
    return height;
}

-(CGFloat)lq_heightForHeaderFooterViewWithIdentifier:(NSString *)identifier configuration:(void (^)(id))configuration {
    UITableViewHeaderFooterView *templateHeaderFooterView = [self lq_templateHeaderFooterViewForReuseIdentifier:identifier];
    
    if (configuration) {
        configuration(templateHeaderFooterView);
    }
    
    if (templateHeaderFooterView.contentView.subviews.count > 0) {
        return [templateHeaderFooterView.contentView.yoga calculateLayoutWithSize:CGSizeMake(self.constraintWidth ? : self.frame.size.width, YGUndefined)].height;
    }else {
        return [templateHeaderFooterView.yoga calculateLayoutWithSize:CGSizeMake(self.constraintWidth ? : self.frame.size.width, YGUndefined)].height;
    }
}

-(__kindof UITableViewCell *)lq_templateCellForReuseIdentifier:(NSString *)identifier {
    NSAssert(identifier.length > 0, @"invalid identifier : %@", identifier);
    
    NSMutableDictionary<NSString *, UITableViewCell *> *templateCellsByIdentifiers = objc_getAssociatedObject(self, _cmd);
    if (!templateCellsByIdentifiers) {
        templateCellsByIdentifiers = @{}.mutableCopy;
        objc_setAssociatedObject(self, _cmd, templateCellsByIdentifiers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    UITableViewCell *templateCell = templateCellsByIdentifiers[identifier];
    if (!templateCell) {
        templateCell = [self dequeueReusableCellWithIdentifier:identifier];
        NSAssert(templateCell != nil, @"Cell must be registered to table view for identifier - %@", identifier);
        templateCell.lq_isTemplateLayoutCell = YES;
        templateCellsByIdentifiers[identifier] = templateCell;
    }
    return templateCell;
}

- (__kindof UITableViewHeaderFooterView *)lq_templateHeaderFooterViewForReuseIdentifier:(NSString *)identifier {
    NSAssert(identifier.length > 0, @"Expect a valid identifier - %@", identifier);
    
    NSMutableDictionary<NSString *, UITableViewHeaderFooterView *> *templateHeaderFooterViews = objc_getAssociatedObject(self, _cmd);
    if (!templateHeaderFooterViews) {
        templateHeaderFooterViews = @{}.mutableCopy;
        objc_setAssociatedObject(self, _cmd, templateHeaderFooterViews, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    UITableViewHeaderFooterView *templateHeaderFooterView = templateHeaderFooterViews[identifier];
    
    if (!templateHeaderFooterView) {
        templateHeaderFooterView = [self dequeueReusableHeaderFooterViewWithIdentifier:identifier];
        NSAssert(templateHeaderFooterView != nil, @"HeaderFooterView must be registered to table view for identifier - %@", identifier);
        templateHeaderFooterView.contentView.translatesAutoresizingMaskIntoConstraints = NO;
        templateHeaderFooterViews[identifier] = templateHeaderFooterView;
    }
    
    return templateHeaderFooterView;
}

@end

@interface LQIndexPathHeightCache ()
@property (nonatomic, strong) LQIndexPathHeightBySections *heightsBySections;
@end

@implementation LQIndexPathHeightCache
- (instancetype)init {
    self = [super init];
    if (self) {
        _heightsBySections = [NSMutableArray array];
    }
    return self;
}

-(BOOL)existsHeightAtIndexPath:(NSIndexPath *)indexPath {
    [self buildCachesAtIndexPathIfNeeded:@[indexPath]];
    NSNumber *number = self.heightsBySections[indexPath.section][indexPath.row];
    return ![number isEqualToNumber:@-1];
}

-(void)cacheHeight:(CGFloat)height byIndexPath:(NSIndexPath *)indexPath {
    self.automaticallyInvalidateEnabled = YES;
    [self buildCachesAtIndexPathIfNeeded:@[indexPath]];
    self.heightsBySections[indexPath.section][indexPath.row] = @(height);
}

-(CGFloat)heightForIndexPath:(NSIndexPath *)indexPath {
    [self buildCachesAtIndexPathIfNeeded:@[indexPath]];
    NSNumber *number = self.heightsBySections[indexPath.section][indexPath.row];
#if CGFLOAT_IS_DOUBLE
    return number.doubleValue;
#else
    return number.floatValue;
#endif
}

-(void)invalidateHeightAtIndexPath:(NSIndexPath *)indexPath {
    [self buildCachesAtIndexPathIfNeeded:@[indexPath]];
    [self enumerateHeightCacheUsingBlock:^(LQIndexPathHeightBySections *heightsBySections) {
        heightsBySections[indexPath.section][indexPath.row] = @-1;
    }];
}

-(void)invalidateAllHeightCache {
    [self enumerateHeightCacheUsingBlock:^(LQIndexPathHeightBySections *heightsBySections) {
        [heightsBySections removeAllObjects];
    }];
}

-(void)buildCachesAtIndexPathIfNeeded:(NSArray *)indexPathes {
    // Build every section array or row array which is smaller than given index path.
    [indexPathes enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull indexPath, NSUInteger idx, BOOL * _Nonnull stop) {
        [self buildSectionsIfNeeded:indexPath.section];
        [self buildRowsIfNeeded:indexPath.row inExistSection:indexPath.section];
    }];
}

-(void)buildSectionsIfNeeded:(NSInteger)targetSection {
    [self enumerateHeightCacheUsingBlock:^(LQIndexPathHeightBySections *heightsBySections) {
        for (NSInteger section = 0; section <= targetSection; ++section) {
            if (section >= heightsBySections.count) {
                heightsBySections[section] = [NSMutableArray array];
            }
        }
    }];
}

-(void)buildRowsIfNeeded:(NSInteger)targetRow inExistSection:(NSInteger)section {
    [self enumerateHeightCacheUsingBlock:^(LQIndexPathHeightBySections *heightsBySections) {
        NSMutableArray<NSNumber *> *heightsByRow = heightsBySections[section];
        for (NSInteger row = 0; row <= targetRow; ++row) {
            if (row >= heightsByRow.count) {
                heightsByRow[row] = @-1;
            }
        }
    }];
}

-(void)enumerateHeightCacheUsingBlock:(void(^)(LQIndexPathHeightBySections *heightBySections))block {
    block(self.heightsBySections);
}

@end

@implementation UITableView (LQFlexLayoutIndexPathHeightCache)

-(LQIndexPathHeightCache *)lq_indexPathHeightCache {
    LQIndexPathHeightCache *cache = objc_getAssociatedObject(self, _cmd);
    if (!cache) {
        cache = [LQIndexPathHeightCache new];
        objc_setAssociatedObject(self, _cmd, cache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return cache;
}

@end

/// 当数据源发生改变时，cell高度缓存失效机制
@implementation UITableView (LQIndexPathHeightCacheInvalidation)

+(void)load {
    // All methods that trigger height cache's invalidation
    SEL selectors[] = {
        @selector(reloadData),
        @selector(insertSections:withRowAnimation:),
        @selector(deleteSections:withRowAnimation:),
        @selector(reloadSections:withRowAnimation:),
        @selector(moveSection:toSection:),
        @selector(insertRowsAtIndexPaths:withRowAnimation:),
        @selector(deleteRowsAtIndexPaths:withRowAnimation:),
        @selector(reloadRowsAtIndexPaths:withRowAnimation:),
        @selector(moveRowAtIndexPath:toIndexPath:)
    };
    
    for (NSUInteger index = 0; index < sizeof(selectors) / sizeof(SEL); index++) {
        SEL originalSelector = selectors[index];
        SEL swizzledSelector = NSSelectorFromString([@"lq_" stringByAppendingString:NSStringFromSelector(originalSelector)]);
        Method originalMethod = class_getInstanceMethod(self, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(self, swizzledSelector);
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

-(void)lq_reloadDataWithoutInvalidateIndexPathHeightCache {
    [self lq_reloadData];
}

-(void)lq_reloadData {
    if (self.lq_indexPathHeightCache.automaticallyInvalidateEnabled) {
        [self.lq_indexPathHeightCache enumerateHeightCacheUsingBlock:^(LQIndexPathHeightBySections *heightBySections) {
            [heightBySections removeAllObjects];
        }];
    }
    [self lq_reloadData];
}

-(void)lq_insertSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation {
    if (self.lq_indexPathHeightCache.automaticallyInvalidateEnabled) {
        [sections enumerateIndexesUsingBlock:^(NSUInteger section, BOOL * _Nonnull stop) {
            [self.lq_indexPathHeightCache buildSectionsIfNeeded:section];
            [self.lq_indexPathHeightCache enumerateHeightCacheUsingBlock:^(LQIndexPathHeightBySections *heightBySections) {
                [heightBySections insertObject:[NSMutableArray array] atIndex:section];
            }];
        }];
    }
    [self lq_insertSections:sections withRowAnimation:animation];
}

- (void)lq_deleteSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation {
    if (self.lq_indexPathHeightCache.automaticallyInvalidateEnabled) {
        [sections enumerateIndexesUsingBlock:^(NSUInteger section, BOOL * _Nonnull stop) {
            [self.lq_indexPathHeightCache buildSectionsIfNeeded:section];
            [self.lq_indexPathHeightCache enumerateHeightCacheUsingBlock:^(LQIndexPathHeightBySections *heightBySections) {
                [heightBySections removeObjectAtIndex:section];
            }];
        }];
    }
    [self lq_deleteSections:sections withRowAnimation:animation];
}

- (void)lq_reloadSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation {
    if (self.lq_indexPathHeightCache.automaticallyInvalidateEnabled) {
        [sections enumerateIndexesUsingBlock:^(NSUInteger section, BOOL * _Nonnull stop) {
            [self.lq_indexPathHeightCache buildSectionsIfNeeded:section];
            [self.lq_indexPathHeightCache enumerateHeightCacheUsingBlock:^(LQIndexPathHeightBySections *heightBySections) {
                [heightBySections[section] removeAllObjects];
            }];
        }];
    }
    [self lq_reloadSections:sections withRowAnimation:animation];
}

- (void)lq_moveSection:(NSInteger)section toSection:(NSInteger)newSection {
    if (self.lq_indexPathHeightCache.automaticallyInvalidateEnabled) {
        [self.lq_indexPathHeightCache buildSectionsIfNeeded:section];
        [self.lq_indexPathHeightCache buildSectionsIfNeeded:newSection];
        [self.lq_indexPathHeightCache enumerateHeightCacheUsingBlock:^(LQIndexPathHeightBySections *heightBySections) {
            [heightBySections exchangeObjectAtIndex:section withObjectAtIndex:newSection];
        }];
    }
    [self lq_moveSection:section toSection:newSection];
}

- (void)lq_insertRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation {
    if (self.lq_indexPathHeightCache.automaticallyInvalidateEnabled) {
        [self.lq_indexPathHeightCache buildCachesAtIndexPathIfNeeded:indexPaths];
        [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop) {
            [self.lq_indexPathHeightCache enumerateHeightCacheUsingBlock:^(LQIndexPathHeightBySections *heightBySections) {
                [heightBySections[indexPath.section] insertObject:@-1 atIndex:indexPath.row];
            }];
        }];
    }
    [self lq_insertRowsAtIndexPaths:indexPaths withRowAnimation:animation];
}

- (void)lq_deleteRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation {
    if (self.lq_indexPathHeightCache.automaticallyInvalidateEnabled) {
        [self.lq_indexPathHeightCache buildCachesAtIndexPathIfNeeded:indexPaths];
        
        NSMutableDictionary<NSNumber *, NSMutableIndexSet *> *mutableIndexSetsToRemove = [NSMutableDictionary dictionary];
        [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop) {
            NSMutableIndexSet *mutableIndexSet = mutableIndexSetsToRemove[@(indexPath.section)];
            if (!mutableIndexSet) {
                mutableIndexSet = [NSMutableIndexSet indexSet];
                mutableIndexSetsToRemove[@(indexPath.section)] = mutableIndexSet;
            }
            [mutableIndexSet addIndex:indexPath.row];
        }];
        
        [mutableIndexSetsToRemove enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, NSIndexSet *indexSet, BOOL *stop) {
            [self.lq_indexPathHeightCache enumerateHeightCacheUsingBlock:^(LQIndexPathHeightBySections *heightBySection) {
                [heightBySection[key.integerValue] removeObjectsAtIndexes:indexSet];
            }];
        }];
    }
    [self lq_deleteRowsAtIndexPaths:indexPaths withRowAnimation:animation];
}

- (void)lq_reloadRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation {
    if (self.lq_indexPathHeightCache.automaticallyInvalidateEnabled) {
        [self.lq_indexPathHeightCache buildCachesAtIndexPathIfNeeded:indexPaths];
        [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop) {
            [self.lq_indexPathHeightCache enumerateHeightCacheUsingBlock:^(LQIndexPathHeightBySections *heightBySections) {
                heightBySections[indexPath.section][indexPath.row] = @-1;
            }];
        }];
    }
    [self lq_reloadRowsAtIndexPaths:indexPaths withRowAnimation:animation];
}

- (void)lq_moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    if (self.lq_indexPathHeightCache.automaticallyInvalidateEnabled) {
        [self.lq_indexPathHeightCache buildCachesAtIndexPathIfNeeded:@[sourceIndexPath, destinationIndexPath]];
        [self.lq_indexPathHeightCache enumerateHeightCacheUsingBlock:^(LQIndexPathHeightBySections *heightBySection) {
            NSMutableArray<NSNumber *> *sourceRows = heightBySection[sourceIndexPath.section];
            NSMutableArray<NSNumber *> *destinationRows = heightBySection[destinationIndexPath.section];
            NSNumber *sourceValue = sourceRows[sourceIndexPath.row];
            NSNumber *destinationValue = destinationRows[destinationIndexPath.row];
            sourceRows[sourceIndexPath.row] = destinationValue;
            destinationRows[destinationIndexPath.row] = sourceValue;
        }];
    }
    [self lq_moveRowAtIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];
}

@end

@implementation UITableViewCell (LQTemplateLayoutCell)

-(BOOL)lq_isTemplateLayoutCell {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

-(void)setGw_isTemplateLayoutCell:(BOOL)lq_isTemplateLayoutCell {
    objc_setAssociatedObject(self, @selector(lq_isTemplateLayoutCell), @(lq_isTemplateLayoutCell), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

