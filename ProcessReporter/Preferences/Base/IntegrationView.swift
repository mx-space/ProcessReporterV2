//
//  IntegrationView.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/8.
//

import Cocoa

class IntegrationView: NSView {
    lazy var gridView: NSGridView = {
        let gridView = NSGridView()
        gridView.rowSpacing = 12
        gridView.columnSpacing = 12
        return gridView
    }()

    func setupUI() {
        addSubview(gridView)
        gridView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(20)
            make.width.lessThanOrEqualToSuperview().inset(40)
        }
    }

    func createRow(leftView: NSView, rightView: NSView) {
        gridView.addRow(with: [leftView, rightView])
        if let cell = gridView.cell(for: leftView) {
            cell.xPlacement = .trailing
            cell.yPlacement = .center
        }
        leftView.snp.makeConstraints { make in
            make.width.lessThanOrEqualTo(120)
        }

        // 设置右侧控件的宽度约束
        if rightView is NSTextField {
            rightView.snp.makeConstraints { make in
                make.width.greaterThanOrEqualTo(200)
            }
        } else if rightView is NSPopUpButton {
            rightView.snp.makeConstraints { make in
                make.width.equalTo(120)
            }
        }
        rightView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(22)
        }
    }
}
