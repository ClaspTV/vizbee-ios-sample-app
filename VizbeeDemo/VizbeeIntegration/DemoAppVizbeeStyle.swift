import Foundation
import VizbeeKit

class DemoAppVizbeeStyle: NSObject {
    
    enum Style {
        case light
        case dark
    }
    
    static func getUIStyle(style: UIUserInterfaceStyle) -> [String: Any]{
        switch style {
        case .light:
            return DemoAppVizbeeStyle.lightTheme
        case .dark:
            return DemoAppVizbeeStyle.darkTheme
        default:
            return DemoAppVizbeeStyle.lightTheme
        }
    }
    
    //----------------------------
    // MARK : - Light Theme
    //---------------------------

    @objc
    static let lightTheme: [String: Any] =  [
        
        "base": "LightTheme",
        
        "references": [
            "@primaryFont"        : "Roboto-Regular",
            "@secondaryFont"      : "Roboto-Medium",
            
            "@primaryColor": "#FFFFFF",
            "@secondaryColor": "#000000",
            "@tertiaryColor": "#000000",
            "@lightTertiaryColor" : [
                "effect" : "transparency",
                "percent" : 0.5,
                "baseColor" : "@tertiaryColor"
            ],
            "@customColor" : "#E60000",
            "@highlightColor" : [
                "effect" : "transparency",
                "percent" : 0.1,
                "baseColor" : "@secondaryColor"
            ],
            
            "@lineWidth": 1,
            "@buttonLayoutEnabled": "@outlineLayoutEnabled",
            "@buttonLayoutDisabled": "@outlineLayoutDisabled",
            "@buttonLayoutSelected": "@outlineLayoutSelected",
            
            "@titleLabel": [
                "font": [
                    "name" : "@primaryFont",
                    "style" : "headline"
                ],
                "textColor": "@tertiaryColor",
            ],
            
            "@subtitleLabel": [
                "font": [
                    "name" : "@secondaryFont",
                    "style" : "subheadline"
                ],
                "textColor": "@lightTertiaryColor",
            ],
            
            "@overlaySubtitleLabel": [
                "font": [
                    "style" : "subheadline"
                ],
            ],
            
            "@actionBodyText" : [
                "font" : [
                    "name" : "@secondaryFont",
                    "style" : "subheadline",
                ],
            ],
        ],
        
        "ids" : [
            "PlayerCard.videoStatus.contentStatusView": [
                "backgroundColor": [
                    "effect": "transparency",
                    "percent": 0.4,
                    "baseColor": "@primaryColor"
                ]
            ],
            "PlayerCard.videoStatus.adStatusView": [
                "backgroundColor": [
                    "effect": "transparency",
                    "percent": 0.4,
                    "baseColor": "@primaryColor"
                ]
            ],
            "PlayerCard.playback.playbackControlsView.captionsButton" : [
                "enabledImageColor" :  "@tertiaryColor",
            ],
            "PlayerCard.playback.playbackControlsView.captionsButtonEnabled" : [
                "enabledImageColor" : "@primaryColor",
                "backgroundColor": "@tertiaryColor",
            ],
            "PlayerCard.playback.videoPositionSliderView.slider" : [
                "minTrackColor" : "@customColor",
                "thumbColor" : "@customColor",
            ],
            "unextendedPlayerCard.extendButton" : [
                "backgroundColor": "@secondaryColor",
                "enabledImageColor" : "@primaryColor",
            ],
            "AppInstallCard.selectLabel" : [
                "font" : [
                    "name" : "@primaryFont",
                    "style" : "subheadline",
                ],
            ],
            "AppInstallCard.notShownLabel" : [
                "font" : [
                    "name" : "@primaryFont",
                    "style" : "subheadline",
                ],
            ],
            "AppInstallCard.installButton": [
                "cornerRadius" : 32,
            ],
            "ManualAppInstallCard.installButton": [
                "cornerRadius" : 32,
            ]
        ],
        
        "classes": [
            
            //---
            // Loaders & Spinners
            //---
            
            "VZBCountdown" : [
                "trackColor" : [
                    "effect" : "transparency",
                    "percent" : 0.5,
                    "baseColor" : "@tertiaryColor"
                ],
                "strokeColor" : "@customColor",
                "text" : [
                    "textAlignment" : "center",
                    "textColor" : "@customColor",
                    "font": [
                            "style" : "body"
                            ]
                ],
            ],
            "VZBActivityIndicator" : [
                "strokeColor" : "@customColor",
                "text" : [
                    "textColor" : "@customColor",
                    "textAlignment" : "center",
                    "font": [
                            "style" : "body"
                            ]
                ]
            ],
            "DeviceStatusSpinner" : [
                "size":42,
                "style" : "arc",  // one of classic, vizbee, or arc
                "accentColor" : "@customColor",
                "lineWidth" : 3,
            ],
            
            //---
            // Mini Cast Playback View
            //---
            
            "MiniCastView.TitleLabel" : [
                "font" : [
                    "style" : "headline"
                ],
            ],
            "MiniCastView.SubtitleLabel" : [
                "font" : [
                    "style" : "caption1",
                ],
                "textColor": "@lightTertiaryColor"
            ],
            "MiniCastView.ControlButton" : [
                "borderWidth" : 0,
            ],
            "MiniCastView.ControlOnButton" : [
                "borderWidth" : 0,
            ],
            "MiniCastView.ControlDisabledButton" : [
                "borderWidth" : 0,
            ],
            
            //---
            // Cast Introduction Overlay Card
            //---
            
            "CastIntroductionOverlayCard.CastIntroductionView.DevicePicker": [
                "maxTableHeight": 2.3
            ],
            "CastIntroductionOverlayCard.CastIntroductionView.DevicePicker.DeviceCell-FirstInTable" : [
                "accessoryColor" : "@customColor",
                "accessoryType" : "checkmark",
            ],
            "CastIntroductionOverlayCard.CastIntroductionView.OverlayHeaderStackView.OverlaySubtitleLabel" : [
                "font" : [
                    "name" : "@secondaryFont",
                    "style" : "caption1",
                ],
            ],
            
            //-----
            // VZBDeviceInfoView
            //-----
            
            "DeviceInfoView.DeviceNameLabel" : [
                "textTransform" : nil,
                "font" : [
                    "style": "subheadline"
                ],
            ],
            "DeviceCell.DeviceInfoView.DeviceNameLabel" : [
                "textTransform" : nil,
                "font" : [
                    "style": "subheadline"
                ],
            ],
            "DeviceCell.DeviceInfoView.DeviceTypeLabel" : [
                "textTransform" : nil,
                "font" : [
                    "style": "subheadline"
                ],
            ],
            
            //-----
            // CastButtonOverlayCard
            //-----
            
            "CastButtonOverlayCard.TitledDevicePicker.PickerHelpButton" : [
                "textColor" :"@customColor",
            ],
            
            //-----
            // Others
            //-----
            
            "ActionBodyText"   : "@actionBodyText",
            
            "CallToActionButton" : [
                "borderWidth" : 2,
                "borderColor" : "@lightTertiaryColor",
                "cornerRadius" : 31,
                "font" : [
                    "name" : "@primaryFont",
                    "style": "body"
                ],
                "textTransform": "capitalize",
                "backgroundColor" : [
                    "effect" : "transparency",
                    "percent" : 0,
                    "baseColor" : "@primaryColor"
                ],
                "margin" : [20.0, 72.0, 20.0, 72.0],
                "showsTouchWhenHighlighted" : true
            ],
            
            "OverlayCallToActionButton" : [
                "borderWidth" : 2,
                "borderColor" : "@lightTertiaryColor",
                "cornerRadius" : 31,
                "font" : [
                    "name" : "@primaryFont",
                    "style": "body"
                ],
                "textTransform": "capitalize",
                "backgroundColor" : [
                    "effect" : "transparency",
                    "percent" : 0,
                    "baseColor" : "@primaryColor"
                ],
                "margin" : [20.0, 72.0, 20.0, 72.0],
                "showsTouchWhenHighlighted" : true
            ],
            
            "FloatingCastIcon": [
                "unavailableColor" : "@primaryColor",
                "disconnectedColor" : "@primaryColor",
                "connectedColor"  : "@primaryColor",
                
                "backgroundColor" : "@customColor",
            ],
            
            "PositionLabel" : [
                "textColor" : "@customColor",
            ],
            
            "DurationLabel" : [
                "textColor" : "@customColor",
            ],
            
            "UISlider" : [
                "maxTrackColor" : [
                    "effect" : "transparency",
                    "percent" : 0.5,
                    "baseColor" : "@tertiaryColor"
                ],
                "useCircleThumbControl" : true,
                "circleThumbDiameter" : 9,
            ],
            
            "RefreshButton" : [
                "textColor" : "@customColor",
                "textTransform": "capitalize"
            ],
            
            "PlaybackControls" : [
                "disablePlayPauseButtonForLive" : true,
            ],
            
            "VZBProgressView" : [
                "backgroundColor" : [
                    "effect" : "transparency",
                    "percent" : 0.1,
                    "baseColor" : "@secondaryColor",
                ],
                "progressColor" : [
                    "effect" : "transparency",
                    "percent" : 1,
                    "baseColor" : "@customColor",
                ],
            ],
        ]
    ]
    
    //---------------------------
    // MARK : - Dark Theme
    //---------------------------
    
    @objc
    static let darkTheme: [String: Any] =  [
        "base": "DarkTheme",
        
        "references": [
            "@primaryFont"        : "vzb_primaryFont",
            "@secondaryFont"      : "vzb_secondaryFont",
            
            "@primaryColor": "#1C1C1C",
            "@secondaryColor": "#FFFFFF",
            "@tertiaryColor": "#FFFFFF",
            "@lightTertiaryColor" : [
                "effect" : "transparency",
                "percent" : 0.8,
                "baseColor" : "@tertiaryColor"
            ],
            "@lighterTertiaryColor" : [
                "effect" : "transparency",
                "percent" : 0.4,
                "baseColor" : "@tertiaryColor"
            ],
            
            "@customColor" : "#E60000",
            "@navBarBGColor": "#000000",
            
            "@lineWidth": 1,
            "@buttonLayoutEnabled": "@outlineLayoutEnabled",
            "@buttonLayoutDisabled": "@outlineLayoutDisabled",
            "@buttonLayoutSelected": "@outlineLayoutSelected",
            
            "@titleLabel": [
                "font": [
                    "name" : "@primaryFont",
                    "style" : "headline"
                ],
                "textColor": "@tertiaryColor",
            ],
            
            "@subtitleLabel": [
                "font": [
                    "name" : "@secondaryFont",
                    "style" : "subheadline"
                ],
                "textColor": "@lightTertiaryColor",
            ],
            
            "@overlaySubtitleLabel": [
                "font": [
                    "style" : "subheadline"
                ],
            ],
            
            "@actionBodyText" : [
                "font" : [
                    "name" : "@secondaryFont",
                    "style" : "subheadline",
                ],
            ],
        ],
        
        "ids" : [
            "PlayerCard.videoStatus.contentStatusView": [
                "backgroundColor": [
                    "effect": "transparency",
                    "percent": 0.4,
                    "baseColor": "@primaryColor"
                ]
            ],
            "PlayerCard.videoStatus.adStatusView": [
                "backgroundColor": [
                    "effect": "transparency",
                    "percent": 0.4,
                    "baseColor": "@primaryColor"
                ]
            ],
            "PlayerCard.playback.playbackControlsView.captionsButton" : [
                "enabledImageColor" : "@tertiaryColor",
            ],
            "PlayerCard.playback.playbackControlsView.captionsButtonEnabled" : [
                "enabledImageColor" : "@primaryColor",
                "backgroundColor" : "@secondaryColor"
            ],
            "PlayerCard.playback.videoPositionSliderView.slider" : [
                "minTrackColor" : "@customColor",
                "thumbColor" : "@customColor",
            ],
            "unextendedPlayerCard.extendButton" : [
                "backgroundColor": "@secondaryColor",
                "enabledImageColor" : "@primaryColor",
            ],
            "AppInstallCard.selectLabel" : [
                "font" : [
                    "name" : "@primaryFont",
                    "style" : "subheadline",
                ],
            ],
            "AppInstallCard.notShownLabel" : [
                "font" : [
                    "name" : "@primaryFont",
                    "style" : "subheadline",
                ],
            ],
            "AppInstallCard.installButton":[
                "cornerRadius" : 32,
            ],
            "ManualAppInstallCard.installButton":[
                "cornerRadius" : 32,
            ],
        ],
        
        "classes": [
            //---
            // Loaders & Spinners
            //---
            
            "VZBCountdown" : [
                "trackColor" : [
                    "effect" : "transparency",
                    "percent" : 0.4,
                    "baseColor" : "@tertiaryColor"
                ],
                "strokeColor" : "@customColor",
                "text" : [
                    "textAlignment" : "center",
                    "textColor" : "@customColor",
                    "font": [
                            "style" : "body"
                            ]
                ],
            ],
            "VZBActivityIndicator" : [
                "strokeColor" : "@customColor",
                "text" : [
                    "textColor" : "@customColor",
                    "textAlignment" : "center",
                    "font": [
                            "style" : "body"
                            ]
                ]
            ],
            "DeviceStatusSpinner" : [
                "size":42,
                "style" : "arc",  // one of classic, vizbee, or arc
                "accentColor" : "@customColor",
                "lineWidth" : 3,
            ],
            
            //---
            // Mini Cast Playback View
            //---
            
            "MiniCastView.TitleLabel" : [
                "font" : [
                    "style" : "headline"
                ],
            ],
            "MiniCastView.SubtitleLabel" : [
                "font" : [
                    "style" : "caption1",
                ],
                "textColor": "@lightTertiaryColor"
            ],
            "MiniCastView.ControlButton" : [
                "borderWidth" : 0,
            ],
            "MiniCastView.ControlOnButton" : [
                "borderWidth" : 0,
            ],
            "MiniCastView.ControlDisabledButton" : [
                "borderWidth" : 0,
            ],
            "MiniCastView.BackgroundLayer" : [
               "backgroundColor" : "@navBarBGColor",
            ],
         
            //---
            // Cast Introduction Overlay Card
            //---
            
            "CastIntroductionOverlayCard.CastIntroductionView":[
                "backgroundColor" : "@primaryColor",
            ],
            "CastIntroductionOverlayCard.CastIntroductionView.DevicePicker": [
                "maxTableHeight": 2.3
            ],
            "CastIntroductionOverlayCard.CastIntroductionView.DevicePicker.DeviceCell-FirstInTable" : [
                "accessoryColor" : "@customColor",
                "accessoryType" : "checkmark"
            ],
            "CastIntroductionOverlayCard.CastIntroductionView.OverlayHeaderStackView.OverlaySubtitleLabel" : [
                "font" : [
                    "name" : "@secondaryFont",
                    "style" : "caption1",
                ],
            ],
            
            //-----
            // Overlay Views
            //-----
            
            "VZBOverlayBlurLayer" : [
                "addBlur" : false,
            ],
            "OverlayCard.BackgroundLayer" : [
                "alpha" : 1.0,
                "backgroundColor" : "@primaryColor",
            ],
            
            //-----
            // VZBDeviceInfoView
            //-----
            
            "DeviceInfoView.DeviceNameLabel" : [
                "textTransform" : nil,
                "font" : [
                    "style": "subheadline"
                ],
            ],
            "DeviceCell.DeviceInfoView.DeviceNameLabel" : [
                "textTransform" : nil,
                "font" : [
                    "style": "subheadline"
                ],
            ],
            "DeviceCell.DeviceInfoView.DeviceTypeLabel" : [
                "textTransform" : nil,
                "font" : [
                    "style": "subheadline"
                ],
            ],
            
            //-----
            // CastButtonOverlayCard
            //-----
            
            "CastButtonOverlayCard.TitledDevicePicker.PickerHelpButton" : [
                "textColor" :"@customColor",
            ],
            
            //-----
            // Others
            //-----
            
            "ActionBodyText"   : "@actionBodyText",
            
            "CallToActionButton" : [
                "borderWidth" : 2,
                "borderColor" : "@lighterTertiaryColor",
                "cornerRadius" : 31,
                "font" : [
                    "name" : "@primaryFont",
                    "style": "body"
                ],
                "textTransform": "capitalize",
                "backgroundColor" : [
                    "effect" : "transparency",
                    "percent" : 0,
                    "baseColor" : "@primaryColor"
                ],
                "margin" : [20.0, 72.0, 20.0, 72.0],
                "showsTouchWhenHighlighted" : true
            ],
            
            "OverlayCallToActionButton" : [
                "borderWidth" : 2,
                "borderColor" : "@lighterTertiaryColor",
                "cornerRadius" : 31,
                "font" : [
                    "name" : "@primaryFont",
                    "style": "body"
                ],
                "textTransform": "capitalize",
                "backgroundColor" : [
                    "effect" : "transparency",
                    "percent" : 0,
                    "baseColor" : "@primaryColor"
                ],
                "margin" : [20.0, 72.0, 20.0, 72.0],
                "showsTouchWhenHighlighted" : true
            ],
            
            "CastIcon" : [
                "unavailableColor" : "@tertiaryColor",
                "disconnectedColor" : "@tertiaryColor",
                "connectedColor"  : "@tertiaryColor",
            ],
            
            "FloatingCastIcon": [
                "unavailableColor" : "@tertiaryColor",
                "disconnectedColor" : "@tertiaryColor",
                "connectedColor"  : "@tertiaryColor",
                
                "backgroundColor" : "@customColor",
            ],
            
            "PositionLabel" : [
                "textColor" : "@customColor",
            ],
            
            "DurationLabel" : [
                "textColor" : "@customColor",
            ],
            
            "UISlider" : [
                "maxTrackColor" : [
                    "effect" : "transparency",
                    "percent" : 0.6,
                    "baseColor" : "@tertiaryColor"
                ],
                "useCircleThumbControl" : true,
                "circleThumbDiameter" : 9,
            ],
            
            "RefreshButton" : [
                "textColor" : "@customColor",
                "textTransform": "capitalize"
            ],
            
            "ControlButton" : [
                "backgroundColor" : "@primaryColor",
                "borderColor": "@secondaryColor",
                "borderWidth" : 1,
            ],
            
            "ControlOnButton" : [
                "backgroundColor" : "@primaryColor",
                "borderColor": "@secondaryColor",
                "borderWidth" : 1,
            ],
            
            "PlaybackControls" : [
                "disablePlayPauseButtonForLive" : true,
            ],
            
            "VZBProgressView" : [
                "backgroundColor" : "@primaryColor",
                "progressColor" : [
                    "effect" : "transparency",
                    "percent" : 1,
                    "baseColor" : "@customColor",
                ],
            ],
        ]
    ]
}

