//
//  ViewController.swift
//  HeartRecord
//
//  Created by Admin on 5/9/18.
//  Copyright © 2018 Admin. All rights reserved.
//

import UIKit
import WatchConnectivity
import AudioToolbox

class ViewController: UIViewController, WCSessionDelegate {
    
    //MARK: Properties
    @IBOutlet weak var fileStatusLabel: UILabel!
    var csv = ""
    var share : FileManager! = nil;
    var setup = false
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        let firstLine = "\(String(describing: message.first!.value))"
        let date = Date()
        let calendar = Calendar.current
        var hour = calendar.component(.hour, from: date)%12
        if(hour == 0) { hour = 12 }
        let minutes = calendar.component(.minute, from: date)
        var zeroes = ""
        if(minutes < 10) {
            zeroes = "0"
        }
        var labelText = ""
        let title = message.keys.first!
        if(title.contains("chunk")) {
            if(title.contains(" 0 ")) {
                csv = ""
            }
            csv += firstLine
            let fileSize = "\(round(Double(self.csv.count)/1.024)/1000.0) KB"
            labelText = message.keys.first! + "\n\(fileSize)"
            if(title.contains("final")) {
                labelText = "Data Received at \(hour):\(zeroes)\(minutes) \n\(fileSize)"
                if(title.contains("post")) {
                    self.postPressed()
                }
            }
            sendMessage(["Received":"\(message.keys.first!)"])
        }
        DispatchQueue.main.async {
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            self.fileStatusLabel.text = labelText
            
        }
    }
    
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        DispatchQueue.main.async {
            //let data = try Data(contentsOf: file.fileURL)
            self.share.sendFileURL(url: file.fileURL.absoluteURL)
            //self.csv = String(data: data, encoding: .utf8)!
            self.fileStatusLabel.text = "File Received at \(Date())"
            //let data = NSData.init(contentsOfURL: file.fileURL)
        }
    }

    /// Sends a message to the paired Apple Watch. In order
    /// to prompt the next chunk of data, the message title must be
    /// "Received"
    /// - parameter message: the message to be sent
    func sendMessage(_ message: [String:Any]) {
        if(WCSession.default.isReachable) {
            WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: nil)
        }
        else {
            let alert = UIAlertController(title: "Failed to send message", message: "Failed to connect to watch", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            present(alert, animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if(setup == false) {
            share = FileManager(self)
            let session = WCSession.default
            session.delegate = self
            session.activate()
            setup = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    /// Presents a dialog for the user to authorize the app
    /// to access heart-rate data
    @IBAction func authorizeHealthKitPressed() {
        HealthKitManager.authorizeHealthKit()
    }

    /// Emails the received data as .zip file
    @IBAction func emailPressed() {
        share.emailFile(data: csv)
    }
    
    /// Shares the received data as a .zip file
    @IBAction func shareDataPressed() {
        share.sendFile(data: csv)
    }
    
    /// Post data to server - server address is currently hard coded
    @IBAction func postPressed() {
        share.uploadFile(url: share.createFileUnzipped(csvText: csv))
    }
    
    /// Sends a message with arbitrary contents to the
    /// watch, which will cause it to tap the user's wrist
    @IBAction func tapPressed() {
        sendMessage(["TestConnection": "Ping Watch"])
    }
}
