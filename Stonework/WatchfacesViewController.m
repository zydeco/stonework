//
//  WatchfacesViewController.m
//  Stonework
//
//  Created by Jesús A. Álvarez on 05/12/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#import "WatchfacesViewController.h"
#import "WatchfaceCollectionViewCell.h"
#import "PBWBundle.h"

@interface WatchfacesViewController ()

@end

@implementation WatchfacesViewController
{
    NSArray<PBWBundle*> *watchfaces;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Do any additional setup after loading the view.
    watchfaces = [self availableWathcfaces];
}

- (NSArray<PBWBundle*>*)availableWathcfaces {
    NSURL *builtInWatchfacesURL = [[NSBundle mainBundle].resourceURL URLByAppendingPathComponent:@"Faces" isDirectory:YES];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *documentsURL = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject;
    return [[PBWBundle bundlesAtURL:builtInWatchfacesURL] arrayByAddingObjectsFromArray:[PBWBundle bundlesAtURL:documentsURL]];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

@end
