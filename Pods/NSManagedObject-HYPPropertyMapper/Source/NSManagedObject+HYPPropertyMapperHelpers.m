#import "NSManagedObject+HYPPropertyMapperHelpers.h"

#import "NSManagedObject+HYPPropertyMapper.h"
#import "NSString+HYPNetworking.h"
#import "NSEntityDescription+SYNCPrimaryKey.h"
@import DateParser;

@implementation NSManagedObject (HYPPropertyMapperHelpers)

- (id)valueForAttributeDescription:(NSAttributeDescription *)attributeDescription
                     dateFormatter:(NSDateFormatter *)dateFormatter
                  relationshipType:(HYPPropertyMapperRelationshipType)relationshipType {
    id value;
    if (attributeDescription.attributeType != NSTransformableAttributeType) {
        value = [self valueForKey:attributeDescription.name];
        BOOL nilOrNullValue = (!value ||
                               [value isKindOfClass:[NSNull class]]);
        NSString *customTransformerName = attributeDescription.userInfo[HYPPropertyMapperCustomValueTransformerKey];
        if (nilOrNullValue) {
            value = [NSNull null];
        } else if ([value isKindOfClass:[NSDate class]]) {
            value = [dateFormatter stringFromDate:value];
        } else if (customTransformerName) {
            NSValueTransformer *transformer = [NSValueTransformer valueTransformerForName:customTransformerName];
            if (transformer) {
                value = [transformer reverseTransformedValue:value];
            }
        }
    }

    return value;
}

- (NSAttributeDescription *)attributeDescriptionForRemoteKey:(NSString *)remoteKey {
    __block NSAttributeDescription *foundAttributeDescription;

    [self.entity.properties enumerateObjectsUsingBlock:^(id propertyDescription, NSUInteger idx, BOOL *stop) {
        if ([propertyDescription isKindOfClass:[NSAttributeDescription class]]) {
            NSAttributeDescription *attributeDescription = (NSAttributeDescription *)propertyDescription;

            NSDictionary *userInfo = [self.entity.propertiesByName[attributeDescription.name] userInfo];
            NSString *customRemoteKey = userInfo[HYPPropertyMapperCustomRemoteKey];
            BOOL currentAttributeHasTheSameRemoteKey = (customRemoteKey.length > 0 && [customRemoteKey isEqualToString:remoteKey]);
            if (currentAttributeHasTheSameRemoteKey) {
                foundAttributeDescription = attributeDescription;
                *stop = YES;
            }
            
            NSString *customRootRemoteKey = [[customRemoteKey componentsSeparatedByString:@"."] firstObject];
            BOOL currentAttributeHasTheSameRootRemoteKey = (customRootRemoteKey.length > 0 && [customRootRemoteKey isEqualToString:remoteKey]);
            if (currentAttributeHasTheSameRootRemoteKey) {
                foundAttributeDescription = attributeDescription;
                *stop = YES;
            }
            
            if ([attributeDescription.name isEqualToString:remoteKey]) {
                foundAttributeDescription = attributeDescription;
                *stop = YES;
            }

            NSString *localKey = [remoteKey hyp_localString];
            BOOL isReservedKey = ([[NSManagedObject reservedAttributes] containsObject:remoteKey]);
            if (isReservedKey) {
                NSString *prefixedRemoteKey = [self prefixedAttribute:remoteKey];
                localKey = [prefixedRemoteKey hyp_localString];
            }

            if ([attributeDescription.name isEqualToString:localKey]) {
                foundAttributeDescription = attributeDescription;
                *stop = YES;
            }
        }
    }];

    if (!foundAttributeDescription) {
        [self.entity.properties enumerateObjectsUsingBlock:^(id propertyDescription, NSUInteger idx, BOOL *stop) {
            if ([propertyDescription isKindOfClass:[NSAttributeDescription class]]) {
                NSAttributeDescription *attributeDescription = (NSAttributeDescription *)propertyDescription;

                if ([remoteKey isEqualToString:SYNCDefaultRemotePrimaryKey] &&
                    ([attributeDescription.name isEqualToString:SYNCDefaultLocalPrimaryKey] || [attributeDescription.name isEqualToString:SYNCDefaultLocalCompatiblePrimaryKey])) {
                    foundAttributeDescription = self.entity.propertiesByName[attributeDescription.name];
                }

                if (foundAttributeDescription) {
                    *stop = YES;
                }
            }
        }];
    }

    return foundAttributeDescription;
}

- (NSArray *)attributeDescriptionsForRemoteKeyPath:(NSString *)remoteKey {
    __block NSMutableArray *foundAttributeDescriptions = [NSMutableArray array];
    
    [self.entity.properties enumerateObjectsUsingBlock:^(id propertyDescription, NSUInteger idx, BOOL *stop) {
        if ([propertyDescription isKindOfClass:[NSAttributeDescription class]]) {
            NSAttributeDescription *attributeDescription = (NSAttributeDescription *)propertyDescription;
            
            NSDictionary *userInfo = [self.entity.propertiesByName[attributeDescription.name] userInfo];
            NSString *customRemoteKeyPath = userInfo[HYPPropertyMapperCustomRemoteKey];
            NSString *customRootRemoteKey = [[customRemoteKeyPath componentsSeparatedByString:@"."] firstObject];
            NSString *rootRemoteKey = [[remoteKey componentsSeparatedByString:@"."] firstObject];
            BOOL currentAttributeHasTheSameRootRemoteKey = (customRootRemoteKey.length > 0 && [customRootRemoteKey isEqualToString:rootRemoteKey]);
            if (currentAttributeHasTheSameRootRemoteKey) {
                [foundAttributeDescriptions addObject:attributeDescription];
            }
        }
    }];
    
    return foundAttributeDescriptions;
}

- (NSString *)remoteKeyForAttributeDescription:(NSAttributeDescription *)attributeDescription {
    return [self remoteKeyForAttributeDescription:attributeDescription usingRelationshipType:HYPPropertyMapperRelationshipTypeNested];
}

- (NSString *)remoteKeyForAttributeDescription:(NSAttributeDescription *)attributeDescription usingRelationshipType:(HYPPropertyMapperRelationshipType)relationshipType {
    NSDictionary *userInfo = attributeDescription.userInfo;
    NSString *localKey = attributeDescription.name;
    NSString *remoteKey;

    NSString *customRemoteKey = userInfo[HYPPropertyMapperCustomRemoteKey];
    if (customRemoteKey) {
        remoteKey = customRemoteKey;
    } else if ([localKey isEqualToString:SYNCDefaultLocalPrimaryKey] || [localKey isEqualToString:SYNCDefaultLocalCompatiblePrimaryKey]) {
        remoteKey = SYNCDefaultRemotePrimaryKey;
    } else if ([localKey isEqualToString:HYPPropertyMapperDestroyKey] &&
               relationshipType == HYPPropertyMapperRelationshipTypeNested) {
        remoteKey = [NSString stringWithFormat:@"_%@", HYPPropertyMapperDestroyKey];
    } else {
        remoteKey = [localKey hyp_remoteString];
    }

    BOOL isReservedKey = ([[self reservedKeys] containsObject:remoteKey]);
    if (isReservedKey) {
        NSMutableString *prefixedKey = [remoteKey mutableCopy];
        [prefixedKey replaceOccurrencesOfString:[self remotePrefix]
                                     withString:@""
                                        options:NSCaseInsensitiveSearch
                                          range:NSMakeRange(0, prefixedKey.length)];
        remoteKey = [prefixedKey copy];
    }

    return remoteKey;
}

- (id)valueForAttributeDescription:(NSAttributeDescription *)attributeDescription
                  usingRemoteValue:(id)remoteValue {
    id value;

    Class attributedClass = NSClassFromString([attributeDescription attributeValueClassName]);

    if ([remoteValue isKindOfClass:attributedClass]) {
        value = remoteValue;
    }

    NSString *customTransformerName = attributeDescription.userInfo[HYPPropertyMapperCustomValueTransformerKey];
    if (customTransformerName) {
        NSValueTransformer *transformer = [NSValueTransformer valueTransformerForName:customTransformerName];
        if (transformer) {
            value = [transformer transformedValue:value];
        }
    }

    BOOL stringValueAndNumberAttribute  = ([remoteValue isKindOfClass:[NSString class]] &&
                                          attributedClass == [NSNumber class]);

    BOOL numberValueAndStringAttribute  = ([remoteValue isKindOfClass:[NSNumber class]] &&
                                          attributedClass == [NSString class]);

    BOOL stringValueAndDateAttribute    = ([remoteValue isKindOfClass:[NSString class]] &&
                                          attributedClass == [NSDate class]);

    BOOL numberValueAndDateAttribute    = ([remoteValue isKindOfClass:[NSNumber class]] &&
                                          attributedClass == [NSDate class]);

    BOOL dataAttribute                  = (attributedClass == [NSData class]);

    BOOL numberValueAndDecimalAttribute = ([remoteValue isKindOfClass:[NSNumber class]] &&
                                           attributedClass == [NSDecimalNumber class]);

    BOOL stringValueAndDecimalAttribute = ([remoteValue isKindOfClass:[NSString class]] &&
                                           attributedClass == [NSDecimalNumber class]);

    BOOL transformableAttribute         = (!attributedClass && [attributeDescription valueTransformerName] && value == nil);

    if (stringValueAndNumberAttribute) {
        NSNumberFormatter *formatter = [NSNumberFormatter new];
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
        value = [formatter numberFromString:remoteValue];
    } else if (numberValueAndStringAttribute) {
        value = [NSString stringWithFormat:@"%@", remoteValue];
    } else if (stringValueAndDateAttribute) {
        value = [NSDate dateFromDateString:remoteValue];
    } else if (numberValueAndDateAttribute) {
        value = [NSDate dateFromUnixTimestampNumber:remoteValue];
    } else if (dataAttribute) {
        value = [NSKeyedArchiver archivedDataWithRootObject:remoteValue];
    } else if (numberValueAndDecimalAttribute) {
        NSNumber *number = (NSNumber *)remoteValue;
        value = [NSDecimalNumber decimalNumberWithDecimal:[number decimalValue]];
    } else if (stringValueAndDecimalAttribute) {
        value = [NSDecimalNumber decimalNumberWithString:remoteValue];
    } else if (transformableAttribute) {
        NSValueTransformer *transformer = [NSValueTransformer valueTransformerForName:[attributeDescription valueTransformerName]];
        if (transformer) {
            id newValue = [transformer transformedValue:remoteValue];
            if (newValue) {
                value = newValue;
            }
        }
    }

    return value;
}

- (NSString *)remotePrefix {
    return [NSString stringWithFormat:@"%@_", [self.entity.name hyp_remoteString]];
}

- (NSString *)prefixedAttribute:(NSString *)attribute {
    return [NSString stringWithFormat:@"%@%@", [self remotePrefix], attribute];
}

- (NSArray *)reservedKeys {
    NSMutableArray *keys = [NSMutableArray new];
    NSArray *reservedAttributes = [NSManagedObject reservedAttributes];

    for (NSString *attribute in reservedAttributes) {
        [keys addObject:[self prefixedAttribute:attribute]];
    }

    return keys;
}

+ (NSArray *)reservedAttributes {
    return @[@"type", @"description", @"signed"];
}

@end
