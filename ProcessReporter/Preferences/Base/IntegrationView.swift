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
        gridView.rowSpacing = 16
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
        gridView.cell(for: leftView)?.xPlacement = .trailing

        // 设置行高
        let row = gridView.row(at: gridView.numberOfRows - 1)
        row.height = 22 // 设置统一的行高

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
    }
}
