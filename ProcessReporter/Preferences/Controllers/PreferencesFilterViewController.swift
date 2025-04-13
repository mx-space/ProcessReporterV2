//
//  PreferencesFilterViewController.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/13.
//

import AppKit
import SnapKit
import SwiftUI

class PreferencesFilterViewController: NSViewController, SettingWindowProtocol {
    let frameSize: NSSize = .init(width: 600, height: 400)

    private var preferencesHostingController: PreferencesHostingController?
    override func loadView() {
        super.loadView()
        preferencesHostingController = PreferencesHostingController()
        view.addSubview(preferencesHostingController!.view)
        addChild(preferencesHostingController!)
        view.snp.makeConstraints { make in
            make.height.equalTo(frameSize.height)
            make.width.equalTo(frameSize.width)
        }
        preferencesHostingController!.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
