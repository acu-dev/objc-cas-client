#import <UIKit/UIKit.h>

@interface CASViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *authResultMessage;
@property (weak, nonatomic) IBOutlet UILabel *requestResultMessage;
@property (weak, nonatomic) IBOutlet UILabel *requestResultBody;
@property (weak, nonatomic) IBOutlet UILabel *logoutResultMessage;
@end
