//
// VizbeeStyles.swift
// This is the template file for customizing Vizbee UI styles to your app's brand requirements.

import Foundation
import VizbeeKit

class VizbeeStyles : NSObject {
    
    static func uiStyle() -> [String : Any] {
        return darkTheme
    }
    
    //----------------------------
    // MARK : - Light Theme
    //---------------------------
    
    static let lightTheme: [String: Any] =  [
        
        // ===============================================================
        // Basic Style Customization (Required)                            
        // ===============================================================
        
        "base" : "LightTheme",
        
        "references" : [
            
            /* Your app's theme colors -->
        
            1. Primary Color - this is typically the background color used on most of your app screens
            2. Secondary Color - this is the highlight or accent color used on buttons etc. in your app screens
            3. Tertiary Color - this is the text color used in most of your app screens
            
            Update the colors below to suit your app.  
            */
            "@primaryColor"       : "#FFFFFF",
            "@secondaryColor"     : "#FF140F",
            "@tertiaryColor"      : "#0C0C0C",
            "@lighterTertiaryColor" : "#323236",
                
            /* Your app's theme fonts
        
            Provide fonts located in your supporting files folder including any nested directories.
            i.e 'yourFont.<extension>' or 'fonts/yourFont.<extension>.
            
            Update the fonts below to suit your app.
            */
            "@primaryFont"        : "<apps_primary_font_name>",
            "@secondaryFont"      : "<apps_secondary_font_name>",
        ],
        
        // ===============================================================
        // Advanced Style Customization (Optional)                         
        // ===============================================================
        
        "classes" : [
            
            /* Card background
        
            set this attribute if you prefer an image background for Vizbee screens
            "BackgroundLayer": [
                                "backgroundType"  : "image",
                                "backgroundImageName" : "<image_name.png>"
                                ],
            */
            
        ]
        
        /*
         OVERLAY CARD

         Customize the Overlay cards as shown here
         https://gist.github.com/vizbee/7e9613f76a546c8f9ed9087e91bdc7b1#customize-overlay-cards
        */
        
        /*
        INTERSTITIAL CARD
       
        Customize the Interstitial cards as shown here
        https://gist.github.com/vizbee/7e9613f76a546c8f9ed9087e91bdc7b1#customize-interstitial-cards
        */
        
         /*
         SPECIFIC CARD ATTRIBUTES
        
         Player Card
            Customize the Player card as shown here
            https://gist.github.com/vizbee/7e9613f76a546c8f9ed9087e91bdc7b1#customize-player-card
         */

    ]
    
    //---------------------------
    // MARK : - Dark Theme
    //---------------------------
    
    static let darkTheme: [String: Any] =  [
        
        // ===============================================================
        // Basic Style Customization (Required)                            
        // ===============================================================
        
        "base" : "DarkTheme",
      
        "references" : [
            
            /* Your app's theme colors -->
        
            1. Primary Color - this is typically the background color used on most of your app screens
            2. Secondary Color - this is the highlight or accent color used on buttons etc. in your app screens
            3. Tertiary Color - this is the text color used in most of your app screens
            
            Update the colors below to suit your app.  
            */
            "@primaryColor"       : "#0C0C0C",
            "@secondaryColor"     : "#FF140F",
            "@tertiaryColor"      : "#FFFFFF",
            
            /* Your app's theme fonts
        
            Provide fonts located in your supporting files folder including any nested directories.
            i.e 'yourFont.<extension>' or 'fonts/yourFont.<extension>.
            
            Update the fonts below to suit your app.
            */
            "@primaryFont"        : "<apps_primary_font_name>",
            "@secondaryFont"      : "<apps_secondary_font_name>",
        ]
    ]
}
