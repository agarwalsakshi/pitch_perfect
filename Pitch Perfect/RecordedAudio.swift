//
//  RecordedAudio.swift
//  Pitch Perfect
//
//  Created by Sakshi Agarwal on 15/12/16.
//  Copyright © 2016 Sakshi Agarwal. All rights reserved.
//

import Foundation

// MARK: - RecordedAudio: NSObject

class RecordedAudio: NSObject {
    
    // MARK: Properties
    
    var filePathURL: NSURL!
    var title: String! {
        get {
            return filePathURL.lastPathComponent
        }
    }

    // MARK: Initializers
    
    init(filePathURL: NSURL) {
        self.filePathURL = filePathURL
    }
}
