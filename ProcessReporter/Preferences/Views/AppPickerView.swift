//
//  AppPickerView.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/13.
//
import SwiftUI

// Add AppPickerView to show a dialog for selecting applications
struct AppPickerView: View {
	@Environment(\.dismiss) private var dismiss
	@State private var installedApps: [AppItem] = []
	@State private var searchText: String = ""

	var onSelectApp: (String?, URL?) -> Void

	var body: some View {
		VStack {
			TextField("Search applications", text: $searchText)
				.textFieldStyle(.roundedBorder)
				.padding()

			List {
				ForEach(filteredApps, id: \.id) { app in
					Button(action: {
						onSelectApp(app.applicationIdentifier, app.url)
					}) {
						HStack {
							Image(nsImage: NSWorkspace.shared.icon(forFile: app.url.path))
								.resizable()
								.frame(width: 24, height: 24)
							Text(app.name)
							Spacer()
						}
						.contentShape(Rectangle())
					}
					.buttonStyle(.plain)
				}
			}

			HStack {
				Spacer()
				Button("Cancel") {
					onSelectApp(nil, nil)
				}
				.keyboardShortcut(.cancelAction)
			}
			.padding()
		}
		.onAppear {
			loadInstalledApps()
		}
	}

	typealias AppItem = (id: String, name: String, url: URL, applicationIdentifier: String)
	private var filteredApps: [AppItem] {
		if searchText.isEmpty {
			return installedApps
		} else {
			return installedApps.filter { app in
				app.name.localizedCaseInsensitiveContains(searchText)
			}
		}
	}

	private func loadInstalledApps() {
		let fileManager = FileManager.default
		guard
			let appFolders = try? fileManager.contentsOfDirectory(
				at: URL(fileURLWithPath: "/Applications"), includingPropertiesForKeys: nil
			)
		else {
			return
		}

		var apps: [AppItem] = []

		for url in appFolders {
			if url.pathExtension == "app", let bundle = Bundle(url: url),
			   let bundleId = bundle.bundleIdentifier
			{
				let appName = url.deletingPathExtension().lastPathComponent
				apps.append((id: bundleId + url.absoluteString, name: appName, url: url, applicationIdentifier: bundleId))
			}
		}

		installedApps = apps.sorted(by: { $0.name < $1.name })
	}
}

extension AppPickerView {
	static func showAppPicker(for anchorView: NSView, completion: @escaping (String?, URL?) -> Void) {
		let appPicker = AppPickerView(onSelectApp: completion)
		let hostingController = NSHostingController(rootView: appPicker)

		let popover = NSPopover()
		popover.contentViewController = hostingController
		popover.behavior = .transient
		popover.contentSize = NSSize(width: 400, height: 500)
		popover.show(relativeTo: anchorView.bounds, of: anchorView, preferredEdge: .maxY)
	}
}
