import Foundation
import UIKit
import Flutter
import EmbraceIO

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

    override init() {
        super.init()
        do {
            // To capture push notifications, build capture services explicitly and pass
            // KSCrashReporter() as the crashReporter. EmbraceCrashReporter is an internal
            // wrapper class and is not a valid value for the crashReporter parameter.
            let captureServices = CaptureServiceBuilder()
                .addDefaults()
                .add(.pushNotification())
                .build()
            try Embrace
                .setup(
                    options: Embrace.Options(
                        appId: "12345",
                        platform: .flutter,
                        captureServices: captureServices,
                        crashReporter: KSCrashReporter()
                    )
                )
                .start()
        } catch let e {
            print("Error starting Embrace \(e.localizedDescription)")
        }
    }

    func didInitializeImplicitFlutterEngine(_ engineBridge: any FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    }
}
