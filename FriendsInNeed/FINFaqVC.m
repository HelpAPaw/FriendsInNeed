//
//  FINFaqVC.m
//  FriendsInNeed
//
//  Created by Milen on 17/12/16.
//  Copyright © 2016 Milen. All rights reserved.
//

#import "FINFaqVC.h"
#import "FINFaqCell.h"

#define kQuestionCellIdentifier @"QuestionCellIdentifier"

@interface FINQnA : NSObject

@property (strong) NSString *question;
@property (strong) NSString *answer;

@end

@implementation FINQnA

@end

@interface FINFaqVC () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong) NSMutableArray *questionsAndAnswers;

@end

@implementation FINFaqVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    _tableView.contentInset = UIEdgeInsetsMake(_closeButton.frame.size.height + 10, 0, 0, 0);
    [_tableView registerNib:[UINib nibWithNibName:@"FINFaqCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:kQuestionCellIdentifier];
    
    _questionsAndAnswers = [NSMutableArray new];
    for (int i = 0; i < 5; i++) {
        FINQnA *qna = [FINQnA new];
        qna.question = @"This is a question?";
        qna.answer = @"And this is an answer?";
        [_questionsAndAnswers addObject:qna];
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
- (IBAction)onCloseButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _questionsAndAnswers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FINFaqCell *cell = [tableView dequeueReusableCellWithIdentifier:kQuestionCellIdentifier];
    
    FINQnA *qna = _questionsAndAnswers[indexPath.row];
    [cell setQuestion:qna.question];
    [cell setAnswer:qna.answer];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 113.0;
}

@end
