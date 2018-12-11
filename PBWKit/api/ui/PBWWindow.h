//
//  PBWWindow.h
//  Stonework
//
//  Created by Jesús A. Álvarez on 04/11/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PBWObject.h"
#import "PBWGraphics.h"

NS_ASSUME_NONNULL_BEGIN

@class PBWLayer;

@interface PBWWindow : PBWObject
{
@public
    PBWLayer *_rootLayer;
    GColor _backgroundColor;
    BOOL dirty;
}

@property (nonatomic, retain) PBWLayer *rootLayer;
@property (nonatomic, assign) GColor backgroundColor;
@property (nonatomic, assign) BOOL loaded;
@property (nonatomic, assign) uint32_t loadHandler;
@property (nonatomic, assign) uint32_t appearHandler;
@property (nonatomic, assign) uint32_t disapperHandler;
@property (nonatomic, assign) uint32_t unloadHandler;
@property (nonatomic, assign) uint32_t userData;
@property (nonatomic, assign) uint32_t clickConfigProvider;
@property (nonatomic, assign) uint32_t clickConfigProviderContext;

- (void)markDirty;
- (void)didLoad;
- (void)didAppear;
- (void)didDisappear;
- (void)didUnload;

@end

NS_ASSUME_NONNULL_END
