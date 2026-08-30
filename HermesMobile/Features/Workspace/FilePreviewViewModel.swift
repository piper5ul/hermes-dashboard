import Foundation
import UniformTypeIdentifiers

@Observable
final class FilePreviewViewModel {
    private let session: SessionSummary
    private let path: String
    private let apiClient: APIClient

    private(set) var preview: FilePreviewContent?
    private(set) var isLoading = false
    private(set) var isExporting = false
    private(set) var errorMessage: String?
    private(set) var exportErrorMessage: String?
    private(set) var lastError: Error?
    private var exportData: Data?

    init(session: SessionSummary, server: URL, path: String, apiClient: APIClient? = nil) {
        self.session = session
        self.path = path
        self.apiClient = apiClient ?? APIClient(baseURL: server)
    }

    var canExportFile: Bool {
        session.sessionId?.isEmpty == false && !path.isEmpty
    }

    var canSaveImageToPhotos: Bool {
        canExportFile && isRasterImagePath
    }

    @MainActor
    func load() async {
        guard let sessionID = session.sessionId else {
            errorMessage = String(localized: "Session ID is missing.")
            return
        }

        guard !path.isEmpty else {
            errorMessage = String(localized: "File path is missing.")
            return
        }

        isLoading = true
        errorMessage = nil
        exportErrorMessage = nil
        lastError = nil

        do {
            if isRasterImagePath {
                let data = try await apiClient.rawFileData(sessionID: sessionID, path: path)
                exportData = data
                if let previewData = ImagePreviewDownsampler.previewData(
                    from: data,
                    maxPixelSize: ImagePreviewDownsampler.filePreviewMaxPixelSize
                ) {
                    preview = .image(.init(data: previewData, originalByteCount: data.count))
                } else {
                    preview = .unavailable(String(localized: "Could not decode this image."))
                }
            } else if isQuickLookPreviewablePath {
                let data = try await apiClient.rawFileData(sessionID: sessionID, path: path)
                exportData = data
                if let fileURL = QuickLookExtensions.temporaryFileURL(filename: exportFilename, data: data) {
                    preview = .document(fileURL)
                } else {
                    preview = .unavailable(String(localized: "Could not prepare document for preview."))
                }
            } else if isKnownUnsupportedBinaryPath {
                preview = .unavailable(String(localized: "Preview is not available for this file type."))
            } else {
                let file = try await apiClient.file(sessionID: sessionID, path: path)
                exportData = Data((file.content ?? "").utf8)
                preview = .text(file)
            }
        } catch {
            lastError = error
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    @MainActor
    func exportPayload() async throws -> FileExportPayload {
        guard let sessionID = session.sessionId else {
            throw FileExportError.missingSessionID
        }

        guard !path.isEmpty else {
            throw FileExportError.missingPath
        }

        if let exportData {
            return payload(with: exportData)
        }

        isExporting = true
        exportErrorMessage = nil
        lastError = nil
        defer {
            isExporting = false
        }

        do {
            let data = try await apiClient.rawFileData(sessionID: sessionID, path: path)
            exportData = data
            return payload(with: data)
        } catch {
            lastError = error
            exportErrorMessage = error.localizedDescription
            throw error
        }
    }

    private var pathExtension: String {
        URL(fileURLWithPath: path).pathExtension.lowercased()
    }

    private var isRasterImagePath: Bool {
        ["png", "jpg", "jpeg", "gif", "webp", "ico", "bmp"].contains(pathExtension)
    }

    private var isQuickLookPreviewablePath: Bool {
        QuickLookExtensions.isPreviewable(pathExtension)
    }

    private var isKnownUnsupportedBinaryPath: Bool {
        [
            "7z", "a", "aiff", "avi", "bin", "bz2", "class", "db", "dmg",
            "dylib", "exe", "flac", "gz", "jar", "m4a", "mov", "mp3",
            "mp4", "o", "pkg", "pyc", "rar", "sqlite",
            "svg", "tar", "tgz", "wav", "xz", "zip"
        ].contains(pathExtension)
    }

    private func payload(with data: Data) -> FileExportPayload {
        FileExportPayload(
            data: data,
            filename: exportFilename,
            contentType: UTType(filenameExtension: pathExtension) ?? .data,
            isImage: isRasterImagePath,
            isVideo: isVideoPath
        )
    }

    private var isVideoPath: Bool {
        ["m4v", "mov", "mp4"].contains(pathExtension)
    }

    private var exportFilename: String {
        let lastPathComponent = URL(fileURLWithPath: path).lastPathComponent.trimmingCharacters(in: .whitespacesAndNewlines)
        return lastPathComponent.isEmpty ? String(localized: "Hermes File") : lastPathComponent
    }
}

enum FilePreviewContent {
    case text(FileResponse)
    case image(ImageFilePreview)
    case audio(Data)
    case document(URL)
    case unavailable(String)
}

enum QuickLookExtensions {
    static let previewable: Set<String> = [
        "csv", "doc", "docx", "pdf", "ppt", "pptx", "rtf", "xls", "xlsx"
    ]

    static func isPreviewable(_ pathExtension: String) -> Bool {
        previewable.contains(pathExtension.lowercased())
    }

    static func temporaryFileURL(filename: String, data: Data) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("QuickLookPreview", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let fileURL = tempDir.appendingPathComponent(filename)
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            return nil
        }
    }

    static func cleanUpTemporaryFiles() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("QuickLookPreview", isDirectory: true)
        try? FileManager.default.removeItem(at: tempDir)
    }
}

struct ImageFilePreview {
    let data: Data
    let originalByteCount: Int
}

struct FileExportPayload {
    let data: Data
    let filename: String
    let contentType: UTType
    let isImage: Bool
    let isVideo: Bool
}

enum FileExportError: LocalizedError {
    case missingSessionID
    case missingPath

    var errorDescription: String? {
        switch self {
        case .missingSessionID:
            String(localized: "Session ID is missing.")
        case .missingPath:
            String(localized: "File path is missing.")
        }
    }
}
