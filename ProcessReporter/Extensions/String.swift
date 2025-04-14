//
//  String.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/14.
//

import Foundation
import CryptoKit

extension String {
    func sha256() -> String {
        let data = Data(self.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
