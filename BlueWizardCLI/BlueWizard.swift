//
//  BlueWizard.swift
//  BlueWizardCLI
//
//  Created by PJ Gray on 6/16/22.
//

import Cocoa

class BlueWizard: NSObject {
    func load(filename: String, success: ((_ byteStreamString: String) -> Void)?, failure: ((_ error: Error?) -> Void)? ) {
        NotificationCenter.default.addObserver(forName: Notification.Name(byteStreamGenerated), object: nil, queue: nil) { notification in
            if let bytestream = notification.object as? String {
                success?(bytestream)
            }
        }
        if FileManager.default.fileExists(atPath: filename) {
            UserSettings.sharedInstance().includeExplicitStopFrame = true
            UserSettings.sharedInstance().includeHexPrefix = true
            let url = URL(fileURLWithPath: filename)
            let input = Input(url: url)

            let lowPassCutoff: UInt = UserSettings.sharedInstance().lowPassCutoff.uintValue
            let highPassCutoff: UInt = UserSettings.sharedInstance().highPassCutoff.uintValue
            let gain: Float = UserSettings.sharedInstance().gain.floatValue
            let buffer = TimeMachine.process(input?.buffer())
            let filterer = Filterer(buffer: buffer, lowPassCutoffInHZ: lowPassCutoff, highPassCutoffInHZ: highPassCutoff, gain: gain)
            let inputBuffer = filterer?.process()

            if let samples = inputBuffer?.samples(), let size = inputBuffer?.size(), let sampleRate = inputBuffer?.sampleRate() {
              let buffer = Buffer(samples: samples, size: size, sampleRate: sampleRate, start: UserSettings.sharedInstance().startSample.uintValue, end: UserSettings.sharedInstance().endSample.uintValue)
              _ = Processor.process(buffer)
            }
        } else {
            failure?(NSError(domain: "Wav file doesn't exist", code: -999) )
        }
    }
}
