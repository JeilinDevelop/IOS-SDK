//
//  URL.swift
//  Polaroid
//
//  Created by jxcs on 2025/9/28.
//

import CommonCrypto
import Foundation

extension URL {
    /// 计算文件 MD5
    func md5() -> String? {
        guard let file = try? FileHandle(forReadingFrom: self) else { return nil }
        
        var context = CC_MD5_CTX()
        CC_MD5_Init(&context)
        
        while autoreleasepool(invoking: {
            let data = file.readData(ofLength: 1024 * 1024) // 1MB buffer
            if data.count > 0 {
                data.withUnsafeBytes {
                    _ = CC_MD5_Update(&context, $0.baseAddress, CC_LONG(data.count))
                }
                return true // 继续读
            } else {
                return false // 读完
            }
        }) {}
        
        var digest = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        digest.withUnsafeMutableBytes {
            _ = CC_MD5_Final($0.bindMemory(to: UInt8.self).baseAddress, &context)
        }
        
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}
