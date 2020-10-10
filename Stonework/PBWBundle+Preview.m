//
//  PBWBundle+Preview.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 10/10/2020.
//  Copyright © 2020 namedfork. All rights reserved.
//

#import "PBWBundle+Preview.h"

@implementation PBWBundle (Preview)

+ (NSURL*)URLForPreviewForBundleAtURL:(NSURL *)bundleURL {
    return [bundleURL URLByAppendingPathExtension:@".preview"];
}

+ (BOOL)writePreviewData:(NSData *)data forBundleAtURL:(NSURL *)bundleURL {
    NSURL *previewURL = [PBWBundle URLForPreviewForBundleAtURL:bundleURL];
    return [data writeToURL:previewURL atomically:NO];
}

- (NSData *)previewData {
    NSURL *previewURL = [PBWBundle URLForPreviewForBundleAtURL:self.bundleURL];
    return [NSData dataWithContentsOfURL:previewURL];
}

- (void)setPreviewData:(NSData *)previewData {
    [PBWBundle writePreviewData:previewData forBundleAtURL:self.bundleURL];
}

- (BOOL)hasPreview {
    NSURL *previewURL = [PBWBundle URLForPreviewForBundleAtURL:self.bundleURL];
    return [[NSFileManager defaultManager] fileExistsAtPath:previewURL.path];
}

@end
