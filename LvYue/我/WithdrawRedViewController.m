//
//  WithdrawRedViewController.m
//  LvYue
//
//  Created by 広有射怪鸟事 on 15/12/15.
//  Copyright © 2015年 OLFT. All rights reserved.
//

#import "WithdrawRedViewController.h"
#import "WithdrawRedTableViewCell.h"
#import "WithDrawRedNumViewController.h"
#import "LYHttpPoster.h"
#import "LYUserService.h"
#import "MBProgressHUD+NJ.h"

@interface WithdrawRedViewController ()<UITableViewDataSource,UITableViewDelegate,UIActionSheetDelegate>
{
    UITableView *tableV;
    NSString *payType;//1为支付宝，2为微信支付
    NSString *payImage;
}

@end

@implementation WithdrawRedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    payType = @"1";
    payImage = @"alipay2";
    
    self.title = @"提现";
    
    [self createView];
    
    [self getData];
    
}

- (void)getData{
    [LYHttpPoster postHttpRequestByPost:[NSString stringWithFormat:@"%@/mobile/user/getDetailInfo",REQUESTHEADER] andParameter:@{@"id":[NSString stringWithFormat:@"%@",[LYUserService sharedInstance].userID]} success:^(id successResponse) {
        MLOG(@"结果:%@",successResponse);
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        if ([[NSString stringWithFormat:@"%@",successResponse[@"code"]] isEqualToString:@"200"]) {
            self.hongdou = [NSString stringWithFormat:@"%@",successResponse[@"data"][@"user"][@"hongdou"]];
            [tableV reloadData];
        } else {
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            [MBProgressHUD showError:[NSString stringWithFormat:@"%@",successResponse[@"msg"]]];
        }
    } andFailure:^(id failureResponse) {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        [MBProgressHUD showError:@"服务器繁忙,请重试"];
    }];
}

- (void)createView{
    tableV = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, kMainScreenWidth, kMainScreenHeight) style:UITableViewStyleGrouped];
    tableV.delegate = self;
    tableV.dataSource = self;
    [self.view addSubview:tableV];
}

- (void)nextStep{
    WithDrawRedNumViewController *num = [[WithDrawRedNumViewController alloc] init];
    num.alipay = self.alipay;
    num.weixin = self.weixin;
    num.payType = payType;
    num.hongdou = self.hongdou;
    [self.navigationController pushViewController:num animated:YES];
}

#pragma mark tableview代理

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0) {
        return 133;
    }
    else{
        return 70;
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        return 10;
    }
    else{
        return 20;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (section == 1) {
        return @"提现方式";
    }
    else{
        return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
    if (section == 1) {
        return @"100颗红豆=1元人民币";
    }
    else{
        return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    WithdrawRedTableViewCell *cell = [WithdrawRedTableViewCell cellWithTableView:tableView andIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (indexPath.section == 0) {
        cell.redBeanNumLabel.text = self.hongdou;
        return cell;
    }
    else{
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"pay"];
        cell.imageView.image = [UIImage imageNamed:payImage];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        if ([payType isEqualToString:@"1"]) {
            cell.textLabel.text = @"支付宝提现";
        }
        else if ([payType isEqualToString:@"2"]){
            cell.textLabel.text = @"微信支付提现";
        }
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    if (section == 1) {
        return 300;
    }
    return 20;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 1) {
        UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"支付宝",@"微信支付", nil];
        [action showInView:self.view];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    UIView *foot = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kMainScreenWidth, 200)];

    UIButton *sureBtn = [[UIButton alloc] initWithFrame:CGRectMake(10, 50, kMainScreenWidth - 20, 50)];
    [sureBtn setTitle:@"下一步" forState:UIControlStateNormal];
    [sureBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [sureBtn addTarget:self action:@selector(nextStep) forControlEvents:UIControlEventTouchUpInside];
    [sureBtn setBackgroundColor:[UIColor colorWithRed:29/255.0 green:189/255.0 blue:159/255.0 alpha:1]];
    sureBtn.layer.cornerRadius = 4;
    [sureBtn.titleLabel setFont:[UIFont systemFontOfSize:14.0]];
    [foot addSubview:sureBtn];
    
    
    if (section == 1) {
        return foot;
    }
    return nil;
}

#pragma mark actionsheet代理

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 0) {
        payType = @"1";
        payImage = @"alipay2";
        [tableV reloadData];
    }
    else if (buttonIndex == 1){
        payType = @"2";
        payImage = @"weixin-2";
        [tableV reloadData];
    }
}

@end
