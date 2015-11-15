//
//  ViewController.m
//  WebViewImageClick
//
//  Created by 杨萧玉 on 15/10/18.
//  Copyright © 2015年 杨萧玉. All rights reserved.
//

#import "ViewController.h"
#import "IDMPhotoBrowser.h"
#import "NSData+Base64Additions.h"

@interface ViewController () <UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _webView.dataDetectorTypes = UIDataDetectorTypeLink;
    _webView.userInteractionEnabled = YES;
    _webView.delegate = self;
    _webView.scrollView.bounces = NO;
    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.doubanmeizi.com"]]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)addJavaScript {
    NSString *clickGirl =
    @"function setImage(){\
        var imgs = document.getElementsByTagName(\"img\");\
        for (var i=0;i<imgs.length;i++){\
            imgs[i].setAttribute(\"onClick\",\"imageClick(\"+i+\")\");\
        }\
    }\
    function imageClick(i){\
        var rect = getImageRect(i);\
        var url=\"clickgirl::\"+i+\"::\"+rect;\
        document.location = url;\
    }\
    function getImageRect(i){\
        var imgs = document.getElementsByTagName(\"img\");\
        var rect;\
        rect = imgs[i].getBoundingClientRect().left+\"::\";\
        rect = rect+imgs[i].getBoundingClientRect().top+\"::\";\
        rect = rect+imgs[i].width+\"::\";\
        rect = rect+imgs[i].height;\
        return rect;\
    }\
    function getAllImageUrl(){\
        var imgs = document.getElementsByTagName(\"img\");\
        var urlArray = [];\
        for (var i=0;i<imgs.length;i++){\
            var src = imgs[i].src;\
            urlArray.push(src);\
        }\
        return urlArray.toString();\
    }\
    function getImageData(i){\
        var imgs = document.getElementsByTagName(\"img\");\
        var img=imgs[i]; \
        var canvas=document.createElement(\"canvas\"); \
        var context=canvas.getContext(\"2d\"); \
        canvas.width=img.width; canvas.height=img.height; \
        context.drawImage(img,0,0,img.width,img.height); \
        return canvas.toDataURL(\"image/png\") \
    }";
    [_webView stringByEvaluatingJavaScriptFromString:clickGirl];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    [self addJavaScript];
    [webView stringByEvaluatingJavaScriptFromString:@"setImage();"];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSString *requestString = [[request URL] absoluteString];
    if ([requestString hasPrefix:@"http://pos.baidu.com"]) {// ignore baidu ad
        return NO;
    }
    NSArray *components = [requestString componentsSeparatedByString:@"::"];
    if ([components[0] isEqualToString:@"clickgirl"]) {
        int imgIndex = [components[1] intValue];
        CGRect frame = CGRectMake([components[2] floatValue], [components[3] floatValue], [components[4] floatValue], [components[5] floatValue]);
        UIImageView *showView = [[UIImageView alloc] initWithFrame:frame];
        NSString *javascript = [NSString stringWithFormat:
                                @"getImageData(%d);", imgIndex];
        NSString *stringData = [webView stringByEvaluatingJavaScriptFromString:javascript];
        stringData = [stringData substringFromIndex:22]; // strip the string "data:image/png:base64,"
        NSData *data = [NSData decodeWebSafeBase64ForString:stringData];
        UIImage *image = [UIImage imageWithData:data];
        showView.image = image;
        [_webView addSubview:showView];
        
        NSString *urls = [_webView stringByEvaluatingJavaScriptFromString:@"getAllImageUrl();"];
        IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:[IDMPhoto photosWithURLs:[urls componentsSeparatedByString:@","]] animatedFromView:showView];
        [browser setInitialPageIndex:imgIndex];
        browser.useWhiteBackgroundColor = YES;
        [self presentViewController:browser animated:YES completion:nil];
        [showView removeFromSuperview];
        
    }
    return YES;
}
@end
