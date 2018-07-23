//
//  DemoIonic.swift
//  WebRTCDemo
//
//  Created by Sachin kishore on 13/06/18.
//  Copyright © 2018 Innotical  Solutions . All rights reserved.
//

import Foundation
import AVFoundation
import WebRTC
let TAG: String = "SACHIN"
let SCREEN_WIDTH = UIScreen.main.bounds.width
let SCREEN_HEIGHT = UIScreen.main.bounds.height

@objc(CommunityWebRtc) class CommunityWebRtc : CDVPlugin , RTCClientDelegate  , RTCEAGLVideoViewDelegate{
    
    var speakerBtn : UIImageView!
    var callImageView : UIImageView!
    var callLocalView : RTCEAGLVideoView!
    var callRemoteView : RTCEAGLVideoView!
    var upperNavView : UIView!
    var currentStatusLabel : UILabel!
    var doctorLabel : UILabel!
    var familyCareCallType : UILabel!
    var acceptBtn : UIImageView!
    var rejectBtn : UIImageView!
    var localMediaStream: RTCMediaStream!
    var localVideoTrack1 : RTCVideoTrack!
    var remoteVideoTrack1  : RTCVideoTrack!
    var videoClient: RTCClient?
    var captureController: RTCCapturer!
    var sdpOffer = ""
    var isCallComing = false
    var isVideoCall = true
    var callBckCommand : CDVInvokedUrlCommand!
    var callTimer : Timer?
    var countSec = 0
    var countMin = 0
    var countHr = 0
    var isAccepted = false
    var stunServer: String!
    var secStr = ""
    var minStr = ""
    var hrStr = ""
    var isSpeakerOff = true
    var isSpeakerOffUrl = ""
    var isSpeakerOnUrl = ""
    var isSpeakerOffImage : UIImage?
    var isSpeakerOnImage : UIImage?
    var busyTimer : Timer?
    var notPicked : Timer?
    var busySec = 0
    var notPicSec = 0
    var callPicked = false
    
    func echo(_ command: CDVInvokedUrlCommand) {
        self.callBckCommand = command
        var pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR,
            messageAs: "error"
        )
        let msg = command.arguments[0] as? String ?? ""
        self.handleMsgFromIonic(msg: msg)
        
        pluginResult = CDVPluginResult(
            status: CDVCommandStatus_OK,
            messageAs: "success command"
        )
        
        self.commandDelegate!.send(
            pluginResult,
            callbackId: command.callbackId
        )
    }
    override func awakeFromNib() {
    }
    func configureVideoClient() {
        print(self.stunServer)
        let iceServers = RTCIceServer.init(urlStrings: [self.stunServer], username: "", credential: "")
        print(iceServers)
        let client = RTCClient.init(iceServers: [iceServers], videoCall: true)
        print(self.isVideoCall)
        client.delegate = self
        self.videoClient = client
        client.startConnection()
        print(TAG,"configureVideoClient")
    }
    func rtcClient(client: RTCClient, didCreateLocalCapturer capturer: RTCCameraVideoCapturer) {
        let settingsModel = RTCCapturerSettingsModel()
        self.captureController = RTCCapturer.init(withCapturer: capturer, settingsModel: settingsModel)
        captureController.startCapture()
    }
    func rtcClient(client : RTCClient, didReceiveError error: Error) {
        print(TAG,"didReceiveError")
    }
    func rtcClient(client : RTCClient, didGenerateIceCandidate iceCandidate: RTCIceCandidate) {
        print(TAG,"iceCandidate")
        print(iceCandidate)
        DispatchQueue.main.async {
            let candidate = ["candidate" : iceCandidate.sdp,
                             "sdpMid" : iceCandidate.sdpMid ?? "",
                             "sdpMLineIndex" : iceCandidate.sdpMLineIndex] as [String : Any]
            let dict : [String : Any] = ["type":"iceCandidate",
                                         "data" : candidate]
            self.callJS(data: dict.json)
        }
    }
    func rtcClient(client : RTCClient, startCallWithSdp sdp: String) {
        print(sdp)
        let dict : [String : Any] = ["type":"sdp",
                                     "data" : sdp.description]
        self.callJS(data: dict.json)
    }
    func rtcClient(client : RTCClient, didReceiveLocalVideoTrack localVideoTrack: RTCVideoTrack) {
        print("didReceiveLocalVideoTrack",self.isVideoCall)
        setViewOfVideo()
        if self.isVideoCall{
            self.isSpeakerOff = false
            self.callLocalView.isHidden = false
            try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
        }else{
            self.isSpeakerOff = true
            self.callLocalView.isHidden = true
            self.SetSpeakerOn()
        }
        localVideoTrack.add(self.callLocalView)
        self.videoClient?.makeOffer()
    }
    func rtcClient(client : RTCClient, didReceiveRemoteVideoTrack remoteVideoTrack: RTCVideoTrack) {
        print("didReceiveRemoteVideoTrack")
        DispatchQueue.main.async {
            self.callTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.ShowTimerCount), userInfo: nil, repeats: true)
            self.remoteVideoTrack1 = remoteVideoTrack
            if !self.isCallComing{
                if !self.isVideoCall{
                    self.speakerBtn.frame = CGRect.init(x: SCREEN_WIDTH/2-60, y: SCREEN_HEIGHT-100, width: 60, height: 60)
                    self.rejectBtn.frame = CGRect.init(x: SCREEN_WIDTH/2+20, y: SCREEN_HEIGHT-100, width: 60, height: 60)
                    self.speakerBtn.isHidden = true
                    self.isSpeakerOff = true
                    self.SetSpeakerOn()
                }
            }
            self.perform(#selector(self.calling), with: nil, afterDelay: 1.0)
        }
    }
    func videoView(_ videoView: RTCEAGLVideoView, didChangeVideoSize size: CGSize) {
        print(size)
        print(videoView.frame.size)
    }
    
    @objc func calling(){
        print("yes")
        self.callPicked = true
        self.isAccepted = true
        if self.isVideoCall{
            DispatchQueue.main.async {
                self.callImageView.isHidden = true
                self.remoteVideoTrack1.add(self.callRemoteView)
            }
        }else{
            DispatchQueue.main.async {
                self.callImageView.isHidden = false
                self.remoteVideoTrack1.add(self.callRemoteView)
            }
        }
    }
    @objc func ShowTimerCount(){
        countSec = countSec + 1
        if countSec == 60{
            countSec = 0
            countMin = countMin + 1
        }
        if countMin == 60{
            countMin = 0
            countHr = countHr + 1
        }
        if countSec < 10 {
            self.secStr = "0\(countSec)"
        }else{
            self.secStr = "\(countSec)"
        }
        if countMin < 10 {
            self.minStr = "0\(countMin)"
        }else{
            self.minStr = "\(countMin)"
        }
        if countHr < 10 {
            self.hrStr = "0\(countHr)"
        }else{
            self.hrStr = "\(countHr)"
        }
        self.currentStatusLabel.text = "\(hrStr) : \(minStr) : \(secStr) "
    }
    func setAudioOutputSpeaker(){
        // try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
    }
    func setViewOfVideo(){
        self.callLocalView = RTCEAGLVideoView.init(frame: CGRect(x: SCREEN_WIDTH-130, y: SCREEN_HEIGHT-280, width: 120, height: 150))
        self.callRemoteView.contentMode = .center
        self.callLocalView.contentMode = .scaleAspectFit
        callRemoteView.addSubview(callLocalView)
    }
    func removeStream(){
        self.minStr = ""
        self.hrStr = ""
        self.secStr = ""
        self.remoteVideoTrack1 = nil
        self.countHr = 0
        self.countSec = 0
        self.countMin = 0
        self.isSpeakerOff = true
        self.videoClient?.disconnect()
        self.busySec = 0
        self.notPicSec = 0
        self.callPicked = false
        self.rejectNotPickedTimer()
        self.rejectBusyTimer()
    }
}
extension CommunityWebRtc{
    func addCallerView(image:String , isCallComing : Bool, appName : String , doctorName : String , status : String , rejectStr : String , acceptStr : String) {
        self.isAccepted = false
        self.isSpeakerOff = true
        callRemoteView = RTCEAGLVideoView.init(frame: CGRect.init(x: 0, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT))
        callRemoteView.backgroundColor = UIColor.white
        self.callRemoteView.delegate = self
        callImageView = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT))
        if let url = URL.init(string: image){
            downloadImage(url: url, value: "user")
        }
        callImageView.contentMode = .scaleToFill
        callImageView.backgroundColor = UIColor.white
        callRemoteView.addSubview(callImageView)
        upperNavView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: SCREEN_WIDTH, height: 125))
        upperNavView.alpha = 0.78
        upperNavView.backgroundColor = UIColor.darkGray
        familyCareCallType = UILabel.init(frame: CGRect.init(x: 10, y: 25, width: SCREEN_WIDTH-10, height: 22))
        familyCareCallType.text = appName
        familyCareCallType.textColor = UIColor.white
        familyCareCallType.textAlignment = .left
        familyCareCallType.font = UIFont.systemFont(ofSize: 13)
        doctorLabel = UILabel.init(frame: CGRect.init(x: 10, y: 52, width: SCREEN_WIDTH-10, height: 30))
        doctorLabel.text = doctorName
        doctorLabel.textColor = UIColor.white
        doctorLabel.textAlignment = .left
        doctorLabel.font = UIFont.systemFont(ofSize: 16)
        currentStatusLabel = UILabel.init(frame: CGRect.init(x: 10, y: 87, width: SCREEN_WIDTH-10, height: 22))
        currentStatusLabel.text = status.capitalized
        currentStatusLabel.textColor = UIColor.white
        currentStatusLabel.textAlignment = .left
        currentStatusLabel.font = UIFont.systemFont(ofSize: 13)
        upperNavView.addSubview(familyCareCallType)
        upperNavView.addSubview(doctorLabel)
        upperNavView.addSubview(currentStatusLabel)
        callRemoteView.addSubview(upperNavView)
        self.acceptBtn = UIImageView.init(frame: CGRect.init(x: SCREEN_WIDTH/2-60, y: SCREEN_HEIGHT-100, width: 60, height: 60))
        self.speakerBtn = UIImageView.init(frame: CGRect.init(x: SCREEN_WIDTH/2-60, y: SCREEN_HEIGHT-100, width: 60, height: 60))
        self.speakerBtn.isHidden = true
        if isCallComing == true{
            rejectBtn = UIImageView.init(frame: CGRect.init(x: SCREEN_WIDTH/2+20, y: SCREEN_HEIGHT-100, width: 60, height: 60))
            self.acceptBtn.isHidden = false
        }else{
            rejectBtn = UIImageView.init(frame: CGRect.init(x: SCREEN_WIDTH/2 - 40, y: SCREEN_HEIGHT-100, width: 60, height: 60))
            callRemoteView.addSubview(acceptBtn)
            self.acceptBtn.isHidden = true
        }
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(acceptCall(gestureRecognizer:)))
        acceptBtn.addGestureRecognizer(tap1)
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(rejectCall(gestureRecognizer:)))
        let tap3 = UITapGestureRecognizer(target: self, action: #selector(speakerBtnTap(gestureRecognizer:)))
        self.speakerBtn.addGestureRecognizer(tap3)
        rejectBtn.addGestureRecognizer(tap2)
        acceptBtn.backgroundColor = #colorLiteral(red: 0.1843137255, green: 0.5529411765, blue: 0.168627451, alpha: 1)
        self.speakerBtn.isUserInteractionEnabled = true
        self.speakerBtn.backgroundColor = UIColor.white
        self.speakerBtn.layer.cornerRadius = 30
        self.acceptBtn.isUserInteractionEnabled = true
        self.rejectBtn.isUserInteractionEnabled = true
        acceptBtn.contentMode = .center
        rejectBtn.contentMode = .center
        self.speakerBtn.contentMode = .center
        acceptBtn.layer.cornerRadius = 30
        acceptBtn.isUserInteractionEnabled = true
        rejectBtn.backgroundColor = UIColor.red
        rejectBtn.layer.cornerRadius = 30
        rejectBtn.clipsToBounds = true
        callRemoteView.addSubview(speakerBtn)
        callRemoteView.addSubview(rejectBtn)
        callRemoteView.addSubview(acceptBtn)
        if let url = URL.init(string: acceptStr){
            downloadImage(url: url, value: "accept")
        }
        if let url = URL.init(string: rejectStr){
            downloadImage(url: url, value: "reject")
        }
        if let url = URL.init(string: self.isSpeakerOnUrl){
            self.downloadImage(url: url, value: "speaker2")
        }
        if let url = URL.init(string: self.isSpeakerOffUrl){
            self.downloadImage(url: url, value: "speaker1")
        }
        
        if let appl = UIApplication.shared.delegate as? CDVAppDelegate{
            self.callRemoteView.backgroundColor = UIColor.white
            appl.window.addSubview(callRemoteView)
            appl.window.bringSubview(toFront: callRemoteView)
        }
    }
    @objc internal func acceptCall(gestureRecognizer: UITapGestureRecognizer) {
        print("acceptCall")
        self.rejectBtn.frame = CGRect.init(x: SCREEN_WIDTH/2+20, y: SCREEN_HEIGHT-100, width: 60, height: 60)
        if self.isVideoCall{
            UIView.animate(withDuration: 0.33) {
                self.rejectBtn.frame = CGRect.init(x: SCREEN_WIDTH/2 - 40, y: SCREEN_HEIGHT-100, width: 60, height: 60)
            }
        }else{
            self.speakerBtn.isHidden = false
        }
        self.acceptBtn.isHidden = true
        if self.isCallComing{
            self.configureVideoClient()
            self.currentStatusLabel.text = "CONNECTED"
        }
    }
    @objc internal func rejectCall(gestureRecognizer: UITapGestureRecognizer) {
        print("rejectCall")
        if self.isAccepted{
            self.rejectTimer()
        }
        self.removeStream()
        self.callRemoteView.removeFromSuperview()
        let rejectDict : [String:Any] = ["reason" : "userReject",
                                         "isAccepted" : self.isAccepted, "isCallComing" : self.isCallComing] //might needs to change
        let dict : [String : Any] = ["type":"cancel",
                                     "data" : rejectDict]
        self.callJS(data: dict.json)
    }
    @objc internal func speakerBtnTap(gestureRecognizer: UITapGestureRecognizer) {
        print("speakerBtnTap")
        self.isSpeakerOff = !self.isSpeakerOff
        self.SetSpeakerOn()
        
    }
    func rejectTimer(){
        if self.callTimer != nil{
            self.callTimer?.invalidate()
            self.callTimer = nil
        }
    }
    func callJS(data: String) {
        let javaScript = "cordova.plugins.CommunityWebRtc.callbackResult(\(data))"
        DispatchQueue.main.async {
            if let appl = UIApplication.shared.delegate as? CDVAppDelegate{
                appl.viewController.webViewEngine.evaluateJavaScript(javaScript, completionHandler: { (res, err) in
                    print("response is ", res ?? "response nil")
                    print("error is ", err ?? "error nil")
                })
            }
            print("hello", data)
        }
    }
}
extension CommunityWebRtc  {
    func handleMsgFromIonic(msg : String){
        let value = msg.dictionary
        print(value)
        if let type = value["type"] as? String{
            switch type {
            case IonicTypes.incomingCall.rawValue:
                print(IonicTypes.incomingCall.rawValue)
                if let data = value["data"] as? [String : Any] {
                    let img = data["img"] as! String
                    let name = data["name"] as! String
                    let callType = data["callType"] as! String
                    let appName = data["appName"] as! String
                    let acc = data["accept"] as! String
                    let rec = data["reject"] as! String
                    let setting = data["settings"] as! [String:Any]
                    let stun = setting["stun"] as! String
                    self.isSpeakerOffUrl =  data["off"] as! String //volume
                    self.isSpeakerOnUrl =  data["on"] as! String //volume_cut
                    self.stunServer = stun
                    if callType == "A"{
                        self.isVideoCall = false
                    }else{
                        self.isVideoCall = true
                    }
                    self.isCallComing = true
                    self.addCallerView(image: img, isCallComing: isCallComing, appName: appName, doctorName: name, status: "Incoming Call", rejectStr: rec, acceptStr: acc)
                }
            case IonicTypes.timerReject.rawValue:
                print(IonicTypes.timerReject.rawValue)
                self.removeStream()
                self.callRemoteView.removeFromSuperview()
                if self.isAccepted{
                    self.rejectTimer()
                }
                if let data = value["data"] as? [String:Any]{
                    
                    if let res = data["response"] as? String{
                        if res == "rejected"{
                            let rejectDict : [String:Any] = ["reason" : "userReject", "response": res, "isAccepted" : self.isAccepted, "isCallComing" : self.isCallComing]
                            let dict : [String : Any] = ["type":"cancel", "data" : rejectDict]
                            self.callJS(data: dict.json)
                            return
                        }
                    }
                    
                    if let res2 = data["id"] as? String{
                        if res2 == "stopCommunication" {
                            let rejectDict : [String:Any] = ["reason" : "stopCommunication",
                                                             "isAccepted" : self.isAccepted, "isCallComing" : self.isCallComing] //might needs to change
                            let dict : [String : Any] = ["type":"stopCommunication",
                                                         "data" : rejectDict]
                            self.callJS(data: dict.json)
                            return
                        }
                    }
                    
                }
                let rejectDict : [String:Any] = ["reason" : "userReject",
                                                 "isAccepted" : self.isAccepted, "isCallComing" : self.isCallComing] //might needs to change
                let dict : [String : Any] = ["type":"cancel",
                                             "data" : rejectDict]
                self.callJS(data: dict.json)
            case IonicTypes.iceCandidate.rawValue:
                if let data = value["data"] as? [String : Any] {
                    self.caseOnCandidate(dict: data)
                }
            case IonicTypes.sdp_callResponse.rawValue:
                if let data = value["data"] as? String {
                    print(data)
                    self.caseOnAnswer(sdpAns: data)
                }
            case IonicTypes.sdp_startCommunication.rawValue:
                if let data = value["data"] as? String {
                    print(data)
                    self.caseOnAnswer(sdpAns: data)
                }
            case IonicTypes.call.rawValue:
                if let data = value["data"] as? [String : Any] {
                    let img = data["img"] as! String
                    let name = data["name"] as! String
                    let callType = data["callType"] as! String
                    let appName = data["appName"] as! String
                    let acc = data["accept"] as! String
                    let rec = data["reject"] as! String
                    if callType == "A"{
                        self.isVideoCall = false
                    }else{
                        self.isVideoCall = true
                    }
                    let setting = data["settings"] as! [String:Any]
                    let stun = setting["stun"] as! String
                    self.stunServer = stun
                    self.isSpeakerOffUrl =  data["off"] as! String
                    self.isSpeakerOnUrl =  data["on"] as! String
                    self.isCallComing = false
                    self.addCallerView(image: img, isCallComing: isCallComing, appName: appName, doctorName: name, status: "Connecting", rejectStr: rec, acceptStr: acc)
                    self.configureVideoClient()
                    self.notPicked = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.notPickedTimer), userInfo: nil, repeats: true)
                    
                }
            case IonicTypes.ringing.rawValue:
                if let data = value["data"] as? [String : Any] {
                    if let text = data["text"] as? String{
                        self.currentStatusLabel.text = text.capitalized
                    }
                }
            case IonicTypes.appkilled.rawValue:
                self.removeStream()
                self.callRemoteView.removeFromSuperview()
                if self.isAccepted{
                    self.rejectTimer()
                }
                
                let rejectDict : [String:Any] = ["reason" : "appkilled",
                                                 "isAccepted" : self.isAccepted, "isCallComing" : self.isCallComing] //might needs to change
                let dict : [String : Any] = ["type":"appkilled",
                                             "data" : rejectDict]
                self.callJS(data: dict.json)
            case IonicTypes.busy.rawValue:
                if let data = value["data"] as? [String : Any] {
                    if let text = data["text"] as? String{
                        self.currentStatusLabel.text = text.capitalized
                        self.busyTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.startBusyTimer), userInfo: nil, repeats: true)
                    }
                }
            default:
                print("No type Found")
            }
        }
    }
    func startBusyTimer(){
        self.busySec += 1
        if self.busySec == 5{
            let rejectDict : [String:Any] = ["id" : "busy"]
            let dict : [String : Any] = ["type":"busy",
                                         "data" : rejectDict]
            self.callJS(data: dict.json)
            self.removeStream()
            self.rejectBusyTimer()
          self.callRemoteView.removeFromSuperview()
        }
    }
    
    func notPickedTimer(){
        self.notPicSec += 1
        if self.notPicSec == 45{
            if !self.callPicked{
            let rejectDict : [String:Any] = ["id" : "notpicked"]
            let dict : [String : Any] = ["type":"notpicked",
                                         "data" : rejectDict]
            self.callJS(data: dict.json)
            self.removeStream()
            self.rejectNotPickedTimer()
            self.callRemoteView.removeFromSuperview()
            }
            else{
                self.rejectNotPickedTimer()
            }
        }
    }
    func rejectNotPickedTimer(){
        if self.notPicked != nil{
            self.notPicked?.invalidate()
            self.notPicked = nil
        }
    }
    func rejectBusyTimer(){
        if self.busyTimer != nil{
            self.busyTimer?.invalidate()
            self.busyTimer = nil
        }
    }
    func caseOnCandidate(dict : [String : Any]){
        let mid = dict["sdpMid"] as! String
        let index = dict["sdpMLineIndex"] as! Int
        let sdp = dict["candidate"] as! String
        let candidate : RTCIceCandidate = RTCIceCandidate.init(sdp: sdp, sdpMLineIndex: Int32(index), sdpMid: mid)
        self.videoClient?.addIceCandidate(iceCandidate: candidate)
    }
    func caseOnAnswer(sdpAns : String) -> Void {
        self.videoClient?.handleAnswerReceived(withRemoteSDP: sdpAns)
    }
    func createAnswerForOfferReceived(sdpAns : String) -> Void {
        self.videoClient?.createAnswerForOfferReceived(withRemoteSDP: sdpAns)
    }
}
extension CommunityWebRtc{
    func getDataFromUrl(url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            completion(data, response, error)
            }.resume()
    }
    func SetSpeakerOn()
    {
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
        try? AVAudioSession.sharedInstance().setActive(true)
        if self.isSpeakerOff{
            self.speakerBtn.image = self.isSpeakerOffImage
            try? AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSessionPortOverride.none)
        }else{
            self.speakerBtn.image = self.isSpeakerOnImage
            try? AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSessionPortOverride.speaker)
        }
        
    }
    
    func downloadImage(url: URL,value : String){
        print("Download Started")
        getDataFromUrl(url: url) { data, response, error in
            guard let data = data, error == nil else { return }
            print(response?.suggestedFilename ?? url.lastPathComponent)
            print("Download Finished")
            DispatchQueue.main.async() {
                if value == "user"{
                    self.callImageView.image = UIImage.init(data: data)
                }else if value == "accept"{
                    self.acceptBtn.image = resizeImage(image: UIImage.init(data: data)!, targetSize: CGSize(width: 23, height: 23))
                }
                else if value == "reject"{
                    self.rejectBtn.image = resizeImage(image: UIImage.init(data: data)!, targetSize: CGSize(width: 13, height: 13))
                }
                else if value == "speaker1"{
                    self.isSpeakerOffImage = resizeImage(image: UIImage.init(data: data)!, targetSize: CGSize(width: 20, height: 20))
                }
                else if value == "speaker2"{
                    self.isSpeakerOnImage = resizeImage(image: UIImage.init(data: data)!, targetSize: CGSize(width: 20, height: 20))
                }
                
            }
        }
    }
}
extension Dictionary {
    var json: String {
        let invalidJson = "Not a valid JSON"
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
            return String(bytes: jsonData, encoding: String.Encoding.utf8) ?? invalidJson
        } catch {
            return invalidJson
        }
    }
    func printJson() {
        print(json)
    }
}
extension String {
    var dictionary : [String : Any] {
        let dict: Dictionary<String, Any> = [:]
        if let data = self.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return dict
    }
    func printDict() {
        print(dictionary)
    }
}
func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
    let size = image.size
    let widthRatio  = targetSize.width  / size.width
    let heightRatio = targetSize.height / size.height
    var newSize: CGSize
    if(widthRatio > heightRatio) {
        newSize = CGSize.init(width: size.width * heightRatio, height: size.height * heightRatio)
    } else {
        newSize = CGSize.init(width: size.width * heightRatio, height: size.height * heightRatio)
    }
    let rect = CGRect.init(x: 0, y: 0, width: newSize.width, height: newSize.height)
    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    image.draw(in: rect)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return newImage!
}
enum IonicTypes:String{
    case ringing = "ringing"
    case registerResponse = "registerResponse"
    case callResponse = "callResponse"
    case incomingCall = "incomingCall"
    case startCommunication = "startCommunication"
    case stopCommunication = "stopCommunication"
    case iceCandidate = "iceCandidate"
    case sdp_callResponse = "sdp_callResponse"
    case sdp_startCommunication = "sdp_startCommunication"
    case timerReject = "timerReject"
    case call = "call"
    case appkilled = "appkilled"
    case busy = "busy"
   
}

