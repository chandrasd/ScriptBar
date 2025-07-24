//
//  SwiftUIMigration.swift
//  scripter
//
//  Created by Chandra Dasari on 7/21/25.
//

import SwiftUI
import UniformTypeIdentifiers


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

    func loadScripts() {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: scriptsDirectory, includingPropertiesForKeys: nil)
            let jsonFiles = fileURLs.filter { $0.pathExtension == "json" }

            scripts = jsonFiles.compactMap { url in
                guard let data = try? Data(contentsOf: url),
                    let script = try? JSONDecoder().decode(Script.self, from: data)
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

    func runScript(_ script: Script) async -> (output: String, exitCode: Int32) {
        return await withCheckedContinuation { continuation in
            Task {
                let tempDir = FileManager.default.temporaryDirectory
                let tempScriptURL = tempDir.appendingPathComponent("\(script.id.uuidString).sh")

                do {
                    try script.content.write(to: tempScriptURL, atomically: true, encoding: .utf8)

                    try FileManager.default.setAttributes(
                        [.posixPermissions: 0o755], ofItemAtPath: tempScriptURL.path)

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

                    try? FileManager.default.removeItem(at: tempScriptURL)

                    continuation.resume(returning: (output, process.terminationStatus))
                } catch {
                    continuation.resume(returning: ("Error: \(error.localizedDescription)", -1))
                }
            }
        }
    }
}

// MARK: - Script Editor View
struct ScriptEditorView: View {
    @Binding var script: Script
    @Environment(\.dismiss) private var dismiss
    let onSave: (Script) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Script Editor")
                .font(.title2)
                .fontWeight(.semibold)
            
            TextField("Script Name", text: $script.name)
                .textFieldStyle(.roundedBorder)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Script Content:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $script.content)
                    .font(.system(.body, design: .monospaced))
                    .border(Color.gray.opacity(0.3))
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save") {
                    onSave(script)
                    dismiss()
                }
                .disabled(script.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                         script.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
    }
}

// MARK: - Script Manager View
struct ScriptManagerView: View {
    @ObservedObject var scriptManager: ScriptManager
    @State private var selectedScript: Script?
    @State private var showingEditor = false
    @State private var editingScript = Script(name: "", content: "#!/bin/bash\n\n# Your script here\necho \"Hello, World!\"")
    
    var body: some View {
        NavigationSplitView {
            VStack {
                List(scriptManager.scripts, selection: $selectedScript) { script in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(script.name)
                                .font(.headline)
                            Text("\(script.content.components(separatedBy: .newlines).count) lines")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                
                HStack {
                    Button("New Script") {
                        editingScript = Script(name: "", content: "#!/bin/bash\n\n# Your script here\necho \"Hello, World!\"")
                        showingEditor = true
                    }
                    
                    Spacer()
                    
                    if selectedScript != nil {
                        Button("Delete") {
                            if let script = selectedScript {
                                scriptManager.deleteScript(script)
                                selectedScript = nil
                            }
                        }
                        .foregroundColor(.red)
                    }
                }
                .padding()
            }
        } detail: {
            if let script = selectedScript {
                ScriptDetailView(script: script, scriptManager: scriptManager)
            } else {
                Text("Select a script to view details")
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showingEditor) {
            ScriptEditorView(script: $editingScript) { newScript in
                scriptManager.saveScript(newScript)
            }
        }
    }
}

// MARK: - Script Detail View
struct ScriptDetailView: View {
    let script: Script
    @ObservedObject var scriptManager: ScriptManager
    @State private var isRunning = false
    @State private var lastOutput = ""
    @State private var lastExitCode: Int32 = 0
    @State private var showingEditor = false
    @State private var editingScript: Script
    
    init(script: Script, scriptManager: ScriptManager) {
        self.script = script
        self.scriptManager = scriptManager
        self._editingScript = State(initialValue: script)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text(script.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Created: \(script.id.uuidString.prefix(8))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Edit") {
                    editingScript = script
                    showingEditor = true
                }
                
                Button(isRunning ? "Running..." : "Run Script") {
                    runScript()
                }
                .disabled(isRunning)
            }
            
            Text("Script Content:")
                .font(.headline)
            
            ScrollView {
                Text(script.content)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .border(Color.gray.opacity(0.3))
            
            if !lastOutput.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Last Output:")
                            .font(.headline)
                        Spacer()
                        Text("Exit Code: \(lastExitCode)")
                            .font(.caption)
                            .foregroundColor(lastExitCode == 0 ? .green : .red)
                    }
                    
                    ScrollView {
                        Text(lastOutput)
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(maxHeight: 200)
                    .border(Color.gray.opacity(0.3))
                }
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingEditor) {
            ScriptEditorView(script: $editingScript) { updatedScript in
                scriptManager.saveScript(updatedScript)
            }
        }
    }
    
    private func runScript() {
        isRunning = true
        Task {
            let result = await scriptManager.runScript(script)
            await MainActor.run {
                lastOutput = result.output
                lastExitCode = result.exitCode
                isRunning = false
            }
        }
    }
}

// MARK: - Menu Bar App
@main
struct ScriptBarApp: App {
    @StateObject private var scriptManager = ScriptManager()
    @State private var showingManager = false
    @State private var showingEditor = false
    @State private var newScript = Script(name: "", content: "#!/bin/bash\n\n# Your script here\necho \"Hello, World!\"")
    
    var body: some Scene {
        MenuBarExtra("ScriptBar", systemImage: "suit.spade.fill") {
            VStack {
                if scriptManager.scripts.isEmpty {
                    Text("No scripts available")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(scriptManager.scripts) { script in
                        Button(script.name) {
                            Task {
                                let _ = await scriptManager.runScript(script)
                            }
                        }
                    }
                }
                
                Divider()
                
                Button("New Script...") {
                    newScript = Script(name: "", content: "#!/bin/bash\n\n# Your script here\necho \"Hello, World!\"")
                    showingEditor = true
                }
                .keyboardShortcut("n")
                
                Button("Manage Scripts...") {
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
        .window(id: "script-manager", isPresented: $showingManager) {
            ScriptManagerView(scriptManager: scriptManager)
                .frame(minWidth: 800, minHeight: 600)
        }
        .sheet(isPresented: $showingEditor) {
            ScriptEditorView(script: $newScript) { script in
                scriptManager.saveScript(script)
            }
        }
    }
}
