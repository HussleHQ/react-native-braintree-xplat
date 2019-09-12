//
//  RCTBraintree.m
//  RCTBraintree
//
//  Created by Rickard Ekman on 18/06/16.
//  Copyright © 2016 Rickard Ekman. All rights reserved.
//

#import "RCTBraintree.h"
#import <Braintree3DSecure.h>
#import <BraintreeUI.h>
#import <BTThreeDSecureRequest.h>

@implementation RCTBraintree {
    bool runCallback;
}

static NSString *URLScheme;

+ (instancetype)sharedInstance {
    static RCTBraintree *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[RCTBraintree alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    if ((self = [super init])) {
        self.dataCollector = [[BTDataCollector alloc]
                              initWithEnvironment:BTDataCollectorEnvironmentProduction];
    }
    return self;
}

#pragma mark BTThreeDSecureRequestDelegate

- (void)onLookupComplete:(__unused BTThreeDSecureRequest *)request result:(__unused BTThreeDSecureLookup *)lookup next:(void (^)(void))next {
    // Optionally inspect the lookup result and prepare UI if a challenge is required
    next();
}

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(setupWithURLScheme:(NSString *)clientToken urlscheme:(NSString*)urlscheme callback:(RCTResponseSenderBlock)callback)
{
    URLScheme = urlscheme;
    [BTAppSwitch setReturnURLScheme:urlscheme];
    self.braintreeClient = [[BTAPIClient alloc] initWithAuthorization:clientToken];
    if (self.braintreeClient == nil) {
        callback(@[@false]);
    }
    else {
        callback(@[@true]);
    }
}

RCT_EXPORT_METHOD(setup:(NSString *)clientToken callback:(RCTResponseSenderBlock)callback)
{
    self.braintreeClient = [[BTAPIClient alloc] initWithAuthorization:clientToken];
    if (self.braintreeClient == nil) {
        callback(@[@false]);
    }
    else {
        callback(@[@true]);
    }
}

RCT_EXPORT_METHOD(showPaymentViewController:(NSDictionary *)options callback:(RCTResponseSenderBlock)callback)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.threeDSecureOptions = options[@"threeDSecure"];
        if (self.threeDSecureOptions) {
            self.threeDSecure = [[BTThreeDSecureDriver alloc] initWithAPIClient:self.braintreeClient delegate:self];
        }

        BTDropInViewController *dropInViewController = [[BTDropInViewController alloc] initWithAPIClient:self.braintreeClient];
        dropInViewController.delegate = self;

        NSLog(@"%@", options);

        UIColor *tintColor = options[@"tintColor"];
        UIColor *bgColor = options[@"bgColor"];
        UIColor *barBgColor = options[@"barBgColor"];
        UIColor *barTintColor = options[@"barTintColor"];

        NSString *title = options[@"title"];
        NSString *description = options[@"description"];
        NSString *amount = options[@"amount"];

        if (tintColor) dropInViewController.view.tintColor = [RCTConvert UIColor:tintColor];
        if (bgColor) dropInViewController.view.backgroundColor = [RCTConvert UIColor:bgColor];

        dropInViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(userDidCancelPayment)];

        self.callback = callback;

        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:dropInViewController];

        if (barBgColor) navigationController.navigationBar.barTintColor = [RCTConvert UIColor:barBgColor];
        if (barTintColor) navigationController.navigationBar.tintColor = [RCTConvert UIColor:barTintColor];

        if (options[@"callToActionText"]) {
            BTPaymentRequest *paymentRequest = [[BTPaymentRequest alloc] init];
            paymentRequest.callToActionText = options[@"callToActionText"];

            dropInViewController.paymentRequest = paymentRequest;
        }

        if (title) [dropInViewController.paymentRequest setSummaryTitle:title];
        if (description) [dropInViewController.paymentRequest setSummaryDescription:description];
        if (amount) [dropInViewController.paymentRequest setDisplayAmount:amount];

        [self.reactRoot presentViewController:navigationController animated:YES completion:nil];
    });
}

RCT_EXPORT_METHOD(showPayPalViewController:(RCTResponseSenderBlock)callback)
{
    dispatch_async(dispatch_get_main_queue(), ^{

        BTPayPalDriver *payPalDriver = [[BTPayPalDriver alloc] initWithAPIClient:self.braintreeClient];
        payPalDriver.viewControllerPresentingDelegate = self;

        [payPalDriver authorizeAccountWithCompletion:^(BTPayPalAccountNonce *tokenizedPayPalAccount, NSError *error) {
            NSMutableArray *args = @[[NSNull null]];
            if ( error == nil && tokenizedPayPalAccount != nil ) {
                args = [@[[NSNull null], tokenizedPayPalAccount.nonce, tokenizedPayPalAccount.email, tokenizedPayPalAccount.firstName, tokenizedPayPalAccount.lastName] mutableCopy];

                if (tokenizedPayPalAccount.phone != nil) {
                    [args addObject:tokenizedPayPalAccount.phone];
                }
            } else if ( error != nil ) {
                args = @[error.description, [NSNull null]];
            }

            callback(args);
        }];
    });
}

RCT_EXPORT_METHOD(getCardNonce: (NSDictionary *)parameters callback: (RCTResponseSenderBlock)callback)
{
    BTCardClient *cardClient = [[BTCardClient alloc] initWithAPIClient: self.braintreeClient];
    BTCard *card = [[BTCard alloc] initWithParameters:parameters];
    card.shouldValidate = YES;
    
    [cardClient tokenizeCard:card
                  completion:^(BTCardNonce *tokenizedCard, NSError *error) {
                      NSArray *args = @[];
                      
                      if ( error == nil ) {
                          args = @[[NSNull null], tokenizedCard.nonce];
                      } else {
                          NSMutableDictionary *userInfo = [error.userInfo mutableCopy];
                          
                          [userInfo removeObjectForKey:@"com.braintreepayments.BTHTTPJSONResponseBodyKey"];
                          [userInfo removeObjectForKey:@"com.braintreepayments.BTHTTPURLResponseKey"];
                          
                          NSError *serialisationErr;
                          NSData *jsonData = [NSJSONSerialization dataWithJSONObject:userInfo
                                                                             options:NSJSONWritingPrettyPrinted
                                                                               error:&serialisationErr];
                          
                          if (! jsonData) {
                              args = @[serialisationErr.description, [NSNull null]];
                          } else {
                              NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                              args = @[jsonString, [NSNull null]];
                          }
                      }
                      callback(args);
                  }];
}

RCT_EXPORT_METHOD(getCardNonceWithThreeDSecure: (NSDictionary *)parameters callback: (RCTResponseSenderBlock)callback)
{
    NSDecimalNumber *amount = parameters[@"amount"];
    NSDictionary *cardDetails = parameters[@"cardDetails"];

    BTCardClient *cardClient = [[BTCardClient alloc] initWithAPIClient: self.braintreeClient];
    BTCard *card = [[BTCard alloc] initWithParameters:cardDetails];
    card.shouldValidate = YES;
    
    [cardClient tokenizeCard:card completion:^(BTCardNonce *tokenizedCard, NSError *error) {
        __block NSArray *args = @[];
        
        if (error == nil) {
            BTThreeDSecureDriver *threeDSecure = [[BTThreeDSecureDriver alloc] initWithAPIClient:self.braintreeClient delegate:self];
            
            [threeDSecure verifyCardWithNonce:tokenizedCard.nonce amount:amount completion:^(BTThreeDSecureCardNonce * _Nullable threeDSecureCard, NSError * _Nullable error) {
                if (error) {
                    return callback(@[error.localizedDescription, [NSNull null]]);
                } else if (threeDSecureCard) {
                    if (threeDSecureCard.liabilityShifted)
                        return callback(@[[NSNull null], threeDSecureCard.nonce]);
                    else {
                        return callback(@[[NSNull null], tokenizedCard.nonce]);
                    }
                } else {
                    // User Cancelled
                    return callback(@[[NSNull null], [NSNull null]]);
                }
            }];
        } else {
            NSMutableDictionary *userInfo = [error.userInfo mutableCopy];

            [userInfo removeObjectForKey:@"com.braintreepayments.BTHTTPJSONResponseBodyKey"];
            [userInfo removeObjectForKey:@"com.braintreepayments.BTHTTPURLResponseKey"];

            NSError *serialisationErr;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:userInfo options:NSJSONWritingPrettyPrinted error:&serialisationErr];

            if (!jsonData) {
                args = @[serialisationErr.description, [NSNull null]];
            } else {
                NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                args = @[jsonString, [NSNull null]];
            }
            
            callback(args);
        }
    }];
}

RCT_EXPORT_METHOD(getNonceWithThreeDSecure: (NSDictionary *)parameters callback: (RCTResponseSenderBlock)callback)
{
    BTPaymentFlowDriver *paymentFlowDriver = [[BTPaymentFlowDriver alloc] initWithAPIClient:self.braintreeClient];
    paymentFlowDriver.viewControllerPresentingDelegate = self;
    
    NSDecimalNumber *amount = parameters[@"amount"];
    NSString *nonce = parameters[@"nonce"];
    
    BTThreeDSecureRequest *request = [[BTThreeDSecureRequest alloc] init];
    BTThreeDSecurePostalAddress *billingAddress = [BTThreeDSecurePostalAddress new];
    BTThreeDSecureAdditionalInformation *additionalInformation = [BTThreeDSecureAdditionalInformation new];
    
    request.amount = amount;
    request.nonce = nonce;
    request.versionRequested = BTThreeDSecureVersion2;

    // Make sure that self conforms to the BTThreeDSecureRequestDelegate protocol
    request.threeDSecureRequestDelegate = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [paymentFlowDriver startPaymentFlow:request completion:^(BTPaymentFlowResult * _Nonnull result, NSError * _Nonnull error) {
            if (error) {
                return callback(@[@"AUTHENTICATION_UNSUCCESSFUL", [NSNull null]]);
            } else if (result) {
                BTThreeDSecureResult *threeDSecureResult = (BTThreeDSecureResult *)result;

                if (threeDSecureResult.tokenizedCard.threeDSecureInfo.liabilityShiftPossible) {
                        // 3D Secure authentication success
                    return callback(@[[NSNull null], threeDSecureResult.tokenizedCard.nonce]);
                } else {
                    // 3D Secure authentication was not possible
                    return callback(@[@"AUTHENTICATION_NOT_POSSIBLE", [NSNull null]]);
                }
            }
        }];
    });
}

RCT_EXPORT_METHOD(getDeviceData:(NSDictionary *)options callback:(RCTResponseSenderBlock)callback)
{
    dispatch_async(dispatch_get_main_queue(), ^{

        NSLog(@"%@", options);

        NSError *error = nil;
        NSString *deviceData = nil;
        NSString *environment = options[@"environment"];
        NSString *dataSelector = options[@"dataCollector"];

        //Initialize the data collector and specify environment
        if([environment isEqualToString: @"development"]){
            self.dataCollector = [[BTDataCollector alloc]
                                  initWithEnvironment:BTDataCollectorEnvironmentDevelopment];
        } else if([environment isEqualToString: @"qa"]){
            self.dataCollector = [[BTDataCollector alloc]
                                  initWithEnvironment:BTDataCollectorEnvironmentQA];
        } else if([environment isEqualToString: @"sandbox"]){
            self.dataCollector = [[BTDataCollector alloc]
                                  initWithEnvironment:BTDataCollectorEnvironmentSandbox];
        }

        //Data collection methods
        if ([dataSelector isEqualToString: @"card"]){
            deviceData = [self.dataCollector collectCardFraudData];
        } else if ([dataSelector isEqualToString: @"both"]){
            deviceData = [self.dataCollector collectFraudData];
        } else if ([dataSelector isEqualToString: @"paypal"]){
            deviceData = [PPDataCollector collectPayPalDeviceData];
        } else {
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:@"Invalid data collector" forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"RCTBraintree" code:255 userInfo:details];
            NSLog (@"Invalid data collector. Use one of: card, paypal or both");
        }

        NSArray *args = @[];
        if ( error == nil ) {
            args = @[[NSNull null], deviceData];
        } else {
            args = @[error.description, [NSNull null]];
        }

        callback(args);
    });
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {

    if ([url.scheme localizedCaseInsensitiveCompare:URLScheme] == NSOrderedSame) {
        return [BTAppSwitch handleOpenURL:url sourceApplication:sourceApplication];
    }
    return NO;
}

#pragma mark - BTViewControllerPresentingDelegate

- (void)paymentDriver:(id)paymentDriver requestsPresentationOfViewController:(UIViewController *)viewController {
    [self.reactRoot presentViewController:viewController animated:YES completion:nil];
}

- (void)paymentDriver:(id)paymentDriver requestsDismissalOfViewController:(UIViewController *)viewController {
    if (!viewController.isBeingDismissed) {
        [viewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - BTDropInViewControllerDelegate

- (void)userDidCancelPayment {
    [self.reactRoot dismissViewControllerAnimated:YES completion:nil];
    runCallback = FALSE;
    self.callback(@[@"USER_CANCELLATION", [NSNull null]]);
}

- (void)dropInViewControllerWillComplete:(BTDropInViewController *)viewController {
    runCallback = TRUE;
}

- (void)dropInViewController:(BTDropInViewController *)viewController didSucceedWithTokenization:(BTPaymentMethodNonce *)paymentMethodNonce {
    // when the user pays for the first time with paypal, dropInViewControllerWillComplete is never called, yet the callback should be invoked.  the second condition checks for that
    if (runCallback || ([paymentMethodNonce.type isEqualToString:@"PayPal"] && [viewController.paymentMethodNonces count] == 1)) {
        if (self.threeDSecure) {
            [self.reactRoot dismissViewControllerAnimated:YES completion:nil];
            [self.threeDSecure verifyCardWithNonce:paymentMethodNonce.nonce
                                            amount:self.threeDSecureOptions[@"amount"]
                                        completion:^(BTThreeDSecureCardNonce *card, NSError *error) {
                                            if (runCallback) {
                                                runCallback = FALSE;
                                                if (error) {
                                                    self.callback(@[error.localizedDescription, [NSNull null]]);
                                                } else if (card) {
                                                    if (!card.liabilityShiftPossible) {
                                                        self.callback(@[@"3DSECURE_NOT_ABLE_TO_SHIFT_LIABILITY", [NSNull null]]);
                                                    } else if (!card.liabilityShifted) {
                                                        self.callback(@[@"3DSECURE_LIABILITY_NOT_SHIFTED", [NSNull null]]);
                                                    } else {
                                                        self.callback(@[[NSNull null], card.nonce]);
                                                    }
                                                } else {
                                                    self.callback(@[@"USER_CANCELLATION", [NSNull null]]);
                                                }
                                            }
                                            [self.reactRoot dismissViewControllerAnimated:YES completion:nil];
                                        }];
        } else {
            runCallback = FALSE;
            self.callback(@[[NSNull null], paymentMethodNonce.nonce]);
        }
    }
    
    if (!self.threeDSecure) {
        [self.reactRoot dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)dropInViewControllerDidCancel:(__unused BTDropInViewController *)viewController {
    self.callback(@[@"Drop-In ViewController Closed", [NSNull null]]);
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

- (UIViewController*)reactRoot {
    UIViewController *root  = [UIApplication sharedApplication].keyWindow.rootViewController;
    UIViewController *maybeModal = root.presentedViewController;

    UIViewController *modalRoot = root;

    if (maybeModal != nil) {
        modalRoot = maybeModal;
    }

    return modalRoot;
}

@end
