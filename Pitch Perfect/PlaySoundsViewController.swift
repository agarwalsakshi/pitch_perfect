//
//  PlaySoundsViewController.swift
//  Pitch Perfect
//
//  Created by Sakshi Agarwal on 15/12/16.
//  Copyright © 2016 Sakshi Agarwal. All rights reserved.
//

import UIKit
import AVFoundation

// MARK: - PlaySoundsViewController: UIViewController

class PlaySoundsViewController: UIViewController {
    
    // MARK: Properties
    
    var receivedAudio: RecordedAudio!
    private var audioEngine: AVAudioEngine!
    private var audioPlayerNode: AVAudioPlayerNode!
    private var audioFile: AVAudioFile!
    private var stopTimer: NSTimer!
    
    // raw values correspond to sender tags
    enum ButtonType: Int { case Slow = 0, Fast, Chipmunk, Vader, Echo, Reverb }
    enum PlayingState { case Playing, NotPlaying }
    
    @IBOutlet weak var snailButton: UIButton!
    @IBOutlet weak var chipmunkButton: UIButton!
    @IBOutlet weak var rabbitButton: UIButton!
    @IBOutlet weak var vaderButton: UIButton!
    @IBOutlet weak var echoButton: UIButton!
    @IBOutlet weak var reverbButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAudio()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        configureUI(.NotPlaying)
        
        // add handlers for interruptions, route changes, and calls
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: #selector(PlaySoundsViewController.handleInterruption(_:)),
            name: AVAudioSessionInterruptionNotification,
            object: AVAudioSession.sharedInstance())
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: #selector(PlaySoundsViewController.handleRouteChange(_:)),
            name: AVAudioSessionRouteChangeNotification,
            object: AVAudioSession.sharedInstance())
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: #selector(PlaySoundsViewController.handleMediaServicesReset(_:)),
            name: AVAudioSessionMediaServicesWereResetNotification,
            object: AVAudioSession.sharedInstance())
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        stopAudio()
        
        audioEngine = nil
        audioPlayerNode = nil
        audioFile = nil
        receivedAudio = nil
        stopTimer = nil
        
        // remove handlers for interruptions, route changes, and calls
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: AVAudioSessionInterruptionNotification,
            object: AVAudioSession.sharedInstance())
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: AVAudioSessionRouteChangeNotification,
            object: AVAudioSession.sharedInstance())
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: AVAudioSessionMediaServicesWereResetNotification,
            object: AVAudioSession.sharedInstance())
    }
    
    // MARK: Actions
    
    @IBAction func playSoundForButton(sender: UIButton) {
        switch(ButtonType(rawValue: sender.tag)!) {
        case .Slow:
            playSound(rate: 0.5)
        case .Fast:
            playSound(rate: 1.5)
        case .Chipmunk:
            playSound(pitch: 1000)
        case .Vader:
            playSound(pitch: -1000)
        case .Echo:
            playSound(echo: true)
        case .Reverb:
            playSound(reverb: true)
        }
        
        configureUI(.Playing)
    }
    
    @IBAction func stopButtonPressed(sender: AnyObject) {
        stopAudio()
    }
    
    // MARK: Manipulate UI
    
    private func configureUI(playState: PlayingState) {
        switch(playState) {
        case .Playing:
            setPlayButtonsEnabled(false)
            stopButton.enabled = true
        case .NotPlaying:
            setPlayButtonsEnabled(true)
            stopButton.enabled = false
        }
    }
    
    private func setPlayButtonsEnabled(enabled: Bool) {
        snailButton.enabled = enabled
        chipmunkButton.enabled = enabled
        rabbitButton.enabled = enabled
        vaderButton.enabled = enabled
        echoButton.enabled = enabled
        reverbButton.enabled = enabled
    }
    
    private func showAlert(title: String, message: String) {
        setPlayButtonsEnabled(false)
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: AppConstants.Alerts.DismissAlert, style: .Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: Audio

    private func setupAudio() {
        
        // initialize (recording) audio file
        do {
            audioFile = try AVAudioFile(forReading: receivedAudio.filePathURL)
        } catch {
            showAlert(AppConstants.Alerts.AudioFileError, message: String(error))
        }
    }
    
    private func playSound(rate rate: Float? = nil, pitch: Float? = nil, echo: Bool = false, reverb: Bool = false) {

        // initialize audio engine components
        audioEngine = AVAudioEngine()
        
        // node for playing audio
        audioPlayerNode = AVAudioPlayerNode()
        audioEngine.attachNode(audioPlayerNode)

        // node for adjusting rate/pitch
        let changeRatePitchNode = AVAudioUnitTimePitch()
        if let pitch = pitch {
            changeRatePitchNode.pitch = pitch
        }
        if let rate = rate {
            changeRatePitchNode.rate = rate
        }
        audioEngine.attachNode(changeRatePitchNode)

        // www.robotlovesyou.com/mixing-between-effects-with-avfoundation/
        
        // node for echo
        let echoNode = AVAudioUnitDistortion()
        echoNode.loadFactoryPreset(.MultiEcho1)
        audioEngine.attachNode(echoNode)
        
        // node for reverb
        let reverbNode = AVAudioUnitReverb()
        reverbNode.loadFactoryPreset(.Cathedral)
        reverbNode.wetDryMix = 50
        audioEngine.attachNode(reverbNode)
        
        // connect nodes
        if echo == true && reverb == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, echoNode, reverbNode, audioEngine.outputNode)
        } else if echo == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, echoNode, audioEngine.outputNode)
        } else if reverb == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, reverbNode, audioEngine.outputNode)
        } else {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, audioEngine.outputNode)
        }
        
        // schedule to play and start the engine!
        audioPlayerNode.stop()
        audioPlayerNode.scheduleFile(audioFile, atTime: nil) {
            
            var delayInSeconds: Double = 0
            
            if let lastRenderTime = self.audioPlayerNode.lastRenderTime, let playerTime = self.audioPlayerNode.playerTimeForNodeTime(lastRenderTime) {
                
                if let rate = rate {
                    delayInSeconds = Double(self.audioFile.length - playerTime.sampleTime) / Double(self.audioFile.processingFormat.sampleRate) / Double(rate)
                } else {
                    delayInSeconds = Double(self.audioFile.length - playerTime.sampleTime) / Double(self.audioFile.processingFormat.sampleRate)
                }
            }
            
            // schedule a stop timer for when audio finishes playing
            self.stopTimer = NSTimer(timeInterval: delayInSeconds, target: self, selector: #selector(PlaySoundsViewController.stopAudio), userInfo: nil, repeats: false)
            NSRunLoop.mainRunLoop().addTimer(self.stopTimer!, forMode: NSDefaultRunLoopMode)
        }

        do {
            try audioEngine.start()
        } catch {
            showAlert(AppConstants.Alerts.AudioEngineError, message: String(error))
            return
        }
        
        // play the recording!
        audioPlayerNode.play()
    }
    
    func stopAudio() {
        
        if let stopTimer = stopTimer {
            stopTimer.invalidate()
        }

        configureUI(.NotPlaying)
        
        if let audioPlayerNode = audioPlayerNode {
            audioPlayerNode.stop()
        }
        
        if let audioEngine = audioEngine {
            audioEngine.stop()
            audioEngine.reset()
        }
    }
    
    // MARK: Connect List of Audio Nodes
    
    private func connectAudioNodes(nodes: AVAudioNode...) {
        for x in 0..<nodes.count-1 {
            audioEngine.connect(nodes[x], to: nodes[x+1], format: audioFile.processingFormat)
        }
    }
    
    // MARK: AVAudioSession Notifications
    
    func handleInterruption(notification: NSNotification) {
        NSLog("Interruption found.")
        if let interruptionValue = (notification.userInfo)?["AVAudioSessionInterruptionTypeKey"] as? NSNumber {
            if let interruptionType = AVAudioSessionInterruptionType(rawValue: interruptionValue.unsignedLongValue) {
                NSLog("Interruption type: %u", interruptionType.rawValue)
                switch interruptionType {
                case .Began:
                    stopAudio()
                default:
                    break
                }
            }
        }
    }
    
    func handleRouteChange(notification: NSNotification) {
        NSLog("Route change found.")
        if let changeValue = (notification.userInfo)?["AVAudioSessionRouteChangeReasonKey"] as? NSNumber {
            if let changeType = AVAudioSessionRouteChangeReason(rawValue: changeValue.unsignedLongValue) {
                NSLog("Route change type: %u", changeType.rawValue)
                switch changeType {
                case .OldDeviceUnavailable, .NewDeviceAvailable:
                    stopAudio()
                default:
                    break
                }
            }
        }
    }
    
    func handleMediaServicesReset(notification: NSNotification) {
        stopAudio()
        setupAudio()
    }
}
