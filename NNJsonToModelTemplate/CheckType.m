//
//  CheckType.m
//  NNJsonToModelTemplate
//
//  Created by olddevil on 2022/10/2.
//

#import "CheckType.h"

@implementation CheckType

+ (NSString *)of: (id)value {
    NSString *type = [NSString stringWithFormat:@"%@", [value class]];
    return type;
}

@end
