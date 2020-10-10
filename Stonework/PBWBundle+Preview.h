//
//  PBWBundle+Preview.h
//  Stonework
//
//  Created by Jesús A. Álvarez on 10/10/2020.
//  Copyright © 2020 namedfork. All rights reserved.
//

#import "PBWBundle.h"

NS_ASSUME_NONNULL_BEGIN

@interface PBWBundle (Preview)

@property (nonatomic, readonly) BOOL hasPreview;
@property (nonatomic, readwrite, nullable) NSData *previewData;

+ (BOOL)writePreviewData:(NSData*)data forBundleAtURL:(NSURL*)bundleURL;

@end

NS_ASSUME_NONNULL_END
