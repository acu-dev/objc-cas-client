//
//  CASViewController.h
//  CAS Client
//
//  Created by Andrew Clissold on 3/5/14.
//  Copyright (c) 2014 Abilene Christian University. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CASViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *authResultMessage;
@property (weak, nonatomic) IBOutlet UILabel *requestResultMessage;
@property (weak, nonatomic) IBOutlet UILabel *requestResultBody;
@property (weak, nonatomic) IBOutlet UILabel *logoutResultMessage;
@end
