//
//  VizbeeAdapter.swift
//  VizbeeDemo
//
//  Copyright © Vizbee Inc. All rights reserved.
//

import VizbeeKit

class VizbeeAdapter: NSObject, VZBAppAdapterDelegate {
    
    /**
      This adapter method is invoked by the Vizbee SDK to get
      metadata in the Vizbee format for a given video.
      - Parameter appVideoObject: The videoObject used in the app
      - Parameter successCallback: callback on successful creation of VZBVideoMetadata
      - Parameter failureCallback: callback on failure
    */
    func getVZBMetadata(fromVideo appVideoObject: Any,
                        onSuccess successCallback: @escaping (VZBVideoMetadata) -> Void,
                        onFailure failureCallback: @escaping (Error) -> Void) {
        
        if let video = appVideoObject as? Video {
            
            let metadata = VZBVideoMetadata()
            metadata.guid = video.id;
            metadata.title = video.title;
            metadata.subTitle = video.subtitle;
            if let urlStr = video.imageURL, let imageURL = URL(string:urlStr) {
                metadata.imageURL = imageURL
            }
            metadata.isLive = video.isLive;
            
            // cuepoints
            metadata.setCuePointsInSeconds(video.adBreaks)
            
            successCallback(metadata);
            
        } else {
            failureCallback(NSError(domain: "Error", code: 2, userInfo: [NSLocalizedDescriptionKey: "'appVideoObject' is not of expected type `VideoObject'"]))
        }
    }

    /**
      This adapter method is invoked by the Vizbee SDK to get
      streaming info in the Vizbee format for a given video.
      - Parameter appVideoObject: The videoObject used in the app
      - Parameter screenType: The target screen to which the video is being cast
      - Parameter successCallback: callback on successful creation of VZBStreamInfo
      - Parameter failureCallback: callback on failure
    */
    func getVZBStreamInfo(fromVideo appVideoObject: Any,
                          for screenType: VZBScreenType,
                          onSuccess successCallback: @escaping (VZBVideoStreamInfo) -> Void,
                          onFailure failureCallback: @escaping (Error) -> Void) {
        
        if let video = appVideoObject as? Video {
            
            if let contentURL = URL(string:video.streamURL) {
                
                let streamInfo = VZBVideoStreamInfo()
                streamInfo.guid = video.id;
                streamInfo.videoURL = contentURL;
                
                // set protocol type
                if screenType.suggestedProtocolType == .any {
                    streamInfo.protocolType = .HLS;
                } else {
                    streamInfo.protocolType = screenType.suggestedProtocolType;
                }
                
                print("Success - \(streamInfo)");
                successCallback(streamInfo);
            } else {
                failureCallback(NSError(domain: "Error", code: 2, userInfo: [NSLocalizedDescriptionKey: "ContentURL is empty"]))
            }
        } else {
            failureCallback(NSError(domain: "Error", code: 2, userInfo: [NSLocalizedDescriptionKey: "'appVideoObject' is not of expected type `VideoMetadata'"]))
        }
    }

    /**
      This adapter method is invoked by the Vizbee SDK when
      the mobile app 'joins' a receiver that is already playing a video.
      The method is used by the Vizbee SDK to get metadata about the
      video playing on the receiver by using the GUID of the video.
      - Parameter guid: GUID of the video
      - Parameter successCallback: callback on successful creation of VZBVideoInfo
      - Parameter failureCallback: callback on failure
    */
    func getVideoInfo(byGUID guid: String,
                      onSuccess successCallback: @escaping (Any) -> Void,
                      onFailure failureCallback: @escaping (Error) -> Void) {
      
        // EXAMPLE:
        /*
        AppNetworking.shared.fetchVideo(id: guid) { video, error in
            if let video = video {
                successCallback(video)
            } else if let error = error {
                failureCallback(error)
            }
        }
        */
      
        // default response
        failureCallback(NSError(domain: "Not implemented", code: 2, userInfo: nil))
    }

    /**
      This adapter method is invoked by the Vizbee SDK in SmartPlay flow
      or the Disconnect flow to start playback of a video on the phone.
      - Parameter appVideoObject: app's video object
      - Parameter playHeadTime: resume position of video
      - Parameter shouldAutoPlay: indicates if the video should start auto playing
      - Parameter viewController: the presenting view controller
    */
    func playVideo(onPhone appVideoObject: Any,
                   atPosition playHeadTime: TimeInterval,
                   shouldAutoPlay: Bool,
                   presenting viewController: UIViewController) {
        if let video = appVideoObject as? Video, let vc = UIApplication.shared.windows.first?.rootViewController!{
            PlayerPresenter.shared.presentPlayer(video: video, atPosition: playHeadTime, presenting: vc)
        }
    }

    /**
      This adapter method is deprecated.
    */
    func goToViewController(forGUID guid: String,
                            onSuccess successCallback: @escaping (UIViewController) -> Void,
                            onFailure failureCallback: @escaping (Error) -> Void) {
    }
}
