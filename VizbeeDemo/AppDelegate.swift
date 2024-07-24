import UIKit
import VizbeeKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Create root UIViewController
        let videoViewController = VideoListViewController(nibName: "VideoListViewController", bundle: nil)
        let navigationController = UINavigationController(rootViewController: videoViewController)
        
        // Setup Cast Bar
        setupCastContainer(with: navigationController)
        
        // Initialize Vizbee SDK
        VizbeeWrapper.shared.initVizbeeSDK()
        
        // start listening for connection state changes
        NotificationCenter.default.addObserver(self, selector: #selector(handleOnConnection(_:)), name: NSNotification.Name(VizbeeWrapper.kVZBCastConnected), object: nil)
        
        // listen for message
        listenForMessages()

        return true
    }
    
    /// handle tv connection state
    @objc func handleOnConnection(_ noitification: NSNotification) {
        
        print("Vizbee::AppDelegate: handleOnConnection - Mobile is now connected to the TV.")
        
        // send initial message on connection if needed
        let mobileToTVMessager = VizbeeWrapper.shared.mobileToTVMessager
        if let eventName = mobileToTVMessager?.kEventName, let message = mobileToTVMessager?.getMessage() {
            mobileToTVMessager?.send(eventName:eventName, data: message)
        }
    }
    
    /// Handle received messages from the connected TV
    func listenForMessages() {
        
        // Set up message listener
        let mobileToTVMessager = VizbeeWrapper.shared.mobileToTVMessager
        mobileToTVMessager?.setMessageListener { connectedTVInfo, messageName, message in
            // Message received from TV
            print("Vizbee::AppDelegate: listenForMessages - Received message from TV \(connectedTVInfo.friendlyName) MessageName: '\(messageName)', Message: \(message)")
            
            // Add your custom handling logic here
        }
    }

    /**
     * Let VizbeeKit manage the layout of the mini controller by wrapping your
     * existing view controller with its own UIViewController.
     *
     * - Parameter rootViewController: Application's root UIViewController
     */
    func setupCastContainer(with rootViewController: UIViewController) {
        let castContainer = Vizbee.createUICastContainer(for: rootViewController)
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = castContainer
        self.window?.makeKeyAndVisible()
    }

    func applicationWillResignActive(_ application: UIApplication) {}
    
    func applicationDidEnterBackground(_ application: UIApplication) {}
    
    func applicationWillEnterForeground(_ application: UIApplication) {}
    
    func applicationDidBecomeActive(_ application: UIApplication) {}
    
    func applicationWillTerminate(_ application: UIApplication) {}
}
