import Foundation

func writeStderr(_ message: String) {
    FileHandle.standardError.write(Data((message + "\n").utf8))
}
