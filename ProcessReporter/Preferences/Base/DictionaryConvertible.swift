//
//  DictionaryConvertible.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/9.
//

import Foundation

protocol DictionaryConvertible {
    func toDictionary() -> [String: Any]
    static func fromDictionary(_ dict: Any) -> Self
}

protocol DictionaryConvertibleDelegate {
    func toDictionary() -> Any
}

extension DictionaryConvertible {
    func toDictionary() -> [String: Any] {
        let mirror = Mirror(reflecting: self)
        var dict: [String: Any] = [:]

        for child in mirror.children {
            guard let propertyName = child.label else { continue }
            if let child = child.value as? DictionaryConvertibleDelegate {
                dict[propertyName] = child.toDictionary()
            }
            else if let child = child.value as? DictionaryConvertible {
                dict[propertyName] = child.toDictionary()

            } else {
                dict[propertyName] = child.value
            }
        }

        return dict
    }
}
