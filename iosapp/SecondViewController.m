//
//  SecondViewController.m
//  iosapp
//
//  Copyright © 2016 Destiny Media Technologies. All rights reserved.
//

#import "SecondViewController.h"

/*
 This code connects to api.clipstream.com showing the usage of:
 
 1) retrieving a list of videos
 2) retrieving the title image of each video
 
 In this example, 3rd party libraries were not used or required.
 */


@interface SecondViewController ()
@property (weak, nonatomic) IBOutlet UIWebView *web;

@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSMutableURLRequest * request =[NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://www.clipstream.com"]];
    [self.web loadRequest:request];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
