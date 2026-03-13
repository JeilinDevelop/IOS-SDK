//
//  File.swift
//  Polaroid
//
//  Created by jxcs on 2025/1/14.
//

import Foundation

class FileUtil {

    static func isVideoFile(fileName: String) -> Bool {
        let lowerCaseFileName = fileName.lowercased()
        return lowerCaseFileName.hasSuffix(".mp4") ||
            lowerCaseFileName.hasSuffix(".avi") ||
            lowerCaseFileName.hasSuffix(".mkv") ||
            lowerCaseFileName.hasSuffix(".mov") ||
            lowerCaseFileName.hasSuffix(".flv") ||
            lowerCaseFileName.hasSuffix(".wmv")
    }

}
