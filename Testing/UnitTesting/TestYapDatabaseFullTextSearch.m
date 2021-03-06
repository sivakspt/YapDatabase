#import <SenTestingKit/SenTestingKit.h>

#import "YapDatabase.h"
#import "YapDatabaseFullTextSearch.h"

#import "DDLog.h"
#import "DDTTYLogger.h"


@interface TestYapDatabaseFullTextSearch : SenTestCase

@end

#pragma mark -

@implementation TestYapDatabaseFullTextSearch

- (NSString *)databasePath:(NSString *)suffix
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *baseDir = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
	
	NSString *databaseName = [NSString stringWithFormat:@"%@-%@.sqlite", THIS_FILE, suffix];
	
	return [baseDir stringByAppendingPathComponent:databaseName];
}

- (void)setUp
{
	[super setUp];
	[DDLog removeAllLoggers];
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
}

- (void)tearDown
{
	[DDLog flushLog];
	[super tearDown];
}

- (void)test
{
	NSString *databasePath = [self databasePath:NSStringFromSelector(_cmd)];
	
	[[NSFileManager defaultManager] removeItemAtPath:databasePath error:NULL];
	YapDatabase *database = [[YapDatabase alloc] initWithPath:databasePath];
	
	STAssertNotNil(database, @"Oops");
	
	YapDatabaseConnection *connection = [database newConnection];
	
	YapDatabaseFullTextSearchBlockType blockType = YapDatabaseFullTextSearchBlockTypeWithObject;
	YapDatabaseFullTextSearchWithObjectBlock block =
	^(NSMutableDictionary *dict, NSString *collection, NSString *key, id object){
		
		[dict setObject:object forKey:@"content"];
	};
	
	YapDatabaseFullTextSearch *fts =
	  [[YapDatabaseFullTextSearch alloc] initWithColumnNames:@[@"content"]
	                                                   block:block
	                                               blockType:blockType];
	
	[database registerExtension:fts withName:@"fts"];
	
	[connection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
		
		[transaction setObject:@"hello world"       forKey:@"key1" inCollection:nil];
		[transaction setObject:@"hello coffee shop" forKey:@"key2" inCollection:nil];
		[transaction setObject:@"hello laptop"      forKey:@"key3" inCollection:nil];
		[transaction setObject:@"hello work"        forKey:@"key4" inCollection:nil];
	}];
	
	[connection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
		
		__block NSUInteger count;
		
		// Find matches for: hello
		
		count = 0;
		[[transaction ext:@"fts"] enumerateKeysMatching:@"hello"
		                                     usingBlock:^(NSString *collection, NSString *key, BOOL *stop) {
			count++;
		}];
		STAssertTrue(count == 4, @"Missing search results");
		
		// Find matches for: coffee
		
		count = 0;
		[[transaction ext:@"fts"] enumerateKeysMatching:@"coffee"
		                                     usingBlock:^(NSString *collection, NSString *key, BOOL *stop) {
			count++;
		}];
		STAssertTrue(count == 1, @"Missing search results");
		
		// Find matches for: hello wor*
		
		count = 0;
		[[transaction ext:@"fts"] enumerateKeysMatching:@"hello wor*"
		                                     usingBlock:^(NSString *collection, NSString *key, BOOL *stop) {
			count++;
		}];
		STAssertTrue(count == 2, @"Missing search results");
		
		// Find matches for: quack
		
		count = 0;
		[[transaction ext:@"fts"] enumerateKeysMatching:@"quack"
		                                     usingBlock:^(NSString *collection, NSString *key, BOOL *stop) {
			count++;
		}];
		STAssertTrue(count == 0, @"Missing search results");
	}];
	
	[connection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
		
		[transaction setObject:@"hello distraction" forKey:@"key4" inCollection:nil];
	}];
	
	[connection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
		
		__block NSUInteger count;
		
		// Find matches for: hello
		
		count = 0;
		[[transaction ext:@"fts"] enumerateKeysMatching:@"hello"
		                                     usingBlock:^(NSString *collection, NSString *key, BOOL *stop) {
			count++;
		}];
		STAssertTrue(count == 4, @"Missing search results");
		
		// Find matches for: coffee
		
		count = 0;
		[[transaction ext:@"fts"] enumerateKeysMatching:@"coffee"
		                                     usingBlock:^(NSString *collection, NSString *key, BOOL *stop) {
			count++;
		}];
		STAssertTrue(count == 1, @"Missing search results");
		
		// Find matches for: hello wor*
		
		count = 0;
		[[transaction ext:@"fts"] enumerateKeysMatching:@"hello wor*"
		                                     usingBlock:^(NSString *collection, NSString *key, BOOL *stop) {
			count++;
		}];
		STAssertTrue(count == 1, @"Missing search results");
		
		// Find matches for: quack
		
		count = 0;
		[[transaction ext:@"fts"] enumerateKeysMatching:@"quack"
		                                     usingBlock:^(NSString *collection, NSString *key, BOOL *stop) {
			count++;
		}];
		STAssertTrue(count == 0, @"Missing search results");
	}];
}

- (void)testSnippet
{
	NSString *databasePath = [self databasePath:NSStringFromSelector(_cmd)];
	
	[[NSFileManager defaultManager] removeItemAtPath:databasePath error:NULL];
	YapDatabase *database = [[YapDatabase alloc] initWithPath:databasePath];
	
	STAssertNotNil(database, @"Oops");
	
	YapDatabaseConnection *connection = [database newConnection];
	
	YapDatabaseFullTextSearchBlockType blockType = YapDatabaseFullTextSearchBlockTypeWithObject;
	YapDatabaseFullTextSearchWithObjectBlock block =
	^(NSMutableDictionary *dict, NSString *collection, NSString *key, id object){
		
		[dict setObject:object forKey:@"content"];
	};
	
	YapDatabaseFullTextSearch *fts =
	  [[YapDatabaseFullTextSearch alloc] initWithColumnNames:@[@"content"]
	                                                   block:block
	                                               blockType:blockType];
	
	[database registerExtension:fts withName:@"fts"];
	
	[connection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
		
		[transaction setObject:@"hello world"       forKey:@"key1" inCollection:nil];
		[transaction setObject:@"hello coffee shop" forKey:@"key2" inCollection:nil];
		[transaction setObject:@"hello laptop"      forKey:@"key3" inCollection:nil];
		[transaction setObject:@"hello work"        forKey:@"key4" inCollection:nil];
	}];
	
	[connection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
		
		__block NSUInteger count;
		
		// Find matches for: hello
		
		count = 0;
		[[transaction ext:@"fts"] enumerateKeysMatching:@"hello"
		                             withSnippetOptions:nil
		                                     usingBlock:
		    ^(NSString *snippet, NSString *collection, NSString *key, BOOL *stop) {
			
		//	NSLog(@"snippet: %@", snippet);
			count++;
		}];
		STAssertTrue(count == 4, @"Missing search results");
		
		// Find matches for: coffee
		
		YapDatabaseFullTextSearchSnippetOptions *options = [YapDatabaseFullTextSearchSnippetOptions new];
		options.startMatchText = @"[[";
		options.endMatchText   = @"]]";
		options.ellipsesText   = @"…";
		options.columnName     = @"content";
		options.numberOfTokens = 2;
		
		count = 0;
		[[transaction ext:@"fts"] enumerateKeysMatching:@"coffee"
		                             withSnippetOptions:options
		                                     usingBlock:
		    ^(NSString *snippet, NSString *collection, NSString *key, BOOL *stop) {
			
			NSLog(@"snippet: %@", snippet);
			count++;
		}];
		STAssertTrue(count == 1, @"Missing search results");
	}];
}

@end
