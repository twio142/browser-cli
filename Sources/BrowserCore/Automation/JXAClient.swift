import Foundation
import OSAKit

struct JXAClient {

    /// Executes a JXA script in-process via OSAKit and returns the string result.
    /// Throws `BrowserError.arcReturnedNoValue` if the result is empty or missing.
    /// Propagates NSError from OSAKit for other failures (e.g. permission denied).
    func execute(script source: String) throws -> String {
        guard let language = OSALanguage(forName: "JavaScript") else {
            throw BrowserError.arcReturnedNoValue
        }

        let script = OSAScript(source: source, language: language)
        var errorInfo: NSDictionary?
        let descriptor = script.executeAndReturnError(&errorInfo)

        if let errorInfo = errorInfo {
            let code = (errorInfo[OSAScriptErrorNumber] as? Int) ?? 0
            let message = (errorInfo[OSAScriptErrorMessage] as? String) ?? "OSAScript execution failed"
            throw NSError(domain: "com.browser-cli.OSAKit", code: code,
                          userInfo: [NSLocalizedDescriptionKey: message])
        }

        guard let value = descriptor?.stringValue, !value.isEmpty else {
            throw BrowserError.arcReturnedNoValue
        }

        return value
    }
}
