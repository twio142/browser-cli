import Foundation
import OSAKit

struct JXAClient {
    /// Executes a JXA script in-process via OSAKit and returns the string result.
    /// Throws `BrowserError.pageNotScriptable` if the script returns no value (e.g. internal or PDF page).
    /// Propagates NSError from OSAKit for other failures (e.g. permission denied).
    /// Pass `allowEmpty: true` to return `""` instead of throwing when the result is an empty string.
    func execute(script source: String, allowEmpty: Bool = false) throws -> String {
        let descriptor = try evaluate(script: source)

        if let value = descriptor?.stringValue {
            if !value.isEmpty || allowEmpty {
                return value
            }
        }

        // Some pages (internal pages, PDFs, browser chrome) return a non-string descriptor.
        // Attempt coercion to unicode text before giving up.
        if let coerced = descriptor?.coerce(toDescriptorType: DescType(typeUnicodeText)),
           let value = coerced.stringValue
        {
            if !value.isEmpty || allowEmpty {
                return value
            }
        }

        throw BrowserError.pageNotScriptable
    }

    /// Executes a JXA script for its side effect, discarding the result.
    /// Use for scripting commands that return nothing (e.g. Arc's `select`).
    func run(script source: String) throws {
        _ = try evaluate(script: source)
    }

    private func evaluate(script source: String) throws -> NSAppleEventDescriptor? {
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

        return descriptor
    }
}
