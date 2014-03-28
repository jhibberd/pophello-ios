
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, PHZoneServiceRequirement) {
    kPHZoneServiceRequirementHardwareSupport,
    kPHZoneServiceRequirementLocationServicesEnabled,
    kPHZoneServiceRequirementLocationServicesAuthorized,
    kPHZoneServiceRequirementBackgroundRefreshAvailable,
    kPHZoneServiceRequirementRegionMonitoringAvailable,
    kPHZoneServiceRequirementMultitaskingSupported
};
