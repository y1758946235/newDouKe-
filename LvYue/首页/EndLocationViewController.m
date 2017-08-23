//
//  EndLocationViewController.m
//  LvYue
//
//  Created by 広有射怪鸟事 on 15/10/21.
//  Copyright © 2015年 OLFT. All rights reserved.
//

#import "EndLocationViewController.h"
#import "DistrictModel.h"
#import "LYHttpPoster.h"
#import "LYUserService.h"
#import "MBProgressHUD+NJ.h"
#import "SearchNearbyViewController.h"
#import "pchFile.pch"

@interface EndLocationViewController ()<UITableViewDataSource,UITableViewDelegate>{
    changeInfoVC *revise;
    SearchNearbyViewController *searVC;
    perfactInfoVC *perinfoVC;
}

@property (nonatomic,strong) NSMutableArray *locationArray;
@property (nonatomic,strong)DistrictModel *model;
@property (nonatomic,strong) UITableView *tableV;

@end

@implementation EndLocationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"选择区域";
    
    self.tableV = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, kMainScreenWidth, kMainScreenHeight)];
    self.tableV.delegate = self;
    self.tableV.dataSource = self;
    self.tableV.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:self.tableV];
    self.locationArray = [[NSMutableArray alloc] init];
    [self setNav];
    [self getDataFromWeb];
}

- (void)setNav{
    //导航栏返回按钮
    UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake(16, 38, 28, 14)];
    [button setTitleColor:[UIColor colorWithHexString:@"#424242"] forState:UIControlStateNormal];
    [button setTitle:@"返回" forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
    [button addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *back = [[UIBarButtonItem alloc]initWithCustomView:button];
    self.navigationItem.leftBarButtonItem = back;
    
}
- (void)goBack{
    
    [self.navigationController popViewControllerAnimated:YES];
    
    
}

- (void)getDataFromWeb{
    [MBProgressHUD showMessage:nil  toView:self.view];
    
    [LYHttpPoster postHttpRequestByPost:[NSString stringWithFormat:@"%@/mobile/cache/getDistrict",REQUESTHEADER] andParameter:@{} success:^(id successResponse) {
       // MLOG(@"结果:%@",successResponse);
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        if ([[NSString stringWithFormat:@"%@",successResponse[@"code"]] isEqualToString:@"200"]) {
            [self.locationArray removeAllObjects];
            for (NSDictionary *dict in successResponse[@"data"]) {
                self.model = [[DistrictModel alloc] initWithDict:dict];
                if ([self.model.parent_id integerValue]==[self.countryId integerValue]) {
                    [self.locationArray addObject:self.model];
                }
            }
            [self.tableV reloadData];
        } else {
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            [MBProgressHUD showError:[NSString stringWithFormat:@"%@",successResponse[@"errorMsg"]]];
        }
    } andFailure:^(id failureResponse) {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        [MBProgressHUD showError:@"服务器繁忙,请重试"];
    }];
}

#pragma mark table代理方法

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0) {
        return 30;
    }
    else if(indexPath.row == 2){
        return 20;
    }
    return 48;
}

//设置cell的数目
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.locationArray.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.row>2) {
        DistrictModel *model = self.locationArray[indexPath.row-3];
        for (UIViewController *controller in self.navigationController.viewControllers) {
        if ([controller isKindOfClass:[changeInfoVC class]]) {
             revise =(changeInfoVC *)controller;
            // revise.placee = [NSString stringWithFormat:@"%@ %@ %@",self.place,self.preLoc,model.name];
            revise.placee = [NSString stringWithFormat:@"%@ %@",self.place,model.name];
             revise.placeId = [NSString stringWithFormat:@"%@,%@,%@",self.placeId,self.countryId,model.level];
            [self postRequest:@"changeInfoVC"];
            //[self.navigationController popToViewController:revise animated:YES];
        }
            if ([controller isKindOfClass:[SearchNearbyViewController class]]) {
                searVC =(SearchNearbyViewController *)controller;
                searVC.placee = [NSString stringWithFormat:@"%@ %@",self.place,model.name];
                searVC.placeId = [NSString stringWithFormat:@"%@,%@,%@",self.placeId,self.countryId,model.level];
       [[NSNotificationCenter defaultCenter]postNotificationName:@"currentSearchNearbyViewControllerplace" object:nil userInfo:nil];
                [self.navigationController popToViewController:searVC animated:YES];
            }
            
            if ([controller isKindOfClass:[perfactInfoVC class]]) {
                perinfoVC =(perfactInfoVC *)controller;
                perinfoVC.placee = [NSString stringWithFormat:@"%@ %@",self.place,model.name];
                perinfoVC.placeId = [NSString stringWithFormat:@"%@,%@,%@",self.placeId,self.countryId,model.level];
          [[NSNotificationCenter defaultCenter]postNotificationName:@"currentPerfactInfoVCplace" object:nil userInfo:nil];
                [self.navigationController popToViewController:perinfoVC animated:YES];
            }
            
    }
    }
}

#pragma mark  ----发送修改地址的请求
- (void)postRequest:(NSString *)VCName{
    NSString *userId = [[NSUserDefaults standardUserDefaults]objectForKey:@"userId"];
    [LYHttpPoster postHttpRequestByPost:[NSString stringWithFormat:@"%@/mobile/user/updatePersonalInfo",REQUESTHEADER] andParameter:@{@"userId":userId,@"userProvince":self.placeId,@"userCity":self.countryId,@"userDistrict":self.model.level} success:^(id successResponse) {
        MLOG(@"结果:%@",successResponse);
        [MBProgressHUD hideHUD];
        if ([[NSString stringWithFormat:@"%@",successResponse[@"code"]] isEqualToString:@"200"]) {
            
            [MBProgressHUD showSuccess:@"地址修改成功"];
            if ([VCName isEqualToString:@"changeInfoVC"]) {
                [self performSelector:@selector(popToVRevise) withObject:self afterDelay:1];
                
            }
//            else if ([VCName isEqualToString:@"SearchNearbyViewController"]){
//                [self performSelector:@selector(popTosSearVC) withObject:self afterDelay:1];
//            }else{
//                 [self performSelector:@selector(popToPerinfoVC) withObject:self afterDelay:1];
//            }

           
            
        } else {
            [MBProgressHUD hideHUD];
            [MBProgressHUD showError:[NSString stringWithFormat:@"%@",successResponse[@"errorMsg"]]];
        }
    } andFailure:^(id failureResponse) {
        [MBProgressHUD hideHUD];
        [MBProgressHUD showError:@"服务器繁忙,请重试"];
    }];
    
    
    
}

- (void)popToVRevise{
    
    [self.navigationController popToViewController:revise animated:YES];
}

- (void)popTosSearVC{
    [self.navigationController popToViewController:searVC animated:YES];
}
- (void)popToPerinfoVC{
    [self.navigationController popToViewController:perinfoVC animated:YES];
}
//创建每个cell
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"cellIdentifier";
    //分割用的cell
    if (indexPath.row == 0) {
        UITableViewCell *cell = [[UITableViewCell alloc] init];
        [cell setBackgroundColor:UIColorWithRGBA(234, 234, 234, 1)];
        cell.textLabel.text = @"当前市";
        cell.textLabel.font = [UIFont boldSystemFontOfSize:14];
        cell.textLabel.textColor = [UIColor colorWithHexString:@"#424242"];
        cell.textLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
       cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    //已选中的地区
    else if(indexPath.row == 1) {
        UITableViewCell *cell = [[UITableViewCell alloc] init];
        cell.textLabel.text = _preLoc;
        cell.textLabel.textColor = [UIColor colorWithHexString:@"#757575"];
        cell.textLabel.font = [UIFont fontWithName:@"PingFangSC-Light" size:14];
        //设置已选地区label
        UILabel *selectedLabel = [[UILabel alloc]initWithFrame:CGRectMake(kMainScreenWidth - 100, 0, 80, 48)];
        selectedLabel.textColor = UIColorWithRGBA(158, 158, 158, 1);
        selectedLabel.text = @"已选地区";
        selectedLabel.textAlignment = NSTextAlignmentRight;
        selectedLabel.font = [UIFont systemFontOfSize:15];
        [cell addSubview:selectedLabel];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.userInteractionEnabled = NO;
        return cell;
    }
    else if (indexPath.row == 2){
        UITableViewCell *cell = [[UITableViewCell alloc] init];
        [cell setBackgroundColor:UIColorWithRGBA(234, 234, 234, 1)];
        cell.textLabel.text = @"所有地区";
        cell.textLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        cell.textLabel.textColor = [UIColor colorWithHexString:@"#424242"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    else{
        //所有地区
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        if (self.locationArray.count) {
            [cell setBackgroundColor:[UIColor redColor]];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] init];
            }
            UIView *lineView = [[UIView alloc]initWithFrame:CGRectMake(0, 47, kMainScreenWidth,1)];
            lineView.backgroundColor = UIColorWithRGBA(234, 234, 234, 1);
            [cell addSubview:lineView];
            self.model = self.locationArray[indexPath.row-3];
            cell.textLabel.text = self.model.name;
            cell.textLabel.textColor = [UIColor colorWithHexString:@"#757575"];
            cell.textLabel.font = [UIFont fontWithName:@"PingFangSC-Light" size:14];
        }
        
        return cell;
    }
}

@end
