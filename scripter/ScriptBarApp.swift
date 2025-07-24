//
//  ScriptBarApp.swift
//  ScriptBar
//
//  Created by Chandra Dasari on 7/2/25.
//
//
//

import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {
        NSApp.setActivationPolicy(.accessory)
        NSApp.deactivate()
        return false
    }
}

@main
struct ScriptBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var scriptManager = ScriptManager()
    @State private var showingManager = false
    @State private var showingEditor = false
    @State private var defaultNewScript = Script(
        name: "",
        content: "#!/bin/bash\n\n# Your script here\necho \"Hello, World!\"")

    var body: some Scene {
        MenuBarExtra("ScriptBar", systemImage: "suit.spade.fill") {
            VStack {
                // Scripts submenu
                Menu("Scripts") {
                    if scriptManager.scripts.isEmpty {
                        Button("No scripts available") {}
                            .disabled(true)
                    } else {
                        ForEach(scriptManager.scripts) { script in
                            Button(script.name) {
                                Task {
                                    let _ = await scriptManager.runScript(
                                        script)
                                }
                            }
                        }
                    }
                }

                Divider()

                Button("Add New Script") {
                    showingEditor = true
                }
                .keyboardShortcut("n")

                Button("Manage Scripts") {
                    showingManager = true
                }
                .keyboardShortcut("m")

                Divider()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
        }
        .menuBarExtraStyle(.menu)
    }
}

// MARK: - Script Manager
@MainActor
class ScriptManager: ObservableObject {
    @Published var scripts: [Script] = []
    private let scriptsDirectory: URL

    init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        scriptsDirectory = appSupport.appendingPathComponent(
            "MenuBarScriptRunner/Scripts")

        try? FileManager.default.createDirectory(
            at: scriptsDirectory, withIntermediateDirectories: true)

        loadScripts()
    }

    func getAllScripts() -> [Script] {
        return scripts
    }

    func loadScripts() {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: scriptsDirectory, includingPropertiesForKeys: nil)
            let jsonFiles = fileURLs.filter { $0.pathExtension == "json" }

            scripts = jsonFiles.compactMap { url in
                guard let data = try? Data(contentsOf: url),
                    let script = try? JSONDecoder().decode(
                        Script.self, from: data)
                else {
                    return nil
                }
                return script
            }

            scripts.sort { $0.name < $1.name }
        } catch {
            print("Error loading scripts: \(error)")
        }
    }

    func saveScript(_ script: Script) {
        let filename = "\(script.id.uuidString).json"
        let fileURL = scriptsDirectory.appendingPathComponent(filename)

        do {
            let data = try JSONEncoder().encode(script)
            try data.write(to: fileURL)
            loadScripts()
        } catch {
            print("Error saving script: \(error)")
        }
    }

    func deleteScript(_ script: Script) {
        let filename = "\(script.id.uuidString).json"
        let fileURL = scriptsDirectory.appendingPathComponent(filename)

        try? FileManager.default.removeItem(at: fileURL)
        loadScripts()
    }

    func runScript(_ script: Script) async -> (output: String, exitCode: Int32)
    {
        return await withCheckedContinuation { continuation in
            Task {
                let tempDir = FileManager.default.temporaryDirectory
                let tempScriptURL = tempDir.appendingPathComponent(
                    "\(script.id.uuidString).sh")

                do {
                    try script.content.write(
                        to: tempScriptURL, atomically: true, encoding: .utf8)

                    try FileManager.default.setAttributes(
                        [.posixPermissions: 0o755],
                        ofItemAtPath: tempScriptURL.path)

                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: "/bin/bash")
                    process.arguments = [tempScriptURL.path]

                    let pipe = Pipe()
                    process.standardOutput = pipe
                    process.standardError = pipe

                    try process.run()
                    process.waitUntilExit()

                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output =
                        String(data: data, encoding: .utf8) ?? "No output"

                    try? FileManager.default.removeItem(at: tempScriptURL)

                    continuation.resume(
                        returning: (output, process.terminationStatus))
                } catch {
                    continuation.resume(
                        returning: ("Error: \(error.localizedDescription)", -1))
                }
            }
        }
    }
}
