//
//  UITableView+LQFlexLayout.h
//  LQFlexLayoutKit
//
//  Created by cuilanqing on 2018/5/29.
//

#import <UIKit/UIKit.h>

@interface LQIndexPathHeightCache : NSObject

// Enable automatically if you're using index path driven height cache
@property (nonatomic, assign) BOOL automaticallyInvalidateEnabled;

// Height cache
- (BOOL)existsHeightAtIndexPath:(NSIndexPath *)indexPath;
- (void)cacheHeight:(CGFloat)height byIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)heightForIndexPath:(NSIndexPath *)indexPath;
- (void)invalidateHeightAtIndexPath:(NSIndexPath *)indexPath;
- (void)invalidateAllHeightCache;

@end

@interface UITableView (LQFlexLayout)

@property (nonatomic, assign) CGFloat constraintWidth;

/// get cell height
-(CGFloat)lq_heightForCellWithIdentifier:(NSString *)identifier
                           configuration:(void (^)(id cell))configuration;

/// get cell height from cache
-(CGFloat)lq_heightForCellWithIdentifier:(NSString *)identifier
                        cacheByIndexPath:(NSIndexPath *)indexPath
                           configuration:(void (^)(id))configuration;

/// get tableView's header or footer view height
-(CGFloat)lq_heightForHeaderFooterViewWithIdentifier:(NSString *)identifier
                                       configuration:(void (^)(id headerFooterView))configuration;

@end

@interface UITableView (LQFlexLayoutIndexPathHeightCache)

@property (nonatomic, strong, readonly) LQIndexPathHeightCache *lq_indexPathHeightCache;

@end

@interface UITableViewCell (LQTemplateLayoutCell)

/// Indicate this is a template layout cell for calculation only.
/// You may need this when there are non-UI side effects when configure a cell.
/// Like:
///   - (void)configureCell:(FooCell *)cell atIndexPath:(NSIndexPath *)indexPath {
///       cell.entity = [self entityAtIndexPath:indexPath];
///       if (!cell.fd_isTemplateLayoutCell) {
///           [self notifySomething]; // non-UI side effects
///       }
///   }
///
@property (nonatomic, assign) BOOL lq_isTemplateLayoutCell;

@end

@interface UITableView (LQIndexPathHeightCacheInvalidation)
/// Call this method when you want to reload data but don't want to invalidate
/// all height cache by index path, for example, load more data at the bottom of
/// table view.
- (void)lq_reloadDataWithoutInvalidateIndexPathHeightCache;
@end
