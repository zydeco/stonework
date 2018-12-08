//
//  PBWObject.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 04/11/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "PBWObject.h"
#import "PBWRuntime.h"

@implementation PBWObject

- (instancetype)initWithRuntime:(PBWRuntime *)rt {
    if (self = [super init]) {
        _tag = [rt addObject:self];
        _runtime = rt;
    }
    return self;
}

- (void)destroy {
    [_runtime.objects removeObjectForKey:@(_tag)];
}

@end
