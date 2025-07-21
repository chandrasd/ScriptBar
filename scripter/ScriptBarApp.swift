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

@main
struct ScriptBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var scriptManager = ScriptManager()
    private weak var manageScriptsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            //TODO: need to change this to diamond concave leftwards tick emoji, currently not available in SF Symbols
            button.image = NSImage(
                systemSymbolName: "suit.spade.fill",
                accessibilityDescription: "Script Runner")
            button.image?.size = NSSize(width: 16, height: 16)
        }

        setupMenu()
    }

    func setupMenu() {
        let menu = NSMenu()
        let runScriptMenu = NSMenu()
        let runScriptItem = NSMenuItem(
            title: "Run Script", action: nil, keyEquivalent: "")
        runScriptItem.submenu = runScriptMenu

        updateRunScriptMenu(runScriptMenu)

        menu.addItem(runScriptItem)
        menu.addItem(NSMenuItem.separator())

        //TODO: need to figure out a better way to do this and fix the editor + allow loading existing scripts
        menu.addItem(
            NSMenuItem(
                title: "Create New Script", action: #selector(createNewScript),
                keyEquivalent: "n"))

        menu.addItem(
            NSMenuItem(
                title: "Manage Scripts", action: #selector(manageScripts),
                keyEquivalent: "m"))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(
            NSMenuItem(
                title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    func updateRunScriptMenu(_ menu: NSMenu) {
        menu.removeAllItems()

        let scripts = scriptManager.getAllScripts()

        if scripts.isEmpty {
            let noScriptsItem = NSMenuItem(
                title: "No scripts available", action: nil, keyEquivalent: "")
            noScriptsItem.isEnabled = false
            menu.addItem(noScriptsItem)
        } else {
            for script in scripts {
                let item = NSMenuItem(
                    title: script.name, action: #selector(runScript(_:)),
                    keyEquivalent: "")
                item.representedObject = script
                item.target = self
                menu.addItem(item)
            }
        }
    }

    @objc func runScript(_ sender: NSMenuItem) {
        guard let script = sender.representedObject as? Script else { return }

        Task {
            await scriptManager.runScript(script)
        }
    }

    // TODO: refactor this to use Script Editor View instead of an alert
    @objc func createNewScript() {
        let alert = NSAlert()
        alert.messageText = "Create New Script"
        alert.informativeText = "Enter the script name and content:"
        alert.alertStyle = .informational

        let inputTextField = NSTextField(
            frame: NSRect(x: 0, y: 40, width: 300, height: 24))
        inputTextField.placeholderString = "Script name"

        let scriptTextView = NSTextView(
            frame: NSRect(x: 0, y: 0, width: 300, height: 120))
        scriptTextView.string =
            "#!/bin/bash\n\n# Your script here\necho \"Hello, World!\""
        scriptTextView.font = NSFont.monospacedSystemFont(
            ofSize: 12, weight: .regular)

        let scrollView = NSScrollView(
            frame: NSRect(x: 0, y: 0, width: 300, height: 120))
        scrollView.documentView = scriptTextView
        scrollView.hasVerticalScroller = true

        let stackView = NSStackView(
            frame: NSRect(x: 0, y: 0, width: 300, height: 164))
        stackView.orientation = .vertical
        stackView.spacing = 8
        stackView.addArrangedSubview(inputTextField)
        stackView.addArrangedSubview(scrollView)

        alert.accessoryView = stackView
        alert.addButton(withTitle: "Create")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            let name = inputTextField.stringValue.trimmingCharacters(
                in: .whitespacesAndNewlines)
            let content = scriptTextView.string

            if !name.isEmpty && !content.isEmpty {
                let script = Script(name: name, content: content)
                scriptManager.saveScript(script)

                // Refresh the menu
                if let runScriptItem = statusItem.menu?.item(at: 0),
                    let runScriptMenu = runScriptItem.submenu
                {
                    updateRunScriptMenu(runScriptMenu)
                }
            }
        }
    }

    @objc func manageScripts() {
        // If window already exists and is visible, bring it to front instead of creating new one
        if let existingWindow = manageScriptsWindow {
            if existingWindow.isVisible {
                existingWindow.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            } else {
                manageScriptsWindow = nil
            }
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "Manage Scripts"
        window.center()

        // Use weak self to avoid retain cycles
        let contentView = ScriptManagerView(scriptManager: scriptManager) { [weak self] in
            guard let self = self else { return }
            if let runScriptItem = self.statusItem.menu?.item(at: 0),
                let runScriptMenu = runScriptItem.submenu
            {
                self.updateRunScriptMenu(runScriptMenu)
            }
        }

        window.contentView = NSHostingView(rootView: contentView)
        
        manageScriptsWindow = window
        
        window.isReleasedWhenClosed = false

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.manageScriptsWindow = nil
        }
    }

    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Script Manager
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

    func runScript(_ script: Script) async {
        await MainActor.run {
            let alert = NSAlert()
            alert.messageText = "Running Script: \(script.name)"
            alert.informativeText = "Please wait..."
            alert.alertStyle = .informational

            let progressIndicator = NSProgressIndicator(
                frame: NSRect(x: 0, y: 0, width: 200, height: 20))
            progressIndicator.style = .bar
            progressIndicator.isIndeterminate = true
            progressIndicator.startAnimation(nil)
            alert.accessoryView = progressIndicator

            // Show alert briefly
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                alert.window.orderOut(nil)
            }
        }

        // Create temporary script file
        let tempDir = FileManager.default.temporaryDirectory
        let tempScriptURL = tempDir.appendingPathComponent(
            "\(script.id.uuidString).sh")

        do {
            try script.content.write(
                to: tempScriptURL, atomically: true, encoding: .utf8)

            // Make executable
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o755], ofItemAtPath: tempScriptURL.path)

            // Run script
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = [tempScriptURL.path]

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? "No output"

            // Clean up
            try? FileManager.default.removeItem(at: tempScriptURL)

            // Show results
            await MainActor.run {
                let resultAlert = NSAlert()
                resultAlert.messageText = "Script Completed: \(script.name)"
                resultAlert.informativeText =
                    "Exit Code: \(process.terminationStatus)"

                if !output.trimmingCharacters(in: .whitespacesAndNewlines)
                    .isEmpty
                {
                    let textView = NSTextView(
                        frame: NSRect(x: 0, y: 0, width: 400, height: 200))
                    textView.string = output
                    textView.isEditable = false
                    textView.font = NSFont.monospacedSystemFont(
                        ofSize: 11, weight: .regular)

                    let scrollView = NSScrollView(
                        frame: NSRect(x: 0, y: 0, width: 400, height: 200))
                    scrollView.documentView = textView
                    scrollView.hasVerticalScroller = true

                    resultAlert.accessoryView = scrollView
                }

                resultAlert.addButton(withTitle: "OK")
                resultAlert.runModal()
            }

        } catch {
            await MainActor.run {
                let errorAlert = NSAlert()
                errorAlert.messageText = "Error Running Script"
                errorAlert.informativeText = error.localizedDescription
                errorAlert.alertStyle = .critical
                errorAlert.runModal()
            }
        }
    }
}
