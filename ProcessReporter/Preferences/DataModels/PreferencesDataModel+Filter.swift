//
//  PreferencesDataModel+Filter.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/13.
//

import Foundation
import RxCocoa
import RxSwift

// Extension for filter-related preferences
extension PreferencesDataModel {
  @UserDefaultsRelay("filteredProcesses", defaultValue: [])
  static var filteredProcesses: BehaviorRelay<[String]>

  @UserDefaultsRelay("filteredMediaProcesses", defaultValue: [])
  static var filteredMediaProcesses: BehaviorRelay<[String]>
}
