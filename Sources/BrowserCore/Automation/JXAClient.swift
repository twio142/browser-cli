import Foundation
import OSAKit

struct JXAClient {
    /// Executes a JXA script in-process via OSAKit and returns the string result.
    /// Throws `BrowserError.pageNotScriptable` if the script returns no value (e.g. internal or PDF page).
    /// Propagates NSError from OSAKit for other failures (e.g. permission denied).
    func execute(script source: String) throws -> String {
        guard let language = OSALanguage(forName: "JavaScript") else {
            throw BrowserError.pageNotScriptable
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

        if let value = descriptor?.stringValue, !value.isEmpty {
            return value
        }

        // Some pages (internal pages, PDFs, browser chrome) return a non-string descriptor.
        // Attempt coercion to unicode text before giving up.
        if let coerced = descriptor?.coerce(toDescriptorType: DescType(typeUnicodeText)),
           let value = coerced.stringValue, !value.isEmpty {
            return value
        }

        throw BrowserError.pageNotScriptable
    }
}
