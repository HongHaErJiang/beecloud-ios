//
//  ChannelCollectionViewController.m
//  BCPay
//
//  Created by Ewenlong03 on 16/2/23.
//  Copyright © 2016年 BeeCloud. All rights reserved.
//

#import "ChannelCollectionViewController.h"
#import "QueryResultViewController.h"
#import "AFNetworking.h"
#import "PayPalMobile.h"
#import "BCOffinePay.h"
#import "GenQrCode.h"
#import "QRCodeViewController.h"
#import "ScanViewController.h"
#import "PayChannelCell.h"
#import "BDWalletSDKMainManager.h"
#import "ChannelCollectionViewCell.h"

@interface ChannelCollectionViewController ()<BeeCloudDelegate, PayPalPaymentDelegate, SCanViewDelegate, QRCodeDelegate,BDWalletSDKMainManagerDelegate,UICollectionViewDelegate, UICollectionViewDataSource> {
    PayPalConfiguration * _payPalConfig;
    PayPalPayment *_completedPayment;
    PayChannel currentChannel;
    NSArray *channelList;
    NSString * billTitle;
}


@end

@implementation ChannelCollectionViewController

static NSString * const reuseIdentifier = @"ChannelCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    //    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    if (self.actionType == 0) {
        self.title = @"支付";
    } else if (self.actionType == 1) {
        self.title = @"查询支付订单";
    } else if (self.actionType == 2) {
        self.title = @"查询退款订单";
    }
    channelList = @[@{@"sub":@(PayChannelWxApp), @"img":@"wx", @"title":@"微信支付"},
                           @{@"sub":@(PayChannelWxNative), @"img":@"wx", @"title":@"微信扫码"},
                           @{@"sub":@(PayChannelWxScan), @"img":@"wx", @"title":@"微信刷卡"},
                           @{@"sub":@(PayChannelAliApp), @"img":@"ali", @"title":@"支付宝支付"},
                           @{@"sub":@(PayChannelAliOfflineQrCode), @"img":@"ali", @"title":@"支付宝扫码"},
                           @{@"sub":@(PayChannelAliScan), @"img":@"ali", @"title":@"支付宝条码"},
                           @{@"sub":@(PayChannelUnApp), @"img":@"un", @"title":@"银联在线"},
                           @{@"sub":@(PayChannelApplePay), @"img":@"ApplePay", @"title":@"ApplePay"},
                           @{@"sub":@(PayChannelBaiduApp), @"img":@"baidu", @"title":@"百度钱包"},
                           @{@"sub":@(PayChannelPayPal), @"img":@"paypal", @"title":@"PayPal"},
                           ];

    billTitle = [BeeCloud getCurrentMode] ? @"iOS Demo Sandbox" : @"iOS Demo Live";
    self.orderList = nil;
    
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
#pragma mark - 设置delegate
    [BeeCloud setBeeCloudDelegate:self];
}

/**
 *  打开摄像头，扫描用户的二维码
 */
- (void)showScanViewController {
    ScanViewController *scanView = [[ScanViewController alloc] init];
    scanView.delegate = self;
    [self presentViewController:scanView animated:YES completion:nil];
}

/**
 *  获得支付授权码，发起支付
 *
 *  @param authCode 支付授权码
 */
- (void)scanWithAuthCode:(NSString *)authCode {
    [self doOfflinePay:currentChannel authCode:authCode];
}

/**
 *  用户付款后，查询订单状态
 *
 *  @param resp 支付结果
 */
- (void)qrCodeBeScaned:(BCOfflinePayResp *)resp {
    BCOfflineStatusReq *req = [[BCOfflineStatusReq alloc] init];
    BCOfflinePayReq *payReq = (BCOfflinePayReq *)resp.request;
    req.channel = payReq.channel;
    req.billNo = payReq.billNo;
    [BeeCloud sendBCReq:req];
}

#pragma mark - prepare segue
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    QueryResultViewController *viewController = (QueryResultViewController *)segue.destinationViewController;
    if([segue.identifier isEqualToString:@"queryResult"]) {
        viewController.resp = self.orderList;
    }
}

#pragma mark - 生成订单号
- (NSString *)genBillNo {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMddHHmmssSSS"];
    return [formatter stringFromDate:[NSDate date]];
}

- (void)setHideTableViewCell:(UITableView *)tableView {
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor clearColor];
    tableView.tableFooterView = view;
}

#pragma mark - Baidu Delegate
- (void)BDWalletPayResultWithCode:(int)statusCode payDesc:(NSString *)payDescs {
    NSString *status = @"";
    switch (statusCode) {
        case 0:
            status = @"支付成功";
            break;
        case 1:
            status = @"支付中";
            break;
        case 2:
            status = @"支付取消";
            break;
        default:
            break;
    }
    [self showAlertView:status];
}

- (void)logEventId:(NSString *)eventId eventDesc:(NSString *)eventDesc {
}


#pragma mark - 微信、支付宝、银联、百度钱包

- (void)doPay:(PayChannel)channel {
    
    NSString *billno = [self genBillNo];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"value",@"key", nil];
    /**
     按住键盘上的option键，点击参数名称，可以查看参数说明
     **/
    BCPayReq *payReq = [[BCPayReq alloc] init];
    payReq.channel = channel; //支付渠道
    payReq.title = billTitle;//订单标题
    payReq.totalFee = @"1";//订单价格
    payReq.billNo = billno;//商户自定义订单号
    payReq.scheme = @"payDemo";//URL Scheme,在Info.plist中配置; 支付宝必有参数
    payReq.billTimeOut = 300;//订单超时时间
    payReq.viewController = self; //银联支付和Sandbox环境必填
    payReq.optional = dict;//商户业务扩展参数，会在webhook回调时返回
    [BeeCloud sendBCReq:payReq];
}

- (void)doOfflinePay:(PayChannel)channel authCode:(NSString *)authcode {
    NSString *billno = [self genBillNo];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"value",@"key", nil];
    
    /**
     按住键盘上的option键，点击参数名称，可以查看参数说明
     **/
    BCOfflinePayReq *payReq = [[BCOfflinePayReq alloc] init];
    payReq.channel = channel; //支付渠道，支持WX_NATIVE、WX_SCAN、ALI_OFFLINE_QRCODE、ALI_SCAN
    payReq.title = @"Offline Pay";//订单标题
    payReq.totalFee = @"1"; //订单价格
    payReq.billNo = billno; //商户自定义订单号
    payReq.authcode = authcode; //支付授权码(ALI_SCAN,WX_SCAN时必需)，通过扫码用户的支付宝钱包(付款)、微信钱包(刷卡)获取
    payReq.terminalId = @"BeeCloud617"; //自定义扫码设备号
    payReq.storeId = @"BeeCloud618";//自定义店铺编号
    payReq.optional = dict;//用于商户业务扩展参数，会在webhook回调时返回
    [BeeCloud sendBCReq:payReq];
}

#pragma mark - PayPal Pay
- (void)doPayPal {
    BCPayPalReq *payReq = [[BCPayPalReq alloc] init];
    
    _payPalConfig = [[PayPalConfiguration alloc] init];
    _payPalConfig.acceptCreditCards = YES;
    _payPalConfig.merchantName = @"Awesome Shirts, Inc.";
    _payPalConfig.merchantPrivacyPolicyURL = [NSURL URLWithString:@"https://www.paypal.com/webapps/mpp/ua/privacy-full"];
    _payPalConfig.merchantUserAgreementURL = [NSURL URLWithString:@"https://www.paypal.com/webapps/mpp/ua/useragreement-full"];
    
    _payPalConfig.languageOrLocale = [NSLocale preferredLanguages][0];
    
    _payPalConfig.payPalShippingAddressOption = PayPalShippingAddressOptionPayPal;
    
    PayPalItem *item1 = [PayPalItem itemWithName:@"Old jeans with holes"
                                    withQuantity:2
                                       withPrice:[NSDecimalNumber decimalNumberWithString:@"84.99"]
                                    withCurrency:@"USD"
                                         withSku:@"Hip-00037"];
    
    PayPalItem *item2 = [PayPalItem itemWithName:@"Free rainbow patch"
                                    withQuantity:1
                                       withPrice:[NSDecimalNumber decimalNumberWithString:@"0.00"]
                                    withCurrency:@"USD"
                                         withSku:@"Hip-00066"];
    
    PayPalItem *item3 = [PayPalItem itemWithName:@"Long-sleeve plaid shirt (mustache not included)"
                                    withQuantity:1
                                       withPrice:[NSDecimalNumber decimalNumberWithString:@"37.99"]
                                    withCurrency:@"USD"
                                         withSku:@"Hip-00291"];
    
    payReq.items = @[item1, item2, item3];
    payReq.shipping = @"5.00";
    payReq.tax = @"2.50";
    payReq.shortDesc = billTitle;
    payReq.viewController = self;
    payReq.payConfig = _payPalConfig;
    
    [BeeCloud sendBCReq:payReq];
    
}

#pragma mark - PayPal Verify
- (void)doPayPalVerify {
    BCPayPalVerifyReq *req = [[BCPayPalVerifyReq alloc] init];
    req.payment = _completedPayment;
    req.optional = @{@"key1":@"value1"};
    [BeeCloud sendBCReq:req];
}

#pragma mark - PayPalPaymentDelegate

- (void)payPalPaymentViewController:(PayPalPaymentViewController *)paymentViewController didCompletePayment:(PayPalPayment *)completedPayment {
    NSLog(@"PayPal Payment Success! %@", completedPayment.description);
    
    _completedPayment = completedPayment;
    
    [self doPayPalVerify];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)payPalPaymentDidCancel:(PayPalPaymentViewController *)paymentViewController {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - BCPay回调

- (void)onBeeCloudResp:(BCBaseResp *)resp {
    
    switch (resp.type) {
        case BCObjsTypePayResp:
        {
            // 支付请求响应
            BCPayResp *tempResp = (BCPayResp *)resp;
            if (tempResp.resultCode == 0) {
                BCPayReq *payReq = (BCPayReq *)resp.request;
                //百度钱包比较特殊需要用户用获取到的orderInfo，调用百度钱包SDK发起支付
                if (payReq.channel == PayChannelBaiduApp && ![BeeCloud getCurrentMode]) {
                    [[BDWalletSDKMainManager getInstance] doPayWithOrderInfo:tempResp.paySource[@"orderInfo"] params:nil delegate:self];
                } else {
                    //微信、支付宝、银联支付成功
                    [self showAlertView:resp.resultMsg];
                }
            } else {
                //支付取消或者支付失败
                [self showAlertView:[NSString stringWithFormat:@"%@ : %@",tempResp.resultMsg, tempResp.errDetail]];
            }
        }
            break;
        case BCObjsTypeQueryBillsResp:
        {
            BCQueryBillsResp *tempResp = (BCQueryBillsResp *)resp;
            if (resp.resultCode == 0) {
                if (tempResp.count == 0) {
                    [self showAlertView:@"未找到相关订单信息"];
                } else {
                    self.orderList = tempResp;
                    [self performSegueWithIdentifier:@"queryResult" sender:self];
                }
            } else {
                [self showAlertView:[NSString stringWithFormat:@"%@ : %@",tempResp.resultMsg, tempResp.errDetail]];
            }
        }
            break;
        case BCObjsTypeQueryRefundsResp:
        {
            BCQueryRefundsResp *tempResp = (BCQueryRefundsResp *)resp;
            if (resp.resultCode == 0) {
                if (tempResp.count == 0) {
                    [self showAlertView:@"未找到相关订单信息"];
                } else {
                    self.orderList = tempResp;
                    [self performSegueWithIdentifier:@"queryResult" sender:self];
                }
            } else {
                [self showAlertView:[NSString stringWithFormat:@"%@ : %@",tempResp.resultMsg, tempResp.errDetail]];
            }
        }
            break;
            
        case BCObjsTypeOfflinePayResp:
        {
            BCOfflinePayResp *tempResp = (BCOfflinePayResp *)resp;
            if (resp.resultCode == 0) {
                BCOfflinePayReq *payReq = (BCOfflinePayReq *)tempResp.request;
                switch (payReq.channel) {
                    case PayChannelAliOfflineQrCode:
                    case PayChannelWxNative:
                        if (tempResp.codeurl.isValid) {
                            QRCodeViewController *qrCodeView = [[QRCodeViewController alloc] init];
                            qrCodeView.resp = tempResp;
                            qrCodeView.delegate = self;
                            [self.navigationController pushViewController:qrCodeView animated:YES];
                        }
                        break;
                    case PayChannelAliScan:
                    case PayChannelWxScan:
                    {
                        BCOfflineStatusReq *req = [[BCOfflineStatusReq alloc] init];
                        req.channel = payReq.channel;
                        req.billNo = payReq.billNo;
                        [BeeCloud sendBCReq:req];
                    }
                        break;
                    default:
                        break;
                }
            } else {
                [self showAlertView:[NSString stringWithFormat:@"%@ : %@",tempResp.resultMsg, tempResp.errDetail]];
            }
        }
            break;
        case BCObjsTypeOfflineBillStatusResp:
        {
            static int queryTimes = 1;
            BCOfflineStatusResp *tempResp = (BCOfflineStatusResp *)resp;
            if (tempResp.resultCode == 0) {
                if (!tempResp.payResult && queryTimes < 3) {
                    queryTimes++;
                    [BeeCloud sendBCReq:tempResp.request];
                } else {
                    [self showAlertView:tempResp.payResult?@"支付成功":@"支付失败"];
                    //                BCOfflineRevertReq *req = [[BCOfflineRevertReq alloc] init];
                    //                req.channel = tempResp.request.channel;
                    //                req.billno = tempResp.request.billno;
                    //                [BeeCloud sendBCReq:req];
                    queryTimes = 1;
                }
                
            } else {
                [self showAlertView:[NSString stringWithFormat:@"%@ : %@",tempResp.resultMsg, tempResp.errDetail]];
            }
        }
            break;
        case BCObjsTypeOfflineRevertResp:
        {
#pragma mark - 线下撤销订单响应事件类型，包含WX_SCAN,ALI_SCAN,ALI_OFFLINE_QRCODE
            BCOfflineRevertResp *tempResp = (BCOfflineRevertResp *)resp;
            if (resp.resultCode == 0) {
                [self showAlertView:tempResp.revertStatus?@"撤销成功":@"撤销失败"];
            } else {
                [self showAlertView:[NSString stringWithFormat:@"%@ : %@",tempResp.resultMsg, tempResp.errDetail]];
            }
        }
            break;
        default:
        {
            if (resp.resultCode == 0) {
                [self showAlertView:resp.resultMsg];
            } else {
                [self showAlertView:[NSString stringWithFormat:@"%@ : %@",resp.resultMsg, resp.errDetail]];
            }
        }
            break;
    }
}

- (void)showAlertView:(NSString *)msg {
    UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"提示" message:msg delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alert show];
}

#pragma mark - 订单查询

- (void)doQuery:(PayChannel)channel {
    
    if (self.actionType == 1) {
        BCQueryBillsReq *req = [[BCQueryBillsReq alloc] init];
        req.channel = channel;
        req.billStatus = BillStatusOnlySuccess;
        req.needMsgDetail = YES;
        //   req.billno = @"20150901104138656";//订单号
        //  req.startTime = @"2015-10-22 00:00";//订单时间
        // req.endTime = @"2015-10-23 00:00";//订单时间
        req.skip = 0;//
        req.limit = 10;
        [BeeCloud sendBCReq:req];
    } else if (self.actionType == 2) {
        BCQueryRefundsReq *req = [[BCQueryRefundsReq alloc] init];
        req.channel = channel;
        req.needApproved = NeedApprovalAll;
        //  req.billno = @"20150722164700237";
        //  req.starttime = @"2015-07-21 00:00";
        // req.endtime = @"2015-07-23 12:00";
        //req.refundno = @"20150709173629127";
        req.skip = 0;
        req.limit = 10;
        [BeeCloud sendBCReq:req];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    return channelList.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    ChannelCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    // Configure the cell
    NSDictionary *row = channelList[indexPath.row];
    cell.title.text = row[@"title"];
    cell.icon.image = [UIImage imageNamed:row[@"img"]];
    
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

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *row = channelList[indexPath.row];
    PayChannel channel = [row[@"sub"] integerValue];
    if (self.actionType == 0) {
        switch (channel) {
            case PayChannelWxApp:
            case PayChannelAliApp:
            case PayChannelUnApp:
            case PayChannelBaiduApp:
            case PayChannelApplePay:
                [self doPay:channel];
                break;
            case PayChannelWxNative:
            case PayChannelAliOfflineQrCode:
                if ([BeeCloud getCurrentMode]) {
                    [self showAlertView:@"该渠道不支持沙箱测试"];
                    return;
                }
                [self doOfflinePay:channel authCode:@""];
                break;
            case PayChannelWxScan:
            case PayChannelAliScan:
                if ([BeeCloud getCurrentMode]) {
                    [self showAlertView:@"该渠道不支持沙箱测试"];
                    return;
                }
                currentChannel = channel;
#if TARGET_IPHONE_SIMULATOR
                [self showAlertView:@"模拟器不能打开相机"];
#elif TARGET_OS_IPHONE
                [self showScanViewController];
#endif
                break;
            case PayChannelPayPal:
            case PayChannelPayPalSandbox:
                [self doPayPal];
                break;
            default:
                break;
        }
    } else {
        switch (channel) {
            case PayChannelWxScan:
                [self doQuery:PayChannelWx];
                break;
            case PayChannelAliScan:
            case PayChannelAliOfflineQrCode:
                [self doQuery:PayChannelAli];
                break;
            default:
                [self doQuery:channel];
                break;
        }
    }
    
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
}

@end
