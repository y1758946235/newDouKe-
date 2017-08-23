//
//  LYEssenceAlbumViewController.m
//  LvYue
//
//  Created by KentonYu on 16/7/22.
//  Copyright © 2016年 OLFT. All rights reserved.
//

#import "FXBlurView.h"
#import "LYBlurImageCache.h"
#import "LYEssenceAlbumViewController.h"
#import "LYEssenceImageUploadViewController.h"
#import "LYEssenceTipViewController.h"
#import "LYHttpPoster.h"
#import "LYUserService.h"
#import "MBProgressHUD+NJ.h"
#import "MyDispositionCollectionViewCell.h"
#import "OriginalViewController.h"
#import "SDWebImageManager.h"
#import "AFNetworking.h"
#import "UIImageView+WebCache.h"

static NSString *const LYEssenceAlbumCollectionViewCellIdentity =
    @"photoCell";

@interface LYEssenceAlbumViewController () <
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    SDWebImageManagerDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewLayout *collectionViewLayout;

@property (nonatomic, strong) NSArray<NSDictionary *> *responseArray;
@property (nonatomic, strong) NSArray<NSString *> *imageURLArray;    // 图片URL
@property (nonatomic, strong) NSMutableArray<UIImage *> *imageArray; // 压缩数组
@property (nonatomic, assign) BOOL mySelf;                           // 是否是自己

@end

@implementation LYEssenceAlbumViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"reloadDisposition" object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setNav];
    self.view.backgroundColor = [UIColor whiteColor];

    // 监听是否需要刷新数据
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_loadData) name:@"reloadDisposition" object:nil];
 [self p_loadData];
}

- (void)setNav{
    self.title = @"我的相册";
    [self.navigationController.navigationBar setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor colorWithHexString:@"#424242"],UITextAttributeTextColor, [UIFont fontWithName:@"PingFangSC-Medium" size:18],UITextAttributeFont, nil]];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithHexString:@"#ffffff"];
    //导航栏返回按钮
    UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake(16, 38, 28, 14)];
    [button setTitleColor:[UIColor colorWithHexString:@"#424242"] forState:UIControlStateNormal];
    [button setTitle:@"返回" forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
    [button addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *back = [[UIBarButtonItem alloc]initWithCustomView:button];
    self.navigationItem.leftBarButtonItem = back;
    
    //导航栏充值记录按钮
    UIButton *edit = [[UIButton alloc]initWithFrame:CGRectMake(SCREEN_WIDTH-16-28, 38, 56, 14)];
    [edit setTitleColor:[UIColor colorWithHexString:@"#ff5252"] forState:UIControlStateNormal];
    if (_userId.length==0) {
        [edit setTitle:@"上传照片" forState:UIControlStateNormal];
    }
    
    edit.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
    [edit addTarget:self action:@selector(uploadPhoto) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *edited = [[UIBarButtonItem alloc]initWithCustomView:edit];
    self.navigationItem.rightBarButtonItem = edited;
    
    
}

- (void)goBack{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // 这两个数据源是懒加载的，所以刷新数据前清空
    self.imageURLArray = nil;
    self.imageArray    = nil;

   
}


#pragma mark - Pravite
- (void)p_loadData {

   // NSString *userId = [LYUserService sharedInstance].userID;
//     _userId = @"1000006";
    [LYHttpPoster postHttpRequestByPost:[NSString stringWithFormat:@"%@/mobile/user/getMyIndex", REQUESTHEADER]
        andParameter:
            @{
                @"userId": _userId
               
            }
        success:^(id successResponse) {

            if ([[NSString stringWithFormat:@"%@", successResponse[@"code"]] isEqualToString:@"200"]) {

                self.responseArray = successResponse[@"data"][@"userPhoto"];
                [self.collectionView reloadData];

                // 下载图片
                 [self p_downloadImage];

            } else {
                [MBProgressHUD showError:[NSString stringWithFormat:@"%@", successResponse[@"errorMsg"]]];
            }
        }
        andFailure:^(id failureResponse) {
            [MBProgressHUD showError:@"服务器繁忙,请重试"];
        }];
}



#pragma mark   ----把模胡、照片下载下来
- (void)p_downloadImage {
    [self.imageURLArray enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {

        NSURL *URL = [NSURL URLWithString:obj];

        // 自己看自己不需要模糊   已经打赏过也不需要模糊 1：打赏过  2：未打赏
       // if (!self.mySelf && [self.responseArray[idx][@"isBo"] integerValue] != 1) {
            // 读取缓存中的模糊相片
            UIImage *blurImage = [[LYBlurImageCache shareCache] objectForKey:URL.absoluteString];
            if (blurImage) {
                [self.imageArray replaceObjectAtIndex:idx withObject:blurImage];
                [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]]];
                return;
            }
        //}

        // 没缓存就下载
        [[SDWebImageManager sharedManager] downloadImageWithURL:URL options:SDWebImageRetryFailed progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {

            if (error) {
                return;
            }

            __block UIImage *returnImage = image;

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                // 自己看自己不需要模糊  已经打赏过也不需要模糊
                //if (!self.mySelf && [self.responseArray[idx][@"isBo"] integerValue] != 1) {
                    // 图片模糊
                    returnImage = [returnImage blurredImageWithRadius:100 iterations:20 tintColor:RGBACOLOR(0, 0, 0, 0.5)];

                    // 缓存模糊图片到内存
                    [[LYBlurImageCache shareCache] setObject:returnImage forKey:imageURL.absoluteString];
                //}

                dispatch_async(dispatch_get_main_queue(), ^{

                    [self.imageArray replaceObjectAtIndex:idx withObject:returnImage];

                    [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]]];
                });

            });

        }];
    }];
}

#pragma mark   ----上传相册
- (void)uploadPhoto {
    LYEssenceImageUploadViewController *vc = [LYEssenceImageUploadViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - UICollectionDelegate,UICollevtiondataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    return self.imageURLArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MyDispositionCollectionViewCell *cell =
        [collectionView dequeueReusableCellWithReuseIdentifier:
                            LYEssenceAlbumCollectionViewCellIdentity
                                                  forIndexPath:indexPath];
    //cell.imageViewM.image = self.imageArray[indexPath.row];
    [cell.imageViewM sd_setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@",self.imageURLArray[indexPath.row]]]];
    return cell;
}



#pragma mark   ----自己查看自己的相册

- (void)collectionView:(UICollectionView *)collectionView
    didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

    // 自己看自己则直接查看
//    if (self.mySelf) {
        OriginalViewController *vc = [[OriginalViewController alloc] init];
        vc.imageData               = self.responseArray; // 响应的字典
        vc.smallImage              = self.imageArray;    // 对应已经加载的 image 对象
       // vc.userId                  = [LYUserService sharedInstance].userID;
        vc.userId = @"1000006";
        vc.dismissBlock            = ^{
            [self viewWillAppear:YES];
        };
        [vc showImageWithIndex:indexPath.row andCount:self.imageArray.count];
       // return;
//    }

    // 已经打赏过，则直接查看这个照片
//    if ([self.responseArray[indexPath.row][@"isBo"] integerValue] == 1) {
//        OriginalViewController *vc = [[OriginalViewController alloc] init];
//        vc.imageData               = @[self.responseArray[indexPath.row]]; // 响应的字典
//        vc.smallImage              = @[self.imageArray[indexPath.row]];    // 对应已经加载的 image 对象
//        vc.userId                  = [LYUserService sharedInstance].userID;
//        [vc showImageWithIndex:0 andCount:1]; // 永远是单张查看
//        return;
//    }

//    LYEssenceTipViewController *vc = [[LYEssenceTipViewController alloc] init];
//    vc.userID                      = self.userId;
//    vc.bulrImageID                 = self.responseArray[indexPath.row][@"id"];
//    vc.bulrImageURL                = self.responseArray[indexPath.row][@"img_name"];
//    vc.tipAmount                   = [self.responseArray[indexPath.row][@"bounty"] integerValue];
//    vc.isReviewed                  = [self.responseArray[indexPath.row][@"isReview"] boolValue];
//    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark Getter

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = ({
            UICollectionView *collectionView = [[UICollectionView alloc]
                       initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - 64.f)
                collectionViewLayout:self.collectionViewLayout];
            collectionView.backgroundColor      = [UIColor whiteColor];
            collectionView.dataSource           = self;
            collectionView.delegate             = self;
            collectionView.alwaysBounceVertical = YES;
            [collectionView registerNib:[UINib nibWithNibName:
                                                   @"MyDispositionCollectionViewCell"
                                                       bundle:nil]
                forCellWithReuseIdentifier:LYEssenceAlbumCollectionViewCellIdentity];
            [self.view addSubview:collectionView];
            collectionView;
        });
    }
    return _collectionView;
}

- (UICollectionViewLayout *)collectionViewLayout {
    if (!_collectionViewLayout) {
        _collectionViewLayout = ({
            UICollectionViewFlowLayout *layout =
                [[UICollectionViewFlowLayout alloc] init];
            layout.itemSize                = CGSizeMake(SCREEN_WIDTH / 3 - 7, SCREEN_WIDTH / 3 - 7);
            layout.sectionInset            = UIEdgeInsetsMake(5, 5, 5, 5);
            layout.minimumInteritemSpacing = 5;
            layout.minimumLineSpacing      = 5;
            layout;
        });
    }
    return _collectionViewLayout;
}

- (NSArray<NSString *> *)imageURLArray {
    if (!_imageURLArray) {
        NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:self.responseArray.count];
        [self.responseArray enumerateObjectsUsingBlock:^(NSDictionary *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            [array addObject:[NSString stringWithFormat:@"%@%@", IMAGEHEADER, obj[@"img_name"]]];
        }];
        _imageURLArray = [array copy];
    }
    return _imageURLArray;
}

- (NSMutableArray<UIImage *> *)imageArray {
    if (!_imageArray) {
        _imageArray = [[NSMutableArray alloc] initWithCapacity:self.imageURLArray.count];
        NSLog(@"count:%@", @(self.imageURLArray.count));
        for (NSInteger flag = 0; flag < self.imageURLArray.count; flag++) {
            NSLog(@"flag:%@", @(flag));
           
          // [_imageArray addObject:[UIImage imageNamed:@"PlaceImage"]];
        }
    }
    return _imageArray;
}

- (BOOL)mySelf {
    BOOL mySelf = (self.userId.length == 0 || [self.userId isEqualToString:[LYUserService sharedInstance].userID]);
    return mySelf;
}

@end
