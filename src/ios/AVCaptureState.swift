    ///Users/innoticalsolutions/Documents/Aman/CommunityWebRtc/ionicRTC/platforms/ios/MyApp/Plugins
    //  AVCaptureState.swift
    //  SwiftyWebRTC
    //
    //  Copyright © 2017 Sachin Kishore. All rights reserved.
    //

    import Foundation
    import AVFoundation

    class AVCaptureState {
        static var isVideoDisabled: Bool{
           let status = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
            return status == .restricted || status == .denied
        }

        static var isAudioDisabled: Bool {
            let status = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeAudio)
            return status == .restricted || status == .denied
        }
    }
