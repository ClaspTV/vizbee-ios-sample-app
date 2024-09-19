//
// VizbeeAppAdapter.swift
// This is the template for writing a custom VizbeeAppAdapter
//

import VizbeeKit

class VizbeeAppAdapter: NSObject, VZBAppAdapterDelegate {

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
      
        // EXAMPLE:
        /*
        if let video = appVideoObject as? VideoModel {

                let metadata = VZBVideoMetadata()
                metadata.guid = video.id
                metadata.title = video.title
                metadata.subTitle = video.subtitle
                metadata.imageURL = video.imageUrl
                metadata.isLive = video.isLive
                metadata.customMetadata = [
                    "userId": ""
                ]

                successCallback(metadata)
            } else {
                failureCallback(NSError(domain: "Unrecognized video type: \(appVideoObject)", code: 2, userInfo: nil))
                return
            }
        }
        */
      
        // default
        failureCallback(NSError(domain: "Not implemented", code: 2, userInfo: nil))
    }

    /**
      This adapter method is invoked by the Vizbee SDK to get
      streaming info in the Vizbee format for a given video.

      - Parameter appVideoObject: The videoObject used in the app
      - Parameter forScreen: The target screen to which the video is being cast
      - Parameter successCallback: callback on successful creation of VZBStreamInfo 
      - Parameter failureCallback: callback on failure  
    */
    func getVZBStreamInfo(fromVideo appVideoObject: Any,
                          for _: VZBScreenType,
                          onSuccess successCallback: @escaping (VZBVideoStreamInfo) -> Void,
                          onFailure failureCallback: @escaping (Error) -> Void) {
        
        // EXAMPLE:
        /*
        if let video = appVideoObject as? VideoModel {
            
              let streamInfo = VZBVideoStreamInfo()
              streamInfo.videoURL = video.hlsURL
              streamInfo.customStreamInfo = [
                                              "authToken" : "<authToken>",
                                              "refreshToken" : "<refreshToken>",
                                              ...
                                            ]
              successCallback(streamInfo)
            
        } else {
            failureCallback(NSError(domain: "Unrecognized video type: \(appVideoObject)", code: 2, userInfo: nil))
        }
        */
      
        // default 
        failureCallback(NSError(domain: "Not implemented", code: 2, userInfo: nil))
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
      - Parameter atPosition: resume position of video
      - Parameter shouldAutoPlay: indicates if the video should start auto playing
      - Parameter viewController: the presenting view controller
    */
    func playVideo(onPhone appVideoObject: Any,
                   atPosition playHeadTime: TimeInterval,
                   shouldAutoPlay: Bool,
                   presenting viewController: UIViewController) {
      
        // EXAMPLE:
        /*
        if let video = playable.videoObject as? VideoModel,
           let playerController = viewController as? PlayerViewController {
             
            playerController.playVideoOnPhone(video: video, atPosition: playHeadTime, shouldAutoPlay: shouldAutoPlay)
        }
        */
    }

    /**
      This adapter method is deprecated.
    */
    func goToViewController(forGUID guid: String,
                            onSuccess _: @escaping (UIViewController) -> Void,
                            onFailure _: @escaping (Error) -> Void) {
        
        // EXAMPLE:
        /*
        AppNavigationCoordinator
            .tryToNavigateToDeepLink(route: DeepLinkRoute.detail(guid, 0))
        */
    }
}
