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
    // MARK: - Light Theme
    //---------------------------
    
    static let lightTheme: [String: Any] =
    [// ===============================================================
        // Basic Style Customization (Required)
        // ===============================================================
        
        "base": "LightTheme",
        
        "references": [
            
            /* Your app's theme colors -->
             
             1. Primary Color - this is typically the background color used on most of your app screens
             2. Secondary Color - this is the highlight or accent color used on buttons etc. in your app screens
             3. Tertiary Color - this is the text color used in most of your app screens
             
             Update the colors below to suit your app.
             */
            
            "@primaryColor": "#FFFFFF",
            "@secondaryColor": "#C20017",
            "@tertiaryColor": "#000000",
            
            /* Your app's theme fonts
             
             Provide fonts located in your supporting files folder including any nested directories.
             i.e 'yourFont.<extension>' or 'fonts/yourFont.<extension>.
             
             Update the fonts below to suit your app.
             */
            "@primaryFont": "Roboto-Bold",
            "@secondaryFont": "Roboto-Regular",
            
            /*
             Derived colors
             */
            "@lightPrimaryColor": [
                "effect": "transparency",
                "percent": 0.3,
                "baseColor": "@primaryColor"
            ],
            "@lightSecondaryColor": [
                "effect": "transparency",
                "percent": 0.3,
                "baseColor": "@secondaryColor"
            ],
            "@widgetEnabledBrightBackgroundColor": [
                "effect": "transparency",
                "percent": 0.08,
                "baseColor": "@secondaryColor"
            ],
            
            // update fonts to match with the app style
            "@titleLabel": [
                "font": [
                    "style": "title3"
                ],
                "textTransform": nil
            ],
            "@subtitleLabel": [
                "font": [
                    "style": "subheadline"
                ]
            ],
            "@overlaySubtitleLabel": [
                "font": [
                    "style": "subheadline"
                ]
            ],
            "@actionBodyText": [
                "font": [
                    "name": "@secondaryFont",
                    "style": "subheadline"
                ]
            ]
        ],
        
        // ===============================================================
        // Advanced Style Customization (Optional)
        // ===============================================================
        
        "classes": [
            
            //---
            // Buttons
            //---
            
            "CallToActionButton": [
                "backgroundColor": "@secondaryColor",
                "cornerRadius": 8,
                "textTransform": nil,
                "font": [
                    "name": "@secondaryFont",
                    "style": "subheadline"
                ]
            ],
            "OverlayCallToActionButton": [
                "backgroundColor": "@secondaryColor",
                "cornerRadius": 8,
                "textTransform": nil,
                "font": [
                    "name": "@secondaryFont",
                    "style": "subheadline"
                ]
            ],
            
            //---
            // Progress/Status
            //---
            
            "DeviceStatusSpinner": [
                "size": 48,
                "backgroundColor": "@widgetEnabledBrightBackgroundColor",
                "style": "arc" // one of classic, vizbee, or arc
            ],
            "VZBCountdown": [
                "trackColor": "@lightSecondaryColor"
            ],
            
            //---
            // ImageView Dim Color
            //---
            
            "VZBIllustrationView": [
                "dimColor": "@secondaryColor",
                "brightColor": "@tertiaryColor"
            ],
            
            //---
            // Device Selection & Device Status Views Title Styling
            //---
            
            "CastIconCard.TitledDevicePicker.PickerTitleLabel": [
                "textTransform": nil,
                "font": [
                    "style": "title3"
                ]
            ],
            "DeviceStatusView.DeviceStatusLabel": [
                "textTransform": nil,
                "font": [
                    "style": "title3"
                ]
            ],
            
            //---
            // Device Cell
            //---
            
            "DeviceCell": [
                "contentView": [
                    "cornerRadius": 8
                ]
            ],
            "DeviceCell.DeviceInfoView.DeviceNameLabel": [
                "textTransform": nil,
                "font": [
                    "style": "subheadline"
                ],
                "margin": [0, 8, 3, 0]
            ],
            "DeviceInfoView.DeviceNameLabel": [
                "textTransform": nil,
                "font": [
                    "style": "subheadline"
                ],
                "textColor": [
                    "effect": "transparency",
                    "percent": 1,
                    "baseColor": "@tertiaryColor"
                ],
                "margin": [0, 8, 3, 8]
            ],
            
            //---
            // TitledImageView
            //---
            
            "TitledImageView": [
                "backupImage": "placeholder_hero",
                "backupImageFilter": [
                    "filterEffect": "none"
                ]
            ],
            
            //---
            // PlayerCard Title/Subtitle/Image
            //---
            
            "PlayerCard.TitledImageView.TitleLabel": [
                "font": [
                    "style": "subheadline"
                ]
            ],
            "UnextendedPlayerCard.TitledImageView.TitleLabel": [
                "font": [
                    "style": "subheadline"
                ]
            ],
            
            //---
            // PlayerCard DeviceInfo
            //---
            
            "PlayerCard.PlaybackControls.DeviceInfoView": [
                "style": "deviceNameAndIcon",
                "margin": [0, 8, 0, 8]
            ],
            "PlayerCard.PlaybackControls.DeviceInfoView.DeviceNameLabel": [
                "margin": [0, 8, 0, 8]
            ],
            
            //---
            // Player Controls Buttons
            // Snippet: Outline style with secondary color for player controls + filled style with secondary color for play/pause button
            //---
            
            // enabled and OFF
            "ControlButton": [
                "enabledImageColor": "@primaryColor",
                "backgroundColor": "@secondaryColor"
            ],
            
            // enabled and ON
            "ControlOnButton": [
                "enabledImageColor": "@tertiaryColor"
            ],
            
            "PlaybackControls": [
                "disablePlayPauseButtonForLive": false,
                "playActionButtonTypeForLiveContent": "playpause",
                "controls": [
                    ["filter": [
                        ["property": "isCCSupported",
                         "matcher": true]
                    ],
                     "buttons": [
                        "captions",
                        "forward"
                     ]],
                    ["filter": [
                    ],
                     "buttons": [
                        "rewind",
                        "forward"
                     ]]
                ]
            ],
            
            //---
            // PlayerCard UISlider
            //---
            
            "UISlider": [
                "minTrackColor": "@secondaryColor",
                "maxTrackColor": "@lighterSecondaryColor"
            ],
            
            //---
            // MiniCastView Control Button
            //---
            
            // enabled
            "MiniCastView.ControlButton": [
                "enabledImageColor": "@secondaryColor",
                "backgroundColor": "@primaryColor"
            ],
            
            //---
            // Cast Introduction Overlay Card
            //---
            
            "CastIntroductionOverlayCard.CastIntroductionView.DevicePicker": [
                "maxTableHeight": 2.3
            ],
        ],
        
        "ids": [
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
            ]
        ]]
    
    //---------------------------
    // MARK: - Dark Theme
    //---------------------------
    
    static let darkTheme: [String: Any] =
    [// ===============================================================
        // Basic Style Customization (Required)
        // ===============================================================
        
        "base": "DarkTheme",
        
        "references": [
            
            /* Your app's theme colors -->
             
             1. Primary Color - this is typically the background color used on most of your app screens
             2. Secondary Color - this is the highlight or accent color used on buttons etc. in your app screens
             3. Tertiary Color - this is the text color used in most of your app screens
             
             Update the colors below to suit your app.
             */
            
            "@primaryColor": "#00172E",
            "@secondaryColor": "#D10F26",
            "@tertiaryColor": "#FFFFFF",
            
            /* Your app's theme fonts
             
             Provide fonts located in your supporting files folder including any nested directories.
             i.e 'yourFont.<extension>' or 'fonts/yourFont.<extension>.
             
             Update the fonts below to suit your app.
             */
            
            "@primaryFont": "Roboto-Bold",
            "@secondaryFont": "Roboto-Regular",
            
            /*
             Derived colors
             */
            "@lightPrimaryColor": [
                "effect": "transparency",
                "percent": 0.3,
                "baseColor": "@primaryColor"
            ],
            "@lightSecondaryColor": [
                "effect": "transparency",
                "percent": 0.3,
                "baseColor": "@secondaryColor"
            ],
            "@widgetEnabledBrightBackgroundColor": [
                "effect": "transparency",
                "percent": 0.08,
                "baseColor": "@tertiaryColor"
            ],
            
            // update fonts to match with the app style
            "@titleLabel": [
                "font": [
                    "style": "title3"
                ],
                "textTransform": nil
            ],
            "@subtitleLabel": [
                "font": [
                    "style": "subheadline"
                ]
            ],
            "@overlaySubtitleLabel": [
                "font": [
                    "style": "subheadline"
                ]
            ],
            "@actionBodyText": [
                "font": [
                    "name": "@secondaryFont",
                    "style": "subheadline"
                ]
            ],
            
            "@overlayLuminosityLayerColor" : [
                "effect" : "transparency",
                "percent" : 0, // 1.0 is opaque
                "baseColor" : "#FFFFFF"
            ]
        ],
        
        // ===============================================================
        // Advanced Style Customization (Optional)
        // ===============================================================
        
        "classes": [
            
            //---
            // CastIcon Buttons
            //---
            
            "CastIcon": [
                "unavailableColor": "@tertiaryColor",
                "disconnectedColor": "@tertiaryColor",
                "connectedColor": "@tertiaryColor"
            ],
            
            //---
            // Buttons
            //---
            
            "CallToActionButton": [
                "backgroundColor": "@secondaryColor",
                "cornerRadius": 8,
                "textTransform": nil,
                "font": [
                    "name": "@secondaryFont",
                    "style": "subheadline"
                ]
            ],
            "OverlayCallToActionButton": [
                "backgroundColor": "@secondaryColor",
                "cornerRadius": 8,
                "textTransform": nil,
                "font": [
                    "name": "@secondaryFont",
                    "style": "subheadline"
                ]
            ],
            
            //---
            // Progress/Status
            //---
            
            "VZBProgressView": [
                "backgroundColor": "@lightSecondaryColor"
            ],
            "DeviceStatusSpinner": [
                "size": 48,
                "backgroundColor": "@widgetEnabledBrightBackgroundColor",
                "style": "arc" // one of classic, vizbee, or arc
            ],
            "VZBCountdown": [
                "trackColor": "@lightSecondaryColor"
            ],
            
            //---
            // ImageView Dim Color
            //---
            
            "VZBIllustrationView": [
                "dimColor": "@widgetEnabledBrightBackgroundColor"
            ],
            
            //---
            // Device Selection & Device Status Views Title Styling
            //---
            
            "CastIconCard.TitledDevicePicker.PickerTitleLabel": [
                "textTransform": nil,
                "font": [
                    "style": "title3"
                ]
            ],
            "DeviceStatusView.DeviceStatusLabel": [
                "textTransform": nil,
                "font": [
                    "style": "title3"
                ]
            ],
            
            //---
            // Device Cell
            //---
            
            "DeviceCell": [
                "contentView": [
                    "cornerRadius": 8
                ]
            ],
            "DeviceCell.DeviceInfoView.DeviceNameLabel": [
                "textTransform": nil,
                "font": [
                    "style": "subheadline"
                ],
                "margin": [0, 8, 3, 0]
            ],
            "DeviceInfoView.DeviceNameLabel": [
                "textTransform": nil,
                "font": [
                    "style": "subheadline"
                ],
                "margin": [0, 8, 3, 8]
            ],
            
            //---
            // TitledImageView
            //---
            
            "TitledImageView": [
                "backupImage": "placeholder_hero_dark",
                "backupImageFilter": [
                    "filterEffect": "none"
                ]
            ],
            
            //---
            // PlayerCard Title/Subtitle/Image
            //---
            
            "PlayerCard.TitledImageView.TitleLabel": [
                "font": [
                    "style": "subheadline"
                ]
            ],
            "UnextendedPlayerCard.TitledImageView.TitleLabel": [
                "font": [
                    "style": "subheadline"
                ]
            ],
            
            //---
            // PlayerCard DeviceInfo
            //---
            
            "PlayerCard.PlaybackControls.DeviceInfoView": [
                "style": "deviceNameAndIcon",
                "margin": [0, 8, 0, 8]
            ],
            "PlayerCard.PlaybackControls.DeviceInfoView.DeviceNameLabel": [
                "margin": [0, 8, 0, 8]
            ],
            
            //---
            // Player Controls Buttons
            // Snippet: Outline style with secondary color for player controls + filled style with secondary color for play/pause button
            //---
            
            // enabled and OFF
            "ControlButton": [
                "enabledImageColor": "@secondaryColor",
                "backgroundColor": "@widgetEnabledBrightBackgroundColor"
            ],
            
            // enabled and ON
            "ControlOnButton": [
                "backgroundColor": "@secondaryColor",
                "enabledImageColor": "@primaryColor"
            ],
            
            "PlaybackControls": [
                "disablePlayPauseButtonForLive": false,
                "playActionButtonTypeForLiveContent": "playpause",
                "controls": [
                    ["filter": [
                        ["property": "isCCSupported",
                         "matcher": true]
                    ],
                     "buttons": [
                        "captions",
                        "forward"
                     ]],
                    ["filter": [
                    ],
                     "buttons": [
                        "rewind",
                        "forward"
                     ]]
                ]
            ],
            
            //---
            // PlayerCard UISlider
            //---
            
            "UISlider": [
                "maxTrackColor": "@widgetEnabledBrightBackgroundColor"
            ],
            
            //---
            // MiniCastView Control Button
            //---
            
            // enabled
            "MiniCastView.ControlButton": [
                "enabledImageColor": "@secondaryColor",
                "backgroundColor": "@primaryColor"
            ],
            
            //---
            // Cast Introduction Overlay Card
            //---
            
            "CastIntroductionOverlayCard.CastIntroductionView.DevicePicker": [
                "maxTableHeight": 2.3
            ],
            
            "OverlayCard.BackgroundLayer" : [
                "alpha" : 1.0,
                "backgroundColor" : "@primaryColor",
            ],
            
            // Blur & Luminosity on overlay cards
            "VZBOverlayBlurLayer" : [
                "addBlur" : false,
            ],
        ],
        
        "ids": [
            "PlayerCard.videoStatus.contentStatusView": [
                "backgroundColor": [
                    "effect": "transparency",
                    "percent": 0.2,
                    "baseColor": "@tertiaryColor"
                ]
            ],
            "PlayerCard.videoStatus.adStatusView": [
                "backgroundColor": [
                    "effect": "transparency",
                    "percent": 0.2,
                    "baseColor": "@tertiaryColor"
                ]
            ]
        ]]
}
