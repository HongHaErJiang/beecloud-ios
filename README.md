## BeeCloud iOS SDK (Open Source)

[![Build Status](https://travis-ci.org/beecloud/beecloud-ios.svg)](https://travis-ci.org/beecloud/beecloud-ios) 
![license](https://img.shields.io/badge/license-MIT-brightgreen.svg) ![version](https://img.shields.io/badge/version-v3.4.2-blue.svg) 

</br>
## 简介

本项目的官方GitHub地址是 [https://github.com/beecloud/beecloud-ios](https://github.com/beecloud/beecloud-ios)

SDK支持以下支付渠道: 
 
 * 微信APP
 * 支付宝APP
 * 银联在线APP
 * PayPal
 * 百度钱包   

提供支付、支付订单以及退款订单的查询功能。  
还提供了线下收款功能(包括微信扫码、微信刷卡、支付宝扫码、支付宝条形码)，订单状态的查询以及订单撤销。  
本SDK是根据[BeeCloud Rest API](https://github.com/beecloud/beecloud-rest-api) 开发的 iOS SDK, 适用于 **iOS 6** 及以上版本。   


</br>
## 流程

下图为整个支付的流程:
![pic](http://7xavqo.com1.z0.glb.clouddn.com/UML01.png)

其中需要开发者开发的只有：

步骤①**（在App端）发送订单信息**

做完这一步之后就会跳到相应的支付页面（如微信app中），让用户继续后续的支付步骤

步骤②：**（在App端）处理同步回调结果**

付款完成或取消之后，会回到客户app中，在页面中展示支付结果（比如弹出框告诉用户"支付成功"或"支付失败")。同步回调结果只作为界面展示的依据，不能作为订单的最终支付结果，最终支付结果应以异步回调为准。

步骤③：**（在客户服务端）处理异步回调结果（[Webhook](https://beecloud.cn/doc/?index=webhook)）**
 
付款完成之后，根据客户在BeeCloud后台的设置，BeeCloud会向客户服务端发送一个Webhook请求，里面包括了数字签名，订单号，订单金额等一系列信息。客户需要在服务端依据规则要验证**数字签名是否正确，购买的产品与订单金额是否匹配，这两个验证缺一不可**。验证结束后即可开始走支付完成后的逻辑。

了解更多关于BeeCloud，请前往[帮助中心](http://help.beecloud.cn/hc/) 

<br>
## 准备
参考[快速开始](https://beecloud.cn/apply/)，完成开发准备工作。

</br>
## 导入SDK

方法一、[下载本工程源码](https://beecloud.cn/download/)，将`BCPaySDK`文件夹中的代码拷贝进自己项目，并按照下文的3个步骤导入相应文件进自己工程即可。

- 下载的`BCPaySDK`文件夹下的`Channel`文件夹里包含了`支付宝`, `银联`, `微信`, `PayPal`,`OfflinePay`,`百度钱包`的原生SDK，请按需选择自己所需要的渠道。  

- 最后加入系统库 `libz.dylib`, `libsqlite3.dylib`, `libc++.dylib`。  
> iOS9 加入`libz.1.2.5.tbd`、`libc++.tbd`、`libsqlite3.tbd` 
 
- 使用PayPal支付，需要添加以下系统库：  
 `AudioToolbox.framework`  
 `CoreLocation.framework`  
 `MessageUI.framework`  
 `CoreMedia.framework`  
 `CoreVideo.framework`  
 `Accelerate.framework`  
 `AVFoundation.framework`  

- 使用百度钱包，需要添加以下系统库：  
![BDWalletVendor](http://7xavqo.com1.z0.glb.clouddn.com/BDWalletVendor.png)

方法二、使用CocoaPods   
在podfile中加入

```
pod 'BeeCloud' //包含支付宝微信银联三个渠道
pod 'BeeCloud/Alipay' //只包含支付宝
pod 'BeeCloud/Wx' //只包括微信
pod 'BeeCloud/UnionPay' //只包括银联
pod 'BeeCloud/PayPal' //只包括paypal
pod 'BeeCloud/Baidu' //只包括百度钱包
```

</br>
## 配置

① 添加`URL Schemes`  

在`Xcode`中，选择你的工程设置项，选中`TARGETS`，在`Info`标签栏的 `URL Types`添加`URL Schemes`。如果使用微信，填入所注册的微信应用程序`APPID`;如果不使用微信，则自定义，允许英文字母和数字，首字母必须是英文字母，建议起名稍复杂一些，尽量避免与支付宝(alipay)等其他程序冲突。  

![URL Schemes](http://7xavqo.com1.z0.glb.clouddn.com/scheme.png)
在Info.plist中显示为：

 ```
 <array>
	<dict>
		<key>CFBundleURLName</key>
		<string>zhifubao</string>
		<key>CFBundleURLSchemes</key>
		<array>
			<string>payDemo</string>
		</array>
	</dict>
	<dict>
		<key>CFBundleURLName</key>
		<string>weixin</string>
		<key>CFBundleURLSchemes</key>
		<array>
			<string>wxf1aa465362b4c8f1</string>
		</array>
	</dict>
 </array>
 ```

② `iOS 9`以上版本如果需要使用支付宝和微信支付，需要在`Info.plist`添加以下代码：

```
<key>LSApplicationQueriesSchemes</key>
<array>
   <string>weixin</string>
   <string>wechat</string>
   <string>alipay</string>
</array>
```
③ `iOS 9`默认限制了http协议的访问，如果App需要使用`http://`访问，必须在 `Info.plist`添加如下代码：

```
<key>NSAppTransportSecurity</key>
<dict>
   <key>NSAllowsArbitraryLoads</key>
   <true/>
</dict>
```
④ 如果Build失败，遇到以下错误信息：

```
XXXXXXX does not contain bitcode. You must rebuild it with bitcode enabled (Xcode setting ENABLE_BITCODE), obtain an updated library from the vendor, or disable bitcode for this target.
```
请到 Xcode 项目的 Build Settings 页搜索 bitcode，将 Enable Bitcode 设置为 NO。

⑤ 如果使用银联支付，请添加以下配置：  
`选择工程`->`targets`->`build settings`->`linking`->`other linker flags`, 配置 **-ObjC**

</br>
## 加入BeeCloud支付 
###  初始化
① 初始化BeeCloud  

**初始化分为生产模式(LiveMode)、沙箱环境(SandboxMode)；沙箱测试模式下不产生真实交易**  

开启生产环境

```objc
[BeeCloud initWithAppID:@"BeeCloud AppId" andAppSecret:@"BeeCloud App Secret"];
```
  
开启沙箱测试环境

```objc
[BeeCloud initWithAppID:@"BeeCloud AppId" andAppSecret:@"BeeCloud Test Secret"];
[BeeCloud setSandboxMode:YES];
或者
[BeeCloud initWithAppID:@"BeeCloud AppId" andAppSecret:@"BeeCloud Test Secret" sandbox:YES];
```

查看当前模式

```objc
/* 返回YES代表沙箱测试模式；NO代表生产模式 */
[BeeCloud getCurrentMode];
```

② 初始化微信  
如果您使用了微信支付，需要用微信开放平台Appid初始化。  

```objc
[BeeCloud initWeChatPay:@"微信开放平台appid"];
```

③ handleOpenUrl
此方法用于处理从第三方应用回到本应用时的回调

```objc
//为保证从支付宝，微信返回本应用，须绑定openUrl. 用于iOS9之前版本
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if (![BeeCloud handleOpenUrl:url]) {
        //handle其他类型的url
    }
    return YES;
}

//iOS9之后apple官方建议使用此方法
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options {
    if (![BeeCloud handleOpenUrl:url]) {
        //handle其他类型的url
    }
    return YES;
}
```

### 支付

通过构造`BCPayReq`的实例，使用`[BeeCloud sendBCReq:payReq]`方法发起支付请求。具体请参考Demo。    
**响应事件对象为`BCPayResp`**

```objc
//微信、支付宝、银联、百度钱包
- (void)doPay:(PayChannel)channel {
    NSString *billno = [self genBillNo];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"value",@"key", nil];
    /**
        按住键盘上的option键，点击参数名称，可以查看参数说明
     **/
    BCPayReq *payReq = [[BCPayReq alloc] init];
    payReq.channel = channel; //支付渠道
    payReq.title = billTitle;//订单标题
    payReq.totalFee = @"10";//订单价格
    payReq.billNo = billno;//商户自定义订单号
    payReq.scheme = @"payDemo";//URL Scheme,在Info.plist中配置; 支付宝必有参数
    payReq.billTimeOut = 300;//订单超时时间
    payReq.viewController = self; //银联支付和Sandbox环境必填
    payReq.optional = dict;//商户业务扩展参数，会在webhook回调时返回
    [BeeCloud sendBCReq:payReq];
}
```

### 查询

#### 查询支付订单  
通过构造`BCQueryBillsReq`的实例，使用`[BeeCloud sendBCReq:req]`方法发起支付查询。  
**响应事件类型对象：`BCQueryBillsResp`**   
**支付订单对象: `BCQueryBillResult`**  

```objc
BCQueryBillsReq *req = [[BCQueryBillsReq alloc] init];
req.channel = channel;
req.billStatus = BillStatusOnlySuccess; //支付成功的订单
req.needMsgDetail = YES; //是否需要返回支付成功订单的渠道反馈的具体信息
//req.billno = @"20150901104138656";   //订单号
//req.startTime = @"2015-10-22 00:00"; //订单时间
//req.endTime = @"2015-10-23 00:00";   //订单时间
req.skip = 0;
req.limit = 10;
[BeeCloud sendBCReq:req];
```

#### 查询支付订单总数
通过构造`BCQueryBillsCountReq`的实例，使用`[BeeCloud sendBCReq:req]`方法发起查询符合条件的支付订单总数。  
**响应事件类型：`BCQueryBillsCountResp`**

```objc
BCQueryBillsCountReq *req = [[BCQueryBillsCountReq alloc] init];
req.channel = channel; //支付渠道
req.billNo = billNo;//商户订单号
req.billStatus = billStatus;//订单状态
req.startTime = startTime; //开始时间
req.endTime = endTime; //结束时间
[BeeCloud sendBCReq:req];
```

#### 根据id查询支付订单
通过构造`BCQueryBillByIdReq`的实例，使用`[BeeCloud sendBCReq:req]`方法发起查询支付订单。  
**响应事件类型: `BCQueryBillByIdResp`**

```objc
//bcId会在支付的回调中返回
BCQueryBillByIdReq *req = [[BCQueryBillByIdReq alloc] initWithObjectId:bcId];
[BeeCloud sendBCReq:req];
```

#### 查询退款订单  
通过构造`BCQueryRefundsReq`的实例，使用`[BeeCloud sendBCReq:req]`方法发起退款查询。  
**响应事件类型对象：`BCQueryRefundsResp`**  
**退款订单对象: `BCQueryRefundResult`**

```objc
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
```

#### 查询退款订单总数
通过构造`BCQueryRefundsCountReq`的实例，使用`[BeeCloud sendBCReq:req]`方法查询符合条件的退款订单总数。  
**响应事件类型: `BCQueryRefundsCountResp`**

```objc
BCQueryRefundsCountReq *req = [[BCQueryRefundsCountReq alloc] init];
req.channel = channel;
req.billNo = billNo;
req.needApproved = needApproved;
req.refundNo = billNo;
req.startTime = startTime;
req.endTime = endTime;
[BeeCloud sendBCReq:req];
```

#### 根据id查询退款订单
通过构造`BCQueryRefundByIdReq`的实例，使用`[BeeCloud sendBCReq:req]`方法发起查询支付订单。  
**响应事件类型: `BCQueryRefundByIdResp`**

```objc
//bcId会在退款的回调中返回
BCQueryRefundByIdReq *req = [[BCQueryRefundByIdReq alloc] initWithObjectId:bcId];
[BeeCloud sendBCReq:req];
```

#### 查询退款状态（只支持微信）
通过构造`BCRefundStatusReq`的实例，使用`[BeeCloud sendBCReq:req]`方法发起退款查询。  
**响应事件类型对象：`BCRefundStatusResp`**

```objc
BCRefundStatusReq *req = [[BCRefundStatusReq alloc] init];
req.refundno = @"20150709173629127";
[BeeCloud sendBCReq:req];
```
## 处理请求回调

实现接口`BeeCloudDelegate`，获取不同类型的请求对应的响应；更多内容请参考[Demo](https://github.com/beecloud/beecloud-ios/tree/master/BCPayExample)。  

*  使用以下方法设置delegate:

```objc
[BeeCloud setBeeCloudDelegate:self];
```

*  实现BeeCloudDelegate:

```objc
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
```

## Demo
项目中的`BCPayExample`文件夹为我们的demo文件  
项目中的`BCPaySDK`文件夹为SDK目录，可以查看SDK源码    
在真机上运行`BCPayExample`target，体验真实支付场景

## 测试
项目根目录命令行运行`bash runTest.sh`, 就可以完成Unit Test。

