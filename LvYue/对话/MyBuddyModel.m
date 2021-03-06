//
//  MyBuddyModel.m
//  LvYue
//
//  Created by apple on 15/10/10.
//  Copyright (c) 2015年 OLFT. All rights reserved.
//

#import "MyBuddyModel.h"

@implementation MyBuddyModel

- (instancetype)initWithDict:(NSDictionary *)dict {
    if (self = [super init]) {
        self.buddyID = [NSString stringWithFormat:@"%@",dict[@"id"]];
        self.remark = [NSString stringWithFormat:@"%@",dict[@"remark"]];
        self.icon = [NSString stringWithFormat:@"%@%@",IMAGEHEADER,dict[@"icon"]];
        self.name = [NSString stringWithFormat:@"%@",dict[@"name"]];
    }
    return self;
}


+ (instancetype)myBuddyModelWithDict:(NSDictionary *)dict {
    return [[self alloc] initWithDict:dict];
}


@end
