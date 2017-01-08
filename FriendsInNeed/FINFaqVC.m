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

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *toolbar;
@property (strong) NSMutableArray *questionsAndAnswers;

@end

@implementation FINFaqVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    _toolbar.layer.shadowColor = [UIColor lightGrayColor].CGColor;
    _toolbar.layer.shadowOpacity = 1.0f;
    _toolbar.layer.shadowOffset = (CGSize){0.0f, 2.0f};
    
    _tableView.contentInset = UIEdgeInsetsMake(15, 0, 0, 0);
    _tableView.rowHeight = UITableViewAutomaticDimension;
    _tableView.estimatedRowHeight = 100;
    [_tableView registerNib:[UINib nibWithNibName:@"FINFaqCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:kQuestionCellIdentifier];
    
    _questionsAndAnswers = [NSMutableArray new];
    for (int i = 0; i < 4; i++) {
        FINQnA *qna = [FINQnA new];
        NSString *question = [NSString stringWithFormat:@"Q%d", i+1];
        NSString *answer   = [NSString stringWithFormat:@"A%d", i+1];
        qna.question = NSLocalizedString(question, nil);
        qna.answer = NSLocalizedString(answer, nil);
        [_questionsAndAnswers addObject:qna];
    }
}

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
    
    cell.backgroundColor = [UIColor clearColor];
    
    FINQnA *qna = _questionsAndAnswers[indexPath.row];
    [cell setQuestion:qna.question];
    [cell setAnswer:qna.answer];
    
    return cell;
}

@end
