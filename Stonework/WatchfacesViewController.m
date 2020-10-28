//
//  WatchfacesViewController.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 05/12/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "WatchfacesViewController.h"
#import "WatchfaceCollectionViewCell.h"
#import "WatchfaceDetailViewController.h"
#import "StoreViewController.h"
#import "PBWBundle.h"
#import "AppDelegate.h"

#if TARGET_OS_MACCATALYST
@interface NSObject (AppKit)
- (id)sharedApplication;
- (NSArray<id>*)windows;
- (void)setMinSize:(CGSize)size;
@end
#endif

@interface WatchfacesViewController ()

@end

@implementation WatchfacesViewController
{
    NSMutableArray<PBWBundle*> *watchfaces;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    watchfaces = [self availableWathcfaces].mutableCopy;
    [self.collectionView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
#if TARGET_OS_MACCATALYST
    id app = [NSClassFromString(@"NSApplication") sharedApplication];
    id window = [[app windows] lastObject];
    if ([window respondsToSelector:@selector(setMinSize:)]) {
        [window setMinSize:CGSizeMake(320.0, 480.0)];
    }
#endif
}
    
- (NSArray<PBWBundle*>*)availableWathcfaces {
    return [AppDelegate sharedInstance].availableWatchfaces;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSIndexPath *selectedIndexPath = self.collectionView.indexPathsForSelectedItems.lastObject;
    if ([segue.destinationViewController isKindOfClass:[WatchfaceDetailViewController class]] && selectedIndexPath) {
        WatchfaceDetailViewController *detailViewController = (WatchfaceDetailViewController*)segue.destinationViewController;
        PBWBundle *selectedWatchface = watchfaces[selectedIndexPath.item-1];
        detailViewController.watchfaceBundle = selectedWatchface;
        // copy to group
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *appGroup = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"ALTAppGroups"] firstObject];
        NSURL *containerURL = [fileManager containerURLForSecurityApplicationGroupIdentifier:appGroup];
        NSURL *destinationURL = [containerURL URLByAppendingPathComponent:@"widget.pbw" isDirectory:NO];
        [fileManager removeItemAtURL:destinationURL error:nil];
        [fileManager copyItemAtURL:selectedWatchface.bundleURL toURL:destinationURL error:nil];
    } if ([segue.destinationViewController isKindOfClass:[StoreViewController class]] && [sender isKindOfClass:[PBWBundle class]]) {
        StoreViewController *storeViewController = (StoreViewController*)segue.destinationViewController;
        PBWBundle *watchfaceBundle = (PBWBundle*)sender;
        storeViewController.landingURL = [StoreViewController URLForSearchingStoreWithUUID:watchfaceBundle.UUID];
    }
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 1 + watchfaces.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == 0) {
        return [collectionView dequeueReusableCellWithReuseIdentifier:@"getWatchfaces" forIndexPath:indexPath];
    }
    WatchfaceCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"watchface" forIndexPath:indexPath];
    cell.watchfaceBundle = watchfaces[indexPath.item-1];
    return cell;
}

#pragma mark <UICollectionViewDelegate>


- (UIContextMenuConfiguration *)collectionView:(UICollectionView *)collectionView contextMenuConfigurationForItemAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point API_AVAILABLE(ios(13.0)) {
    NSUInteger watchfaceIndex = indexPath.item - 1;
    PBWBundle *watchfaceBundle = watchfaces[watchfaceIndex];
    return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:nil actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
        UIAction *shareAction = [UIAction actionWithTitle:@"Share" image:[UIImage systemImageNamed:@"square.and.arrow.up"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[watchfaceBundle.bundleURL] applicationActivities:nil];
            [self presentViewController:activityViewController animated:YES completion:nil];
        }];
        UIAction *findInStoreAction = [UIAction actionWithTitle:@"Find in Store" image:[UIImage systemImageNamed:@"cart"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            [self performSegueWithIdentifier:@"store" sender:watchfaceBundle];
        }];
        UIAction *deleteAction = [UIAction actionWithTitle:@"Delete" image:[UIImage systemImageNamed:@"trash"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            [WatchfacesViewController confirmDeletionOfWatchface:watchfaceBundle fromViewController:self completion:^(NSError * _Nonnull error) {
                if (error == nil) {
                    [self->watchfaces removeObjectAtIndex:watchfaceIndex];
                    [collectionView deleteItemsAtIndexPaths:@[indexPath]];
                }
            }];
        }];
        deleteAction.attributes = UIMenuElementAttributesDestructive;
        return [UIMenu menuWithTitle:@"" children:@[
            shareAction, findInStoreAction, deleteAction
        ]];
    }];
}

+ (void)confirmDeletionOfWatchface:(PBWBundle*)watchfaceBundle fromViewController:(UIViewController*)viewController completion:(void(^)(NSError *error))completion {
    NSString *watchfaceName = watchfaceBundle.longName ?: watchfaceBundle.shortName ?: watchfaceBundle.bundleURL.lastPathComponent;
    NSString *title = [NSString stringWithFormat:@"Do you want to delete watchface “%@”?", watchfaceName];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:@"This action cannot be undone." preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        NSError *deleteError = nil;
        if ([[NSFileManager defaultManager] removeItemAtURL:watchfaceBundle.bundleURL error:&deleteError]) {
            completion(nil);
        } else {
            UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"Error deleting watchface" message:deleteError.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
            [errorAlert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [viewController presentViewController:errorAlert animated:YES completion:^{
                completion(deleteError);
            }];
        }
    }]];
    [viewController presentViewController:alert animated:YES completion:nil];
}

@end
