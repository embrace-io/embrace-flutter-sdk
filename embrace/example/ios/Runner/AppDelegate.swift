import Foundation
import UIKit
import Flutter
import EmbraceIO

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

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

    func didInitializeImplicitFlutterEngine(_ engineBridge: any FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    }
}
