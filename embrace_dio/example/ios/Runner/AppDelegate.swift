import Foundation
import UIKit
import Flutter
import EmbraceIO
import EmbraceCore
import EmbraceCrash

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

    override init() {
        super.init()
        do {
            try Embrace
                .setup(
                    options: Embrace.Options(
                        appId: "12345",
                        platform: .flutter
                    )
                )
                .start()
        } catch let e {
            print("Error starting Embrace \(e.localizedDescription)")
        }
    }

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
