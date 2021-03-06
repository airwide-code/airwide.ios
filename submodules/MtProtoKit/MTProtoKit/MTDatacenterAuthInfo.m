#import "MTDatacenterAuthInfo.h"
#import "MTDatacenterSaltInfo.h"

@implementation MTDatacenterAuthKey

- (instancetype)initWithAuthKey:(NSData *)authKey authKeyId:(int64_t)authKeyId {
    self = [super init];
    if (self != nil) {
        _authKey = authKey;
        _authKeyId = authKeyId;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    return [self initWithAuthKey:[aDecoder decodeObjectForKey:@"key"] authKeyId:[aDecoder decodeInt64ForKey:@"keyId"]];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_authKey forKey:@"key"];
    [aCoder encodeInt64:_authKeyId forKey:@"keyId"];
}

@end

@implementation MTDatacenterAuthInfo

- (instancetype)initWithAuthKey:(NSData *)authKey authKeyId:(int64_t)authKeyId saltSet:(NSArray *)saltSet authKeyAttributes:(NSDictionary *)authKeyAttributes tempAuthKey:(MTDatacenterAuthKey *)tempAuthKey
{
    self = [super init];
    if (self != nil)
    {
        _authKey = authKey;
        _authKeyId = authKeyId;
        _saltSet = saltSet;
        _authKeyAttributes = authKeyAttributes;
        _tempAuthKey = tempAuthKey;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self != nil)
    {
        _authKey = [aDecoder decodeObjectForKey:@"authKey"];
        _authKeyId = [aDecoder decodeInt64ForKey:@"authKeyId"];
        _saltSet = [aDecoder decodeObjectForKey:@"saltSet"];
        _authKeyAttributes = [aDecoder decodeObjectForKey:@"authKeyAttributes"];
        _tempAuthKey = [aDecoder decodeObjectForKey:@"tempAuthKey"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_authKey forKey:@"authKey"];
    [aCoder encodeInt64:_authKeyId forKey:@"authKeyId"];
    [aCoder encodeObject:_saltSet forKey:@"saltSet"];
    [aCoder encodeObject:_authKeyAttributes forKey:@"authKeyAttributes"];
    [aCoder encodeObject:_tempAuthKey forKey:@"tempAuthKey"];
}

- (int64_t)authSaltForMessageId:(int64_t)messageId
{
    int64_t bestSalt = 0;
    int64_t bestValidMessageCount = 0;
    
    for (MTDatacenterSaltInfo *saltInfo in _saltSet)
    {
        int64_t currentValidMessageCount = [saltInfo validMessageCountAfterId:messageId];
        if (currentValidMessageCount != 0 && currentValidMessageCount > bestValidMessageCount)
            bestSalt = saltInfo.salt;
    }
    
    return bestSalt;
}

- (MTDatacenterAuthInfo *)mergeSaltSet:(NSArray *)updatedSaltSet forTimestamp:(NSTimeInterval)timestamp
{
    int64_t referenceMessageId = (int64_t)(timestamp * 4294967296);
    
    NSMutableArray *mergedSaltSet = [[NSMutableArray alloc] init];
    
    for (MTDatacenterSaltInfo *saltInfo in _saltSet)
    {
        if ([saltInfo isValidFutureSaltForMessageId:referenceMessageId])
            [mergedSaltSet addObject:saltInfo];
    }
    
    for (MTDatacenterSaltInfo *saltInfo in updatedSaltSet)
    {
        bool alreadExists = false;
        for (MTDatacenterSaltInfo *existingSaltInfo in mergedSaltSet)
        {
            if (existingSaltInfo.firstValidMessageId == saltInfo.firstValidMessageId)
            {
                alreadExists = true;
                break;
            }
        }
        
        if (!alreadExists)
        {
            if ([saltInfo isValidFutureSaltForMessageId:referenceMessageId])
                [mergedSaltSet addObject:saltInfo];
        }
    }
    
    return [[MTDatacenterAuthInfo alloc] initWithAuthKey:_authKey authKeyId:_authKeyId saltSet:mergedSaltSet authKeyAttributes:_authKeyAttributes tempAuthKey:_tempAuthKey];
}

- (MTDatacenterAuthInfo *)withUpdatedTempAuthKey:(MTDatacenterAuthKey *)tempAuthKey {
    return [[MTDatacenterAuthInfo alloc] initWithAuthKey:_authKey authKeyId:_authKeyId saltSet:_saltSet authKeyAttributes:_authKeyAttributes tempAuthKey:tempAuthKey];
}

@end
