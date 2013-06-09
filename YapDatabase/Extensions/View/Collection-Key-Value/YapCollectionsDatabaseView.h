#import <Foundation/Foundation.h>

#import "YapAbstractDatabaseExtension.h"
#import "YapCollectionsDatabaseViewConnection.h"
#import "YapCollectionsDatabaseViewTransaction.h"

/**
 * Welcome to YapDatabase!
 *
 * The project page has a wealth of documentation if you have any questions.
 * https://github.com/yaptv/YapDatabase
 *
 * If you're new to the project you may want to check out the wiki
 * https://github.com/yaptv/YapDatabase/wiki
 *
 * YapDatabaseView is an extension designed to work with YapDatabase.
 *
 * What is an extension?
 * https://github.com/yaptv/YapDatabase/wiki/Extensions
**/

/**
 * The grouping block handles both filtering and grouping.
 * 
 * When you add or update rows in the databse the grouping block is invoked.
 * Your grouping block can inspect the row and determine if it should be a part of the view.
 * If not, your grouping block simply returns 'nil' and the object is excluded from the view (removing it if needed).
 * Otherwise your grouping block returns a group, which can be any string you want.
 * Once the view knows what group the row belongs to,
 * it with then determine the index/position of the row within the group (using the sorting block).
 * 
 * You should choose a block type that takes the minimum number of required parameters.
 * The view can make various optimizations based on required parameters of the block.
 * For example, if grouping is based on the object, and the metadata of a row is updated,
 * then the view can deduce that the group hasn't changed, and can skip this step.
**/
typedef id YapCollectionsDatabaseViewGroupingBlock; // One of the YapCollectionsDatabaseViewGroupingX types below.

typedef NSString* (^YapCollectionsDatabaseViewGroupingWithKeyBlock) \
            (NSString *collection, NSString *key);
typedef NSString* (^YapCollectionsDatabaseViewGroupingWithObjectBlock) \
            (NSString *collection, NSString *key, id object);
typedef NSString* (^YapCollectionsDatabaseViewGroupingWithMetadataBlock) \
            (NSString *collection, NSString *key, id metadata);
typedef NSString* (^YapCollectionsDatabaseViewGroupingWithObjectAndMetadataBlock) \
            (NSString *collection, NSString *key, id object, id metadata);

/**
 * The sorting block handles sorting of objects within their group.
 *
 * After the view invokes the grouping block to determine what group a database row belongs to (if any),
 * the view then needs to determine what index within that group the row should be.
 * In order to do this, it needs to compare the new/updated row with existing rows in the same view group.
 * This is what the sorting block is used for.
 * So the sorting block will be invoked automatically during this process until the view has come to a conclusion.
 * 
 * You should choose a block type that takes the minimum number of required parameters.
 * The view can make various optimizations based on required parameters of the block.
 * For example, if sorting is based on the object, and the metadata of a row is updated,
 * then the view can deduce that the index hasn't changed (if the group hans't), and can skip this step.
 * 
 * Performance note:
 * The view uses various optimizations (based on common patterns)
 * to reduce the number of times it needs to invoke the sorting block.
 *
 * - Pattern      : row is updated, but its index in the view doesn't change.
 *   Optimization : if an updated row doesn't change groups, the view will first compare it with
 *                  objects to the left and right.
 *
 * - Pattern      : rows are added to the beginning or end or a view
 *   Optimization : if the last change put an object at the beginning of the view, then it will test this quickly.
 *                  if the last change put an object at the end of the view, then it will test this quickly.
 * 
 * These optimizations offer huge performance benefits to many common cases.
 * For example, adding objects to a view that are sorted by timestamp of when they arrived.
 *
 * The optimizations are not always performed.
 * That is, if the row is added to a group it didn't previously belong,
 * or if the last change didn't place an item at the beginning or end of the view.
 *
 * If optimizations fail, or are skipped, then the view uses a binary search algorithm.
 * 
 * Although this may be considered "internal information", I feel it is important to explain for the following reason:
 * Another common pattern is to fetch a number of objects in a batch, and then insert them into the database.
 * Now imagine a situation in which the view is sorting posts based on timestamp,
 * and you just fetched the most recent 10 posts. You can enumerate these 10 posts in forwards or backwards
 * while adding them to the database. One direction will hit the optimization every time. The other will cause
 * the view to perform a binary search every time. These little one-liner optimzations are easy.
**/
typedef id YapCollectionsDatabaseViewSortingBlock; // One of the YapCollectionsDatabaseViewSortingX types below.

typedef NSComparisonResult (^YapCollectionsDatabaseViewSortingWithKeyBlock) \
                 (NSString *group, NSString *collection1, NSString *key1, \
                                   NSString *collection2, NSString *key2);
typedef NSComparisonResult (^YapCollectionsDatabaseViewSortingWithObjectBlock) \
                 (NSString *group, NSString *collection1, NSString *key1, id object1, \
                                   NSString *collection2, NSString *key2, id object2);
typedef NSComparisonResult (^YapCollectionsDatabaseViewSortingWithMetadataBlock) \
                 (NSString *group, NSString *collection1, NSString *key1, id metadata, \
                                   NSString *collection2, NSString *key2, id metadata2);
typedef NSComparisonResult (^YapCollectionsDatabaseViewSortingWithObjectAndMetadataBlock) \
                 (NSString *group, NSString *collection1, NSString *key1, id object1, id metadata1, \
                                   NSString *collection2, NSString *key2, id object2, id metadata2);

/**
 * I wish there was a way to inspect a given block and see what kind of parameters it takes.
 * Sadly this does not appear to be possible (at least not in any kind of standard legal way).
 * 
 * Thus, unfortunately (for now), you will have to specify what kind of block you're passing.
**/
typedef enum {
	YapCollectionsDatabaseViewBlockTypeWithKey               = 201,
	YapCollectionsDatabaseViewBlockTypeWithObject            = 202,
	YapCollectionsDatabaseViewBlockTypeWithMetadata          = 203,
	YapCollectionsDatabaseViewBlockTypeWithObjectAndMetadata = 204
} YapCollectionsDatabaseViewBlockType;


@interface YapCollectionsDatabaseView : YapAbstractDatabaseExtension

/* Inherited from YapAbstractDatabaseExtension
 
@property (nonatomic, strong, readonly) NSString *registeredName;

*/

- (id)initWithGroupingBlock:(YapCollectionsDatabaseViewGroupingBlock)groupingBlock
          groupingBlockType:(YapCollectionsDatabaseViewBlockType)groupingBlockType
               sortingBlock:(YapCollectionsDatabaseViewSortingBlock)sortingBlock
           sortingBlockType:(YapCollectionsDatabaseViewBlockType)sortingBlockType;

@property (nonatomic, strong, readonly) YapCollectionsDatabaseViewGroupingBlock groupingBlock;
@property (nonatomic, strong, readonly) YapCollectionsDatabaseViewSortingBlock sortingBlock;

@property (nonatomic, assign, readonly) YapCollectionsDatabaseViewBlockType groupingBlockType;
@property (nonatomic, assign, readonly) YapCollectionsDatabaseViewBlockType sortingBlockType;

@end