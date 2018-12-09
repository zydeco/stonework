//
//  NSFileManager+ExtendedAttributes.h
//
//  Created by Jesús A. Álvarez on 2008-12-17.
//  Copyright 2008-2018 namedfork.net. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sys/xattr.h>

extern NSString * XAFinderInfo;
extern NSString * XAFinderComment;
extern NSString * XAResourceFork;

typedef enum XAMode {
    XAAnyMode = 0,
    XACreate = XATTR_CREATE,
    XAReplace = XATTR_REPLACE,
} XAMode;

@interface NSFileManager (ExtendedAttributes)
- (NSArray*)extendedAttributeNamesAtPath:(NSString*)path traverseLink:(BOOL)follow error:(NSError**)err;
- (BOOL)hasExtendedAttribute:(NSString*)name atPath:(NSString*)path traverseLink:(BOOL)follow error:(NSError**)err;
- (NSData*)extendedAttribute:(NSString*)name atPath:(NSString*)path traverseLink:(BOOL)follow error:(NSError**)err;
// extendedAttributesAtPath dictionary DOES NOT include resource fork, as it can be quite big
// and resource forks are inherent to the Macintosh, not a mere attribute that can be lost
- (NSDictionary*)extendedAttributesAtPath:(NSString*)path traverseLink:(BOOL)follow error:(NSError**)err;
- (BOOL)setExtendedAttribute:(NSString*)name value:(NSData*)value atPath:(NSString*)path traverseLink:(BOOL)follow mode:(XAMode)mode error:(NSError**)err;
- (BOOL)removeExtendedAttribute:(NSString*)name atPath:(NSString*)path traverseLink:(BOOL)follow error:(NSError**)err;
// overwrite will delete attributes not in dictionary, except resource fork
- (BOOL)setExtendedAttributes:(NSDictionary*)attrs atPath:(NSString*)path traverseLink:(BOOL)follow overwrite:(BOOL)overwrite error:(NSError**)err;
@end
