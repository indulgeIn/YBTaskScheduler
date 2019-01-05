//
//  PhotoAlbumViewController.m
//  YBTaskSchedulerDemo
//
//  Created by 杨波 on 2019/1/4.
//  Copyright © 2019 杨波. All rights reserved.
//

#import "PhotoAlbumViewController.h"
#import <Photos/Photos.h>
#import "PhotoAlbumCell.h"
#import "YBTaskScheduler.h"

static NSString * const kReuseIdentifierOfPhotoAlbumCell = @"kReuseIdentifierOfPhotoAlbumCell";
static CGFloat kPadding = 5;
#define kPhotoAlbumCellLength (([UIScreen mainScreen].bounds.size.width - kPadding * 2) / 3)

@interface PhotoAlbumViewController ()<UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, copy) NSArray<PHAsset *> *dataArray;
@end

@implementation PhotoAlbumViewController {
    YBTaskScheduler *_scheduler;
}

#pragma mark - life cycle

- (void)dealloc {
    NSLog(@"释放：%@", self);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.dataArray = [self.class getPHAssets];
    
    //初始化任务调度器
    _scheduler = [YBTaskScheduler schedulerWithStrategy:YBTaskSchedulerStrategyPriority];
    //设置最大保持任务数量
    _scheduler.maxNumberOfTasks = 2;
    
    [self.view addSubview:self.collectionView];
}

#pragma mark - <UICollectionViewDataSource, UICollectionViewDelegate>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    /* 特别说明：
     此处很多逻辑应该放 Cell 里面，业务处理方式也并不是最优的，此处只是为了演示。
     */
    
    PhotoAlbumCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kReuseIdentifierOfPhotoAlbumCell forIndexPath:indexPath];
    cell.imgView.image = nil;
    
    cell.tag = indexPath.row;
    NSInteger tmpTag = cell.tag;
    
    PHAsset *phAsset = self.dataArray[indexPath.row];
    
    [_scheduler addTask:^{
        
        //获取相册图片
        PHImageRequestOptions *options = [PHImageRequestOptions new];
        options.synchronous = YES;
        options.resizeMode = PHImageRequestOptionsResizeModeFast;
        CGFloat imgL = (kPhotoAlbumCellLength - kPadding * 2) * [UIScreen mainScreen].scale;
        [[PHImageManager defaultManager] requestImageForAsset:phAsset targetSize:CGSizeMake(imgL, imgL) contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage *result, NSDictionary *info){
            BOOL downloadFinined = ![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue];
            if (downloadFinined && result) {
                
                //裁剪图片并加圆角
                CGFloat imgH = result.size.height, imgW = result.size.width;
                CGRect cutRect;
                if (imgH > imgW) {
                    CGFloat y = (imgH - imgW) / 2;
                    cutRect = CGRectMake(0, y, imgW, imgW);
                } else {
                    CGFloat x = (imgW - imgH) / 2;
                    cutRect = CGRectMake(x, 0, imgH, imgH);
                }
                CGImageRef cgImage = CGImageCreateWithImageInRect(result.CGImage, cutRect);
                UIImage *cutImage = [UIImage imageWithCGImage:cgImage];
                CGImageRelease(cgImage);
                UIGraphicsBeginImageContextWithOptions(cutImage.size, NO, 1);
                CGRect clipRect = CGRectMake(0, 0, cutImage.size.width, cutImage.size.height);
                [[UIBezierPath bezierPathWithRoundedRect:clipRect cornerRadius:20] addClip];
                [cutImage drawInRect:clipRect];
                UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                
                //显示
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (cell.tag == tmpTag) {
                        cell.imgView.image = image;
                    }
                });
            }
        }];
        
    }];

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

#pragma mark - getter

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
        layout.itemSize = CGSizeMake(kPhotoAlbumCellLength, kPhotoAlbumCellLength);
        layout.sectionInset = UIEdgeInsetsMake(kPadding, kPadding, kPadding, kPadding);
        layout.minimumLineSpacing = 0;
        layout.minimumInteritemSpacing = 0;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - [UIApplication sharedApplication].statusBarFrame.size.height - self.navigationController.navigationBar.bounds.size.height) collectionViewLayout:layout];
        [_collectionView registerNib:[UINib nibWithNibName:NSStringFromClass(PhotoAlbumCell.class) bundle:nil] forCellWithReuseIdentifier:kReuseIdentifierOfPhotoAlbumCell];
        _collectionView.backgroundColor = [UIColor whiteColor];
        _collectionView.alwaysBounceVertical = YES;
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
    }
    return _collectionView;
}

#pragma mark - data

+ (NSArray *)getPHAssets {
    NSMutableArray *resultArray = [NSMutableArray array];
    PHFetchResult *smartAlbumsFetchResult0 = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
    [smartAlbumsFetchResult0 enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(PHAssetCollection  *_Nonnull collection, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray<PHAsset *> *assets = [self getAssetsInAssetCollection:collection];
        [resultArray addObjectsFromArray:assets];
    }];
    
    PHFetchResult *smartAlbumsFetchResult1 = [PHAssetCollection fetchTopLevelUserCollectionsWithOptions:nil];
    [smartAlbumsFetchResult1 enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(PHAssetCollection * _Nonnull collection, NSUInteger idx, BOOL *stop) {
        NSArray<PHAsset *> *assets = [self getAssetsInAssetCollection:collection];
        [resultArray addObjectsFromArray:assets];
    }];
    
    return resultArray;
}

+ (NSArray *)getAssetsInAssetCollection:(PHAssetCollection *)assetCollection {
    NSMutableArray<PHAsset *> *arr = [NSMutableArray array];
    PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:assetCollection options:nil];
    [result enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(PHAsset *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.mediaType == PHAssetMediaTypeImage) {
            [arr addObject:obj];
        } else if (obj.mediaType == PHAssetMediaTypeVideo) {
            [arr addObject:obj];
        }
    }];
    return arr;
}


@end
