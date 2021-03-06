//
//  BuyCoinViewController.m
//  LvYue
//
//  Created by KFallen on 16/6/30.
//  Copyright © 2016年 OLFT. All rights reserved.
//

#import "BuyCoinViewController.h"
#import "WhatsRedViewController.h"
#import "MBProgressHUD+NJ.h"
#import <AlipaySDK/AlipaySDK.h>
#import "WXModel.h"
#import "WXApi.h"
#import "LYHttpPoster.h"
#import "LYUserService.h"

//苹果内购
#import "ConstPriceEnum.h"
#import <StoreKit/StoreKit.h>


@interface BuyCoinViewController ()<UITextFieldDelegate,SKPaymentTransactionObserver,SKProductsRequestDelegate>{
#warning 未完成
    NSString *_selectProductID; //选中商品的产品ID
    NSString *_coinNum; //充值金币数
}
@property (weak, nonatomic) IBOutlet UITextField *inputCoin;        //金币数目
@property (weak, nonatomic) IBOutlet UIButton *appleBuyBtn;         //苹果购买按钮    tag = 101
@property (weak, nonatomic) IBOutlet UIButton *alipayBtn;           //支付宝按钮      tag = 102
@property (weak, nonatomic) IBOutlet UIButton *wxpayBtn;            //微信支付按钮    tag = 103
- (IBAction)payBtnClick:(UIButton *)sender;

- (IBAction)nextBtnClick:(UIButton *)sender;


@end

@implementation BuyCoinViewController


-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [self setUI];
}

- (void)setUI {
    self.title = @"购买金币";

    self.view.backgroundColor = GRAYBG_COLOR;
    self.appleBuyBtn.selected = YES;
    self.alipayBtn.selected = NO;
    self.wxpayBtn.selected = NO;
    
    self.inputCoin.delegate = self;
    
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

/**
 *  支付方式
 */
- (IBAction)payBtnClick:(UIButton *)sender {
    self.appleBuyBtn.selected = NO;
    self.alipayBtn.selected = NO;
    self.wxpayBtn.selected = NO;
    if (sender.tag == 101) {  //苹果内购
        self.appleBuyBtn.selected = YES;
    }
    else if (sender.tag == 102) { //支付宝
        self.alipayBtn.selected = YES;
    }
    else if (sender.tag == 103) { //微信支付
        self.wxpayBtn.selected = YES;
    }
}

- (IBAction)nextBtnClick:(UIButton *)sender {
    //获取金币数目
//    NSInteger coinNum = [self.inputCoin.text integerValue];
//    if (coinNum < 0||coinNum == 0) {
//        [MBProgressHUD showError:@"金币不得小于0" toView:self.view];
//        return;
//    }
    
    if ([self.inputCoin.text isEqualToString:@""] || [self.inputCoin.text integerValue] == 0) {
        [MBProgressHUD showError:@"金额有误"];
        return;
    }
    
    if ([self.inputCoin.text integerValue] > 1000) {
        [MBProgressHUD showError:@"金额不得超过1000"];
        return;
    }

    
    
    //[self buy];
}


#pragma mark - ******* 苹果内购 *******
//进入苹果内购流程
- (void)enterInAppPurchase {
    if ([SKPaymentQueue canMakePayments]) {
        [self requestProductPayment:_selectProductID];
    } else {
        [[[UIAlertView alloc] initWithTitle:nil message:@"发起购买失败,您已禁止应用内付费购买" delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil] show];
    }
}


//请求商品
- (void)requestProductPayment:(NSString *)productID {
    NSArray *product = @[productID];
    NSSet *productSet = [NSSet setWithArray:product];
    SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:productSet];
    request.delegate = self;
    [request start];
    [EageProgressHUD eage_circleWaitShown:YES];
}



#pragma mark - SKProductsRequestDelegate
//收到产品返回信息
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    NSArray *product = response.products;
    if([product count] == 0){
        NSLog(@"--------------没有商品------------------");
        return;
    }
    NSLog(@"productID:%@", response.invalidProductIdentifiers);
    NSLog(@"产品付费数量:%ld",[product count]);
    
    SKProduct *p = nil;
    for (SKProduct *pro in product) {
        NSLog(@"%@", [pro description]);
        NSLog(@"%@", [pro localizedTitle]);
        NSLog(@"%@", [pro localizedDescription]);
        NSLog(@"%@", [pro price]);
        NSLog(@"%@", [pro productIdentifier]);
        
        if([pro.productIdentifier isEqualToString:_selectProductID]){
            p = pro;
        }
    }
    
    SKPayment *payment = [SKPayment paymentWithProduct:p];
    
    NSLog(@"发送购买请求");
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}



//请求失败
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error{
    NSLog(@"------------------错误-----------------:%@", error);
}

- (void)requestDidFinish:(SKRequest *)request{
    NSLog(@"------------反馈信息结束-----------------");
}



//监听购买结果
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transaction{
    
    for(SKPaymentTransaction *tran in transaction){
        
        switch (tran.transactionState) {
            case SKPaymentTransactionStatePurchased:
                NSLog(@"交易完成");
                [self completeTransaction:tran];
                break;
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"商品添加进列表");
                break;
            case SKPaymentTransactionStateRestored:
                NSLog(@"已经购买过商品");
                [self restoreTransaction:tran];
                [EageProgressHUD eage_circleWaitShown:NO];
                break;
            case SKPaymentTransactionStateFailed:
                NSLog(@"交易失败");
                [self failedTransaction:tran];
                [EageProgressHUD eage_circleWaitShown:NO];
                break;
            default:
                break;
        }
    }
}


//购买成功结束交易
- (void)completeTransaction:(SKPaymentTransaction *)transaction{
    NSLog(@"交易结束");
    [EageProgressHUD eage_circleWaitShown:NO];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    //通知服务器
    NSString *selectAmount = @"";
    if ([_selectProductID isEqualToString:CONSTPRICE_HD_600]) {
        selectAmount = @"600";
    } else if ([_selectProductID isEqualToString:CONSTPRICE_HD_1800]) {
        selectAmount = @"1800";
    } else if ([_selectProductID isEqualToString:CONSTPRICE_HD_5000]) {
        selectAmount = @"5000";
    } else if ([_selectProductID isEqualToString:CONSTPRICE_HD_10800]) {
        selectAmount = @"10800";
    } else if ([_selectProductID isEqualToString:CONSTPRICE_HD_29800]) {
        selectAmount = @"29800";
    }
    [EageProgressHUD eage_circleWaitShown:YES];
    [LYHttpPoster postHttpRequestByPost:[NSString stringWithFormat:@"%@/mobile/user/buyHDFinish",REQUESTHEADER] andParameter:@{@"user_id":[LYUserService sharedInstance].userID,@"num":selectAmount} success:^(id successResponse) {
        if ([[NSString stringWithFormat:@"%@",successResponse[@"code"]] isEqualToString:@"200"]) {
            [EageProgressHUD eage_circleWaitShown:NO];
        } else {
            [EageProgressHUD eage_circleWaitShown:NO];
            [[[UIAlertView alloc] initWithTitle:@"错误" message:@"发生了未知的错误,导致您的交易失败,请及时联系客服" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil] show];
        }
    } andFailure:^(id failureResponse) {
        [EageProgressHUD eage_circleWaitShown:NO];
        [[[UIAlertView alloc] initWithTitle:@"错误" message:@"发生了未知的错误,导致您的交易失败,请及时联系客服" delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil] show];
    }];
}


//购买失败终止交易
- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    if (transaction.error.code != SKErrorPaymentCancelled) {
        [[[UIAlertView alloc] initWithTitle:nil message:@"购买失败,请重试" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
    } else {
        NSLog(@"用户取消交易");
    }
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}


//对于已购商品,处理恢复购买的逻辑
- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}
#pragma mark - ******* 苹果内购 *******


#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.view endEditing:YES];
    return YES;
}

#pragma mark 购买请求
//
//- (void)buy{
//
//    NSString *channel;
//
//    switch ([payType integerValue]) {
//        case 1:
//        {
//            channel = @"0";
//        }
//            break;
//        case 2:
//        {
//            channel = @"1";
//        }
//            break;
//        default:
//            break;
//    }
//
//    [MBProgressHUD showMessage:nil toView:self.view];
//    [LYHttpPoster postHttpRequestByPost:[NSString stringWithFormat:@"%@/mobile/user/buyHongdou",REQUESTHEADER] andParameter:@{@"buyer":[LYUserService sharedInstance].userID,@"content":@"购买红豆",@"amount":moneyTextField.text,@"createIp":@"128.0.0.1",@"channel":channel} success:^(id successResponse) {
//        MLOG(@"结果:%@",successResponse);
//        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
//        if ([[NSString stringWithFormat:@"%@",successResponse[@"code"]] isEqualToString:@"200"]) {
//            if ([payType isEqualToString:@"1"]) {
//                self.vipModel = [[VipModel alloc] initWithDict:successResponse[@"data"][@"pay"]];
//                if (self.vipModel) {
//                    [self aliPay];//支付宝支付
//                }
//            }
//            else if ([payType isEqualToString:@"2"]){
//                self.wxModel = [[WXModel alloc] initWithDict:successResponse[@"data"][@"pay"]];
//                if (self.wxModel) {
//                    [self wxPay];//微信支付
//                }
//            }
//        } else {
//            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
//            [MBProgressHUD showError:[NSString stringWithFormat:@"%@",successResponse[@"msg"]]];
//        }
//    } andFailure:^(id failureResponse) {
//        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
//        [MBProgressHUD showError:@"服务器繁忙,请重试"];
//    }];
//}
//
//#pragma makr 支付
//
//- (void)aliPay{
//    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
//    /*============================================================================
//    =======================需要填写商户app申请的===================================
//    ============================================================================*/
//    NSString *partner = self.vipModel.partner;
//    NSString *seller = self.vipModel.seller_id;
//    NSString *privateKey = self.vipModel.rsa_key;
//
////    partner和seller获取失败,提示
//    if ([partner length] == 0 ||
//        [seller length] == 0 ||
//        [privateKey length] == 0)
//    {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示"
//                                                        message:@"缺少partner或者seller或者私钥。"
//                                                       delegate:self
//                                              cancelButtonTitle:@"确定"
//                                              otherButtonTitles:nil];
//        [alert show];
//        return;
//    }
//
//    /*
//     *生成订单信息及签名
//     */
////    将商品信息赋予AlixPayOrder的成员变量
//    Order *order = [[Order alloc] init];
//    order.partner = partner;
//    order.seller = seller;
//    order.tradeNO = self.vipModel.out_trade_no; //订单ID（由商家自行制定）
//    order.productName = self.vipModel.subject; //商品标题
//    order.productDescription = self.vipModel.body; //商品描述
//    order.amount = moneyTextField.text; //商品价格
//    order.notifyURL =  self.vipModel.notify_url; //回调URL
//
//    order.service = @"mobile.securitypay.pay";
//    order.paymentType = @"1";
//    order.inputCharset = @"utf-8";
//    order.itBPay = self.vipModel.it_b_pay;
//    order.showUrl = @"m.alipay.com";
//
//    //应用注册scheme,在AlixPayDemo-Info.plist定义URL types
//    NSString *appScheme = @"LvYue";
//
//    //将商品信息拼接成字符串
//    NSString *orderSpec = [order description];
//    NSLog(@"orderSpec = %@",orderSpec);
//
//    //获取私钥并将商户信息签名,外部商户可以根据情况存放私钥和签名,只需要遵循RSA签名规范,并将签名字符串base64编码和UrlEncode
//    id<DataSigner> signer = CreateRSADataSigner(privateKey);
//    NSString *signedString = [signer signString:orderSpec];
//
//    //将签名成功字符串格式化为订单字符串,请严格按照该格式
//    NSString *orderString = nil;
//    if (signedString != nil) {
//        orderString = [NSString stringWithFormat:@"%@&sign=\"%@\"&sign_type=\"%@\"",
//                       orderSpec, signedString, @"RSA"];
//
//        [[AlipaySDK defaultService] payOrder:orderString fromScheme:appScheme callback:^(NSDictionary *resultDic) {
//            NSLog(@"reslut = %@",resultDic);
//            if ([resultDic[@"resultStatus"] integerValue] == 9000) {
//                [MBProgressHUD showSuccess:@"购买成功"];
//            }
//            else{
//                [MBProgressHUD showError:@"购买失败"];
//            }
//        }];
//    }
//}
//
//- (void)wxPay{
//    //向微信注册
//    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
//    [WXApi registerApp:self.wxModel.appid];
//
//    PayReq *request = [[PayReq alloc] init];
//    request.partnerId = [NSString stringWithFormat:@"%@",self.wxModel.partnerid];
//    request.prepayId = [NSString stringWithFormat:@"%@",self.wxModel.prepayid];
//    request.package = [NSString stringWithFormat:@"Sign=WXPay"];
//    request.nonceStr = [NSString stringWithFormat:@"%@",self.wxModel.nonceStr];
//    request.timeStamp = [self.wxModel.timestamp intValue];
//    request.sign = [NSString stringWithFormat:@"%@",self.wxModel.sign];
//    request.openID = [NSString stringWithFormat:@"%@",self.wxModel.appid];
//    [WXApi sendReq:request];
//}




@end
