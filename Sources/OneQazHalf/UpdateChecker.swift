import AppKit
import Foundation

enum UpdateChecker {

    static let currentVersion = "1.6.0"

    private static let apiURL = URL(string: "https://api.github.com/repos/OmarHung/1qaz-half/releases/latest")!
    private static let releasesURL = URL(string: "https://github.com/OmarHung/1qaz-half/releases/latest")!

    /// 檢查更新，完成後在 main thread 回呼
    static func checkForUpdates(completion: @escaping (_ hasUpdate: Bool, _ latestVersion: String?, _ error: Error?) -> Void) {
        var request = URLRequest(url: apiURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                if let error {
                    completion(false, nil, error)
                    return
                }
                guard let data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let tagName = json["tag_name"] as? String else {
                    completion(false, nil, nil)
                    return
                }
                let latest = tagName.trimmingCharacters(in: CharacterSet(charactersIn: "v"))
                let hasUpdate = isNewer(latest, than: currentVersion)
                completion(hasUpdate, latest, nil)
            }
        }.resume()
    }

    static func openReleasesPage() {
        NSWorkspace.shared.open(releasesURL)
    }

    // MARK: - 版本比較（1.2.0 > 1.1.0）

    private static func isNewer(_ version: String, than current: String) -> Bool {
        let a = version.split(separator: ".").compactMap { Int($0) }
        let b = current.split(separator: ".").compactMap { Int($0) }
        let maxLen = max(a.count, b.count)
        for i in 0..<maxLen {
            let av = i < a.count ? a[i] : 0
            let bv = i < b.count ? b[i] : 0
            if av != bv { return av > bv }
        }
        return false
    }
}
