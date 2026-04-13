import Foundation
import ServiceManagement

enum LoginItemManager {

    static var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            return FileManager.default.fileExists(atPath: launchAgentPath)
        }
    }

    static func setEnabled(_ enabled: Bool) throws {
        if #available(macOS 13.0, *) {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } else {
            if enabled {
                try writeLaunchAgent()
            } else {
                try removeLaunchAgent()
            }
        }
    }

    // MARK: - macOS 12 LaunchAgent fallback

    private static var launchAgentPath: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/Library/LaunchAgents/com.omarhung.1qaz-half.plist"
    }

    private static func writeLaunchAgent() throws {
        guard let execPath = Bundle.main.executablePath else { return }
        let plist: [String: Any] = [
            "Label": "com.omarhung.1qaz-half",
            "ProgramArguments": [execPath],
            "RunAtLoad": true,
            "KeepAlive": false
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: plist,
                                                      format: .xml, options: 0)
        let url = URL(fileURLWithPath: launchAgentPath)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try data.write(to: url)
    }

    private static func removeLaunchAgent() throws {
        try FileManager.default.removeItem(atPath: launchAgentPath)
    }
}
