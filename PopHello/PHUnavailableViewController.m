
#import "PHUnavailableViewController.h"
#import "UIColor+PHColor.h"

@interface PHUnavailableViewController ()
@end

@implementation PHUnavailableViewController {
    PHZoneServiceRequirement _missing;
}

- (id)initWithMissingZoneServiceRequirement:(PHZoneServiceRequirement)missing
{
    self = [super init];
    if (self) {
        _missing = missing;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor ph_unavailableColor];
    
    NSString *textReason;
    switch (_missing) {
        case kPHZoneServiceRequirementHardwareSupport:
            textReason = NSLocalizedString(@"SERVICE_UNAVAILABLE_HARDWARE_SUPPORT", nil);
            break;
        case kPHZoneServiceRequirementLocationServicesEnabled:
            textReason = NSLocalizedString(@"SERVICE_UNAVAILABLE_LOCATION_SERVICES_ENABLED", nil);
            break;
        case kPHZoneServiceRequirementLocationServicesAuthorized:
            textReason = NSLocalizedString(@"SERVICE_UNAVAILABLE_LOCATION_SERVICES_AUTHORIZED", nil);
            break;
        case kPHZoneServiceRequirementBackgroundRefreshAvailable:
            textReason = NSLocalizedString(@"SERVICE_UNAVAILABLE_BACKGROUND_REFRESH_AVAILABLE", nil);
            break;
        case kPHZoneServiceRequirementRegionMonitoringAvailable:
            textReason = NSLocalizedString(@"SERVICE_UNAVAILABLE_REGION_MONITORING_AVAILABLE", nil);
            break;
        case kPHZoneServiceRequirementMultitaskingSupported:
            textReason = NSLocalizedString(@"SERVICE_UNAVAILABLE_MULTITASKING_SUPPORTED", nil);
            break;
    }
    
    UILabel *labelReason = [[UILabel alloc] init];
    labelReason.textColor = [UIColor whiteColor];
    labelReason.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    labelReason.numberOfLines = 0;
    labelReason.text = textReason;
    [labelReason sizeToFit];
    [self.view addSubview:labelReason];
    
    labelReason.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *variableBindings = NSDictionaryOfVariableBindings(labelReason);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-30-[labelReason]"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:variableBindings]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-10-[labelReason]-10-|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:variableBindings]];
}

@end
