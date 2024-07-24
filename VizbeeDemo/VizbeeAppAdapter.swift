//
// VizbeeAppAdapter.swift
// This is the template for writing a custom VizbeeAppAdapter
//
import VizbeeKit
import UIKit

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
        
        if let video = appVideoObject as? VideoObject {
            
            let metadata = VZBVideoMetadata()
            metadata.guid = video.guid;
            metadata.title = video.title;
            metadata.subTitle = video.subTitle;
            if let imageURL = video.imageURL {
                metadata.imageURL = imageURL
            }
            metadata.isLive = video.isLive;
            
            // cuepoints
            metadata.setCuePointsInSeconds(video.adBreaks)
            
            // custom metadata
            metadata.customMetadata = ["mkey1": "mvalue1", "mkey2" : "mvalue2"];
            
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
        
        if let video = appVideoObject as? VideoObject {
            
            if let contentURL = video.contentURL {
                
                let streamInfo = VZBVideoStreamInfo()
                streamInfo.guid = video.guid;
                streamInfo.videoURL = contentURL;
                
                // set protocol type
                if screenType.suggestedProtocolType == .any {
                    streamInfo.protocolType = .HLS;
                } else {
                    streamInfo.protocolType = screenType.suggestedProtocolType;
                }
                
                // drm info
                if screenType.suggestedDRMType == .any {
                    streamInfo.drmType = .playReady
                } else {
                    streamInfo.drmType = screenType.suggestedDRMType
                }
                streamInfo.drmLicenseURL = URL(string: "http://drm.vizbee.tv/my/custom/url")
                streamInfo.drmCustomData = "myCustomDRMData";
                
                // custom stream infos
                streamInfo.customStreamInfo = ["skey1": "svalue1",
                                               "skey2": "svalue2",
                                               "skey3": ["key1": "value1", "key2": "valu2"]
                                              ];
                
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
    }

    /**
      This adapter method is deprecated.
    */
    func goToViewController(forGUID guid: String,
                            onSuccess successCallback: @escaping (UIViewController) -> Void,
                            onFailure failureCallback: @escaping (Error) -> Void) {
    }
}
