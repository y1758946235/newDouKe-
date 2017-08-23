//
//  GoldsRecordTableViewCell.m
//  LvYue
//
//  Created by X@Han on 17/7/21.
//  Copyright © 2017年 OLFT. All rights reserved.
//

#import "GoldsRecordTableViewCell.h"
#import "otherZhuYeVC.h"
@implementation GoldsRecordTableViewCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self createUI];
    }
    return self;
    
}
-(void)removeAllSubviews{
    for (UIView *view in self.contentView.subviews) {
        [view removeFromSuperview];
    }
}
-(void)createUI{
    
    UIImageView *headimageV = [[UIImageView alloc]init];
    headimageV.frame = CGRectMake(SCREEN_WIDTH-62, 16, 38, 38);
    headimageV.layer.cornerRadius = 19;
    headimageV.clipsToBounds = YES;
    headimageV.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(gotToOtherHome)];
    [headimageV addGestureRecognizer:tap];
    [self.contentView addSubview:headimageV];
    self.headImageV = headimageV;
    
    
    UILabel * nickNameLabel = [[UILabel alloc]init];
    nickNameLabel.frame = CGRectMake(SCREEN_WIDTH-86, 70, 86, 20);
    nickNameLabel.text = @"Deborah";
    nickNameLabel.textAlignment = NSTextAlignmentCenter;
    nickNameLabel.font = [UIFont fontWithName:@"PingFangSC-Light" size:12];
    nickNameLabel.textColor = [UIColor colorWithHexString:@"#757575"];
    [self.contentView addSubview:nickNameLabel];
    self.nameLabel = nickNameLabel;
    
    UILabel * userGoldsLabel = [[UILabel alloc]init];
    userGoldsLabel.frame = CGRectMake(100, 42, SCREEN_WIDTH-200, 22);
    userGoldsLabel.textAlignment = NSTextAlignmentCenter;
    userGoldsLabel.font = [UIFont fontWithName:@"PingFangSC-Light" size:14];
    userGoldsLabel.textColor = [UIColor colorWithHexString:@"#757575"];
    [self.contentView addSubview:userGoldsLabel];
    self.userGoldsLabel = userGoldsLabel;
    
    UILabel * creatTimeLabel = [[UILabel alloc]init];
    creatTimeLabel.frame = CGRectMake(24, 22, 180, 22);
    creatTimeLabel.text = @"217-1-6";
    creatTimeLabel.textAlignment = NSTextAlignmentLeft;
    creatTimeLabel.font = [UIFont fontWithName:@"PingFangSC-Light" size:12];
    creatTimeLabel.textColor = [UIColor colorWithHexString:@"#757575"];
    [self.contentView addSubview: creatTimeLabel];
    self.creatTimeLabel = creatTimeLabel;
    
    
    UILabel * typeLabel = [[UILabel alloc]init];
    typeLabel.frame = CGRectMake(24, 62, 180, 22);
    typeLabel.textAlignment = NSTextAlignmentLeft;
    typeLabel.font = [UIFont fontWithName:@"PingFangSC-Light" size:14];
//    typeLabel.textColor = [UIColor colorWithHexString:@"#bdbdbd"];
    typeLabel.textColor = [UIColor colorWithHexString:@"#ff5252"];
    [self.contentView addSubview: typeLabel];
    self.typeLabel = typeLabel;

}

-(void)gotToOtherHome{
   
    
    if ([[NSString stringWithFormat:@"%@",[CommonTool getUserID]] isEqualToString:[NSString stringWithFormat:@"%@",_model.userId]]) {
       
        otherZhuYeVC *vc = [[otherZhuYeVC alloc]init];
        vc.userNickName = _model.otherUserNickname;
        vc.userId = _model.otherUserId;
        [self.viewController.navigationController pushViewController:vc animated:YES];
        
    }else{
        otherZhuYeVC *vc = [[otherZhuYeVC alloc]init];
        vc.userNickName = _model.userNickname;
        vc.userId = _model.userId;
        [self.viewController.navigationController pushViewController:vc animated:YES];
    }
   
}

- (void)createCell:(GoldsRecordModel *)model{
    _model = model;
    NSURL *headUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",IMAGEHEADER,_model.userIcon]];
    [self.headImageV sd_setImageWithURL:headUrl];
    self.nameLabel.text = _model.userNickname;
    self.userGoldsLabel.text = [NSString stringWithFormat:@"消耗%@金币",_model.userGold];
    self.creatTimeLabel.text = [CommonTool timestampSwitchTime:[_model.createTime doubleValue]/1000 andFormatter:@"YYYY-MM-dd"];
    //    self.spendGoldLabel.text = [NSString stringWithFormat:@"花费%@金币",_model.goldPrice];
    NSInteger type = [_model.type integerValue];
    switch (type) {
        case 0:
            self.typeLabel.text = @"聊天";
            break;
        case 1:
            self.typeLabel.text = @"获取联系方式";
            break;
            
        case 2:
            self.typeLabel.text = @"查看认证视频";
            break;
            
        case 3:
            self.typeLabel.text = @"查看精华照片";
            break;
            
        case 4:
            self.typeLabel.text = @"查看看法";
            break;
            
        case 5:
            self.typeLabel.text = @"赠送礼物";
            break;
            
        case 6:
            self.typeLabel.text = @"视频通话";
            break;
            
        default:
            break;
    }
   

}

- (void)createCallRecordModel:(GoldsRecordModel *)model{
    _model = model;
    
    if ([[NSString stringWithFormat:@"%@",[CommonTool getUserID]] isEqualToString:[NSString stringWithFormat:@"%@",_model.userId]]) {
       self.userGoldsLabel.text = @"呼出";
        NSURL *headUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",IMAGEHEADER,_model.otherUserIcon]];
        [self.headImageV sd_setImageWithURL:headUrl];
        self.nameLabel.text = _model. otherUserNickname;
        
    }else{
      self.userGoldsLabel.text = @"呼入";
        NSURL *headUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",IMAGEHEADER,_model.userIcon]];
        [self.headImageV sd_setImageWithURL:headUrl];
        self.nameLabel.text = _model.userNickname;
    }
    
    self.creatTimeLabel.text = [CommonTool timestampSwitchTime:[_model.createTime doubleValue]/1000 andFormatter:@"YYYY-MM-dd"];
    self.typeLabel.text =  [NSString stringWithFormat:@"%@秒",_model.videoTime];
    self.typeLabel.textColor = [UIColor colorWithHexString:@"#bdbdbd"];
}
- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
