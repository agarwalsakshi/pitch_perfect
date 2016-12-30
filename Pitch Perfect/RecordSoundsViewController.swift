//
//  RecordSoundsViewController.swift
//  Pitch Perfect
//
//  Created by Sakshi Agarwal on 15/12/16.
//  Copyright © 2016 Sakshi Agarwal. All rights reserved.
//

import UIKit
import AVFoundation

// MARK: - RecordSoundsViewController: UIViewController

class RecordSoundsViewController: UIViewController {

    // MARK: Properties
    
    private var audioRecorder: AVAudioRecorder!
    private var audioSession: AVAudioSession!
    private var audioSettings = [String:AnyObject]()
    private var recordingEnabled: Bool!
    private var recordedAudio: RecordedAudio!
    
    enum RecordingState { case WaitingToRecord, Recording, RecordingPaused }
    enum RecordingUIGroup { case Resume, Pause, Stop }
    
    // MARK: Outlets
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var recordingLabel: UILabel!
    @IBOutlet weak var resumeButton: UIButton!
    @IBOutlet weak var resumeLabel: UILabel!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var pauseLabel: UILabel!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var stopLabel: UILabel!
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        audioSettings[AVFormatIDKey] = Int(kAudioFormatMPEG4AAC)
        audioSettings[AVSampleRateKey] = 12000.0
        audioSettings[AVNumberOfChannelsKey] = 1 as NSNumber
        audioSettings[AVEncoderAudioQualityKey] = AVAudioQuality.High.rawValue
        
        if NSFileManager.defaultManager().fileExistsAtPath(audioURL().path!) {
            createRecordingAndSegueWithURL(audioURL())
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        configureUI(.WaitingToRecord)
    }
    
    // MARK: Actions
    
    @IBAction func recordButtonPressed(sender: UIButton) {
        
        configureAudioSession()
        
        guard recordingEnabled == true else {
            showAlert(AppConstants.Alerts.RecordingDisabledTitle, message: AppConstants.Alerts.RecordingDisabledMessage)
            return
        }

        configureUI(.Recording)
        
        do {
            audioRecorder = try AVAudioRecorder(URL: audioURL(), settings: audioSettings)
            audioRecorder.delegate = self
            audioRecorder.record()
        } catch {
            showAlert(AppConstants.Alerts.AudioRecorderError, message: String(error))
        }
    }
    
    @IBAction func resumeButtonPressed(sender: UIButton) {
        configureUI(.Recording)
        audioRecorder.record()
    }
    
    @IBAction func pauseButtonPressed(sender: UIButton) {
        configureUI(.RecordingPaused)
        audioRecorder.pause()
    }
    
    @IBAction func stopButtonPressed(sender: UIButton) {                
        audioRecorder.stop()
    }
    
    // MARK: Setup Audio Session
    
    private func configureAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions: .DefaultToSpeaker)
            try audioSession.setActive(true)
            audioSession.requestRecordPermission { (allowed) in
                self.recordingEnabled = allowed
            }
        } catch {
            showAlert(AppConstants.Alerts.AudioSessionError, message: String(error))
        }
    }
    
    // MARK: Get Audio URL
    
    private func audioURL() -> NSURL {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as [String]
        let documentsDirectory = paths[0]
        let audioURL = NSURL(fileURLWithPath: documentsDirectory).URLByAppendingPathComponent(AppConstants.DefaultAudioFileName)
        return audioURL!
    }
    
    // MARK: Manipulate UI
    
    private func configureUI(recordingState: RecordingState) {
        switch(recordingState) {
        case .WaitingToRecord:
            recordButton.enabled = true
            recordingLabel.text = AppConstants.Labels.ReadyToRecord
            hideRecordingUI(true)
        case .Recording:
            recordButton.enabled = false
            recordingLabel.text = AppConstants.Labels.Recording
            enableRecordingUI(.Pause, enabled: true)
            enableRecordingUI(.Resume, enabled: false)
            hideRecordingUI(false)
        case .RecordingPaused:
            recordingLabel.text = AppConstants.Labels.RecordingPaused
            enableRecordingUI(.Pause, enabled: false)
            enableRecordingUI(.Resume, enabled: true)
        }
    }
    
    private func enableRecordingUI(recordingUIGroup: RecordingUIGroup, enabled: Bool) {
        switch(recordingUIGroup) {
        case .Resume:
            resumeButton.enabled = enabled
            resumeLabel.enabled = enabled
        case .Pause:
            pauseButton.enabled = enabled
            pauseLabel.enabled = enabled
        case .Stop:
            stopButton.enabled = enabled
            stopLabel.enabled = enabled
        }
    }
    
    private func hideRecordingUI(hidden: Bool) {
        resumeButton.hidden = hidden
        resumeLabel.hidden = hidden
        pauseButton.hidden = hidden
        pauseLabel.hidden = hidden
        stopButton.hidden = hidden
        stopLabel.hidden = hidden
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: AppConstants.Alerts.DismissAlert, style: .Default, handler: { (action) in
            self.configureUI(.WaitingToRecord)
        }))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: Prepare For Segue
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let segueIdentifier = segue.identifier where segueIdentifier == AppConstants.FinishedRecordingSegue {
            let destinationViewController = segue.destinationViewController as! PlaySoundsViewController
            let data = sender as! RecordedAudio
            destinationViewController.receivedAudio = data
        }
    }
}

// MARK: - RecordSoundsViewController: AVAudioRecorderDelegate

extension RecordSoundsViewController: AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            createRecordingAndSegueWithURL(audioRecorder.url)
        } else {
            showAlert(AppConstants.Alerts.RecordingFailedTitle, message: AppConstants.Alerts.RecordingFailedMessage)
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(recorder: AVAudioRecorder, error: NSError?) {
        if let error = error {
            showAlert(AppConstants.Alerts.AudioRecordingError, message: error.localizedDescription)
        }
    }
    
    private func createRecordingAndSegueWithURL(audioURL: NSURL) {
        recordedAudio = RecordedAudio(filePathURL: audioURL)
        performSegueWithIdentifier(AppConstants.FinishedRecordingSegue, sender: recordedAudio)
    }
}

