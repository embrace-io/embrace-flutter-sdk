import Foundation
import UIKit
import Flutter
import EmbraceIO
// CocoaPods merges every embrace-apple-sdk subspec (including EmbraceCrash) into a single
// EmbraceIO module, so KSCrashReporter is already visible there. SPM keeps them as separate
// modules, so it needs this import explicitly; canImport keeps both build paths working.
#if canImport(EmbraceCrash)
import EmbraceCrash
#endif

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
