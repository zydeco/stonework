//
//  NSFileManager+ExtendedAttributes.m
//
//  Created by Jesús A. Álvarez on 2008-12-17.
//  Copyright 2008-2018 namedfork.net. All rights reserved.
//

#import "NSFileManager+ExtendedAttributes.h"
#import <string.h>

NSString * XAFinderInfo = @XATTR_FINDERINFO_NAME;
NSString * XAFinderComment = @"com.apple.metadata:kMDItemFinderComment";
NSString * XAResourceFork = @XATTR_RESOURCEFORK_NAME;

@implementation NSFileManager (ExtendedAttributes)

- (NSArray*)extendedAttributeNamesAtPath:(NSString*)path traverseLink:(BOOL)follow error:(NSError**)err {
    int flags = follow? 0 : XATTR_NOFOLLOW;
    
    // get size of name list
    ssize_t nameBuffLen = listxattr([path fileSystemRepresentation], NULL, 0, flags);
    if (nameBuffLen == -1) {
        if (err) *err = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:
            [NSDictionary dictionaryWithObjectsAndKeys:
             [NSString stringWithUTF8String:strerror(errno)], @"error",
             @"listxattr", @"function",
             path, @":path",
             [NSNumber numberWithBool:follow], @":traverseLink",
             nil]
            ];
        return nil;
    } else if (nameBuffLen == 0) return [NSArray array];
    
    // get name list
    NSMutableData *nameBuff = [NSMutableData dataWithLength:nameBuffLen];
    listxattr([path fileSystemRepresentation], [nameBuff mutableBytes], nameBuffLen, flags);
    
    // convert to array
    NSMutableArray * names = [NSMutableArray arrayWithCapacity:5];
    char *nextName, *endOfNames = [nameBuff mutableBytes] + nameBuffLen;
    for(nextName = [nameBuff mutableBytes]; nextName < endOfNames; nextName += 1+strlen(nextName))
        [names addObject:[NSString stringWithUTF8String:nextName]];
    return [NSArray arrayWithArray:names];
}

- (BOOL)hasExtendedAttribute:(NSString*)name atPath:(NSString*)path traverseLink:(BOOL)follow error:(NSError**)err {
    int flags = follow? 0 : XATTR_NOFOLLOW;
    
    // get size of name list
    ssize_t nameBuffLen = listxattr([path fileSystemRepresentation], NULL, 0, flags);
    if (nameBuffLen == -1) {
        if (err) *err = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:
            [NSDictionary dictionaryWithObjectsAndKeys:
             [NSString stringWithUTF8String:strerror(errno)], @"error",
             @"listxattr", @"function",
             path, @":path",
             [NSNumber numberWithBool:follow], @":traverseLink",
             nil]
            ];
        return NO;
    } else if (nameBuffLen == 0) return NO;
    
    // get name list
    NSMutableData *nameBuff = [NSMutableData dataWithLength:nameBuffLen];
    listxattr([path fileSystemRepresentation], [nameBuff mutableBytes], nameBuffLen, flags);
    
    // find our name
    NSMutableArray * names = [NSMutableArray arrayWithCapacity:5];
    char *nextName, *endOfNames = [nameBuff mutableBytes] + nameBuffLen;
    for(nextName = [nameBuff mutableBytes]; nextName < endOfNames; nextName += 1+strlen(nextName))
        if (strcmp(nextName, [name UTF8String]) == 0) return YES;
    return NO;
}

- (NSData*)extendedAttribute:(NSString*)name atPath:(NSString*)path traverseLink:(BOOL)follow error:(NSError**)err {
    int flags = follow? 0 : XATTR_NOFOLLOW;
    // get length
    ssize_t attrLen = getxattr([path fileSystemRepresentation], [name UTF8String], NULL, 0, 0, flags);
    if (attrLen == -1) {
        if (err) *err = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:
                         [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSString stringWithUTF8String:strerror(errno)], @"error",
                          @"getxattr", @"function",
                          name, @":name",
                          path, @":path",
                          [NSNumber numberWithBool:follow], @":traverseLink",
                          nil]
                         ];
        return nil;
    }
    
    // get attribute data
    NSMutableData * attrData = [NSMutableData dataWithLength:attrLen];
    getxattr([path fileSystemRepresentation], [name UTF8String], [attrData mutableBytes], attrLen, 0, flags);
    return attrData;
}

- (NSDictionary*)extendedAttributesAtPath:(NSString*)path traverseLink:(BOOL)follow error:(NSError**)err {
    // get names
    NSArray * names = [self extendedAttributeNamesAtPath:path traverseLink:follow error:err];
    if (names == nil) return nil;
    
    NSMutableDictionary * attrs = [NSMutableDictionary dictionaryWithCapacity:[names count]];
    // get attributes
    for(NSString * name in names) if (![name isEqualToString:XAResourceFork]) {
        NSData * attr = [self extendedAttribute:name atPath:path traverseLink:follow error:err];
        if (attr == nil) return nil;
        [attrs setObject:attr forKey:name];
    }
    
    return [NSDictionary dictionaryWithDictionary:attrs];
}

- (BOOL)setExtendedAttribute:(NSString*)name value:(NSData*)value atPath:(NSString*)path traverseLink:(BOOL)follow mode:(XAMode)mode error:(NSError**)err {
    int flags = (follow? 0 : XATTR_NOFOLLOW) | mode;
    if (0 == setxattr([path fileSystemRepresentation], [name UTF8String], [value bytes], [value length], 0, flags)) return YES;
    // error
    if (err) *err = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:
                     [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSString stringWithUTF8String:strerror(errno)], @"error",
                      @"setxattr", @"function",
                      name, @":name",
                      [NSNumber numberWithUnsignedInteger:[value length]], @":value.length",
                      path, @":path",
                      [NSNumber numberWithBool:follow], @":traverseLink",
                      [NSNumber numberWithInt:mode], @":mode",
                      nil]
                     ];
    return NO;
}

- (BOOL)removeExtendedAttribute:(NSString*)name atPath:(NSString*)path traverseLink:(BOOL)follow error:(NSError**)err {
    int flags = (follow? 0 : XATTR_NOFOLLOW);
    if (0 == removexattr([path fileSystemRepresentation], [name UTF8String], flags)) return YES;
    // error
    if (err) *err = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:
                     [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSString stringWithUTF8String:strerror(errno)], @"error",
                      @"removexattr", @"function",
                      name, @":name",
                      path, @":path",
                      [NSNumber numberWithBool:follow], @":traverseLink",
                      nil]
                     ];
    return NO;
}

- (BOOL)setExtendedAttributes:(NSDictionary*)attrs atPath:(NSString*)path traverseLink:(BOOL)follow overwrite:(BOOL)overwrite error:(NSError**)err {
    NSArray * oldNames = [self extendedAttributeNamesAtPath:path traverseLink:follow error:err];
    if (oldNames == nil) return NO;
    NSArray * newNames = [attrs allKeys];
    BOOL success = YES;
    
    // remove attributes
    if (overwrite) {
        NSMutableSet * attrsToRemove = [NSMutableSet setWithArray:oldNames];
        [attrsToRemove minusSet:[NSSet setWithArray:newNames]];
        [attrsToRemove removeObject:XAResourceFork];
        for(NSString * name in attrsToRemove)
            if (NO == [self removeExtendedAttribute:name atPath:path traverseLink:follow error:err]) success = NO;
        if (success == NO) return NO;
    }   
    
    // set attributes
    for (NSString * name in newNames)
        if (NO == [self setExtendedAttribute:name value:[attrs objectForKey:name] atPath:path traverseLink:follow mode:0 error:err]) success = NO;
    
    return success;
}

@end
