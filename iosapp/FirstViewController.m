//
//  FirstViewController.m
//  iosapp
//
//  Copyright © 2016 Destiny Media Technologies. All rights reserved.
//

/*
    This code connects to api.clipstream.com showing the usage of:
    
    1) authentication - retrieves an authtoken
    2) upload video - request to upload then upload
 
    In this example, 3rd party libraries were not used or required.
*/

#import "FirstViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "AppDelegate.h"


@interface FirstViewController ()
@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UIButton *findvideobutton;


@end

@implementation FirstViewController

NSString * authtoken = nil;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.findvideobutton setEnabled:false];
    
    self.username.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
    self.password.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"password"];
}

- (IBAction)verifyPassword:(id)sender {
    
    NSString *post = [NSString stringWithFormat:@"{\"username\":\"%@\", \"password\":\"%@\"}",
                      self.username.text, self.password.text
                      ];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
    
    //STEP1: authenticate and get an authtoken
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:@"https://api.clipstream.com/account/login"]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    
    dispatch_async(dispatch_get_main_queue(),^ {
        [self.findvideobutton setEnabled:false];
    });
    authtoken = nil;
    
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    app.authtoken = authtoken;
    
    
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSString *requestReply = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        
        NSData *jsonData = [requestReply dataUsingEncoding:NSUTF8StringEncoding];
        NSError *e;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&e];
        
        if (dict){
            authtoken = [dict valueForKey:@"authtoken"];
            
            AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            app.authtoken = authtoken;
            
            if (authtoken != nil){
                dispatch_async(dispatch_get_main_queue(),^ {
                    [self.findvideobutton setEnabled:true];
                });
                
                NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                [userDefaults setObject:self.username.text forKey:@"username"];
                [userDefaults setObject:self.password.text forKey:@"password"];
                [userDefaults synchronize];
            }
        }
        
        NSLog(@"requestReply: %@", requestReply);
        
        if (authtoken == nil){
            dispatch_async(dispatch_get_main_queue(),^ {
                UIAlertController * alert=   [UIAlertController
                                              alertControllerWithTitle:@"Authentication"
                                              message:@"Wrong username or password"
                                              preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction* ok = [UIAlertAction
                                     actionWithTitle:@"OK"
                                     style:UIAlertActionStyleDefault
                                     handler:^(UIAlertAction * action)
                                     {
                                         [alert dismissViewControllerAnimated:YES completion:nil];
                                         
                                     }];
                [alert addAction:ok];
                [self presentViewController:alert animated:YES completion:nil];
            });
        }
    }] resume];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)uploadVideo:(id)sender {
    //STEP2: select a video to upload
    UIImagePickerController *videoPicker = [[UIImagePickerController alloc] init];
    videoPicker.delegate = self;
    videoPicker.modalPresentationStyle = UIModalPresentationCurrentContext;
    videoPicker.mediaTypes =[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    videoPicker.mediaTypes = @[(NSString*)kUTTypeMovie, (NSString*)kUTTypeAVIMovie, (NSString*)kUTTypeVideo, (NSString*)kUTTypeMPEG4];
    videoPicker.videoQuality = UIImagePickerControllerQualityTypeHigh;
    [self presentViewController:videoPicker animated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

/*
 
 https://github.com/nevyn/URLSessionTest
 http://hayageek.com/ios-background-task/
 
 */

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    NSURL *videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
    //NSString *assetType = [info objectForKey:UIImagePickerControllerMediaType];
    NSData *movieData = [NSData dataWithContentsOfURL:videoURL];
        
    NSString *post = [NSString stringWithFormat:@"{\"title\":\"%@\", \"filename\":\"%@\", \"callback\":\"\"}",
                      @"ios video",     // get the title or use this default
                      @"untitled.mov"   // get the filename or use this default
                      ];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
    

    //STEP 3: request to upload a video
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:@"https://api.clipstream.com/video"]];
    [request setHTTPMethod:@"POST"];
    [request setValue:authtoken forHTTPHeaderField:@"Authorization"];
    [request setValue:@"1234" forHTTPHeaderField:@"X-AppId"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    
    NSLog(@"%@", [request allHTTPHeaderFields]);
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    
        
        NSLog(@"POST /video request to upload\n");
        if (error) {
            NSLog(@"Failed request\n");
            return;
        }
        
        //STEP4: retrieve the uploadurl to send the video file
        NSString *requestReply = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        NSData *jsonData = [requestReply dataUsingEncoding:NSUTF8StringEncoding];
        NSError *e;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&e];
        if (dict){
            NSString * uploadurl = [dict valueForKey:@"uploadurl"];
            
            //STEP5: upload the video to the url
            NSMutableURLRequest *request2 = [[NSMutableURLRequest alloc] init];
            [request2 setURL:[NSURL URLWithString:uploadurl]];
            [request2 setHTTPMethod:@"PUT"];
            //[request2 setValue:@"video/quicktime" forHTTPHeaderField:@"Content-Type"];
            [request2 setValue:[NSString stringWithFormat:@"%ld",(unsigned long)[movieData length]] forHTTPHeaderField:@"Content-Length"];
            [request2 setHTTPBody:movieData];
            
            NSLog(@"%@", [request2 allHTTPHeaderFields]);
            NSLog(@"%@", request2);
            
            // start up the proces
            __block UIAlertController * progress;
            dispatch_async(dispatch_get_main_queue(),^ {
                progress =   [UIAlertController
                                              alertControllerWithTitle:@"Uploading"
                                              message: @"please wait..."
                                              preferredStyle:UIAlertControllerStyleAlert];
                [self presentViewController:progress animated:YES completion:nil];
            });
            
            NSURLSession *session2 = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
            [[session2 dataTaskWithRequest:request2 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                
                dispatch_async(dispatch_get_main_queue(),^ {
                    [progress dismissViewControllerAnimated:YES completion:nil];
                });
                
                NSLog(@"PUT /video actual upload\n");
                if (error) {
                    NSLog(@"Failed to upload the file\n");
                    dispatch_async(dispatch_get_main_queue(),^ {
                        UIAlertController * alert=   [UIAlertController
                                                      alertControllerWithTitle:@"Upload Failed"
                                                      message: error.description
                                                      preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction* ok = [UIAlertAction
                                             actionWithTitle:@"OK"
                                             style:UIAlertActionStyleCancel
                                             handler:^(UIAlertAction * action)
                                             {
                                                 [alert dismissViewControllerAnimated:YES completion:nil];
                                                 
                                             }];
                        [alert addAction:ok];
                        [self presentViewController:alert animated:YES completion:nil];
                    });
                } else {
                    NSLog(@"SUCCESS uploading the file\n");
                    dispatch_async(dispatch_get_main_queue(),^ {
                        UIAlertController * alert=   [UIAlertController
                                                      alertControllerWithTitle:@"Upload Complete"
                                                      message: @"The video was uploaded successfully"
                                                      preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction* ok = [UIAlertAction
                                             actionWithTitle:@"OK"
                                             style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction * action)
                                             {
                                                 [alert dismissViewControllerAnimated:YES completion:nil];
                                                 
                                             }];
                        [alert addAction:ok];
                        [self presentViewController:alert animated:YES completion:nil];
                    });
                }
                
                NSLog(@"Background Complete Up\n");
                
                
            }] resume];
            
        } else {
            //FAILED
            NSLog(@"No uploadurl found\n");
            NSLog(@"Background Complete Up\n");
        }
        
        NSLog(@"requestReply: %@", requestReply);
    }] resume];
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

@end
