//
//  PBWManager.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 31/10/2020.
//  Copyright © 2020 namedfork. All rights reserved.
//

#import "PBWManager.h"
#import "PBWBundle.h"

@implementation PBWManager
{
    NSString *appGroup;
}

+ (instancetype)defaultManager {
    static dispatch_once_t onceToken;
    static PBWManager *sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [PBWManager new];
    });
    return sharedInstance;
}

- (instancetype)init {
    if ((self = [super init])) {
#if TARGET_OS_WATCH
        // watch extension can't share with app
        appGroup = nil;
        _documentsURL = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject;
        _sharedUserDefaults = [NSUserDefaults standardUserDefaults];
#else
        appGroup = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"ALTAppGroups"] firstObject];
        _documentsURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:appGroup];
        _sharedUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:appGroup];
#endif
    }
    return self;
}

- (NSArray<PBWBundle *> *)availableWatchfaces {
    return [PBWBundle bundlesAtURL:self.documentsURL];
}

@end
