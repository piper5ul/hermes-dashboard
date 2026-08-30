import AVFoundation
import Foundation
import SwiftUI

@MainActor
@Observable
final class TranscriptMediaPreviewViewModel {
    private let sessionID: String?
    private let reference: TranscriptMediaReference
    private let apiClient: APIClient
    private var didLoad = false
    private var loadGeneration = 0
    private var originalData: Data?
    private var temporaryVideoURL: URL?

    private(set) var previewData: Data?
    private(set) var audioData: Data?
    private(set) var videoFileURL: URL?
    private(set) var documentFileURL: URL?
    private(set) var textContent: String?
    private(set) var originalByteCount: Int?
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var lastError: Error?

    init(
        server: URL,
        sessionID: String?,
        reference: TranscriptMediaReference,
        apiClient: APIClient? = nil
    ) {
        self.sessionID = sessionID
        self.reference = reference
        self.apiClient = apiClient ?? APIClient(baseURL: server)
    }

    var canSaveImageToPhotos: Bool {
        reference.isRasterImageCandidate && previewData != nil
    }

    var canSaveVideoToPhotos: Bool {
        videoFileURL != nil && originalData != nil
    }

    var canSaveMediaToPhotos: Bool {
        canSaveImageToPhotos || canSaveVideoToPhotos
    }

    var canExportMedia: Bool {
        originalData != nil
    }

    func load(force: Bool = false) async {
        guard force || !didLoad else { return }
        loadGeneration += 1
        let generation = loadGeneration
        didLoad = true
        previewData = nil
        audioData = nil
        videoFileURL = nil
        documentFileURL = nil
        textContent = nil
        originalByteCount = nil
        originalData = nil
        removeTemporaryVideoFile()
        removeTemporaryDocumentFile()

        isLoading = true
        errorMessage = nil
        lastError = nil
        defer {
            if loadGeneration == generation {
                isLoading = false
            }
        }

        do {
            let data = try await transcriptMediaData()
            guard !Task.isCancelled, loadGeneration == generation else { return }
            originalData = data
            originalByteCount = data.count

            if reference.isVideoCandidate {
                let fileURL = try writeTemporaryVideoFile(data)
                guard !Task.isCancelled, loadGeneration == generation else {
                    try? FileManager.default.removeItem(at: fileURL)
                    return
                }
                temporaryVideoURL = fileURL
                videoFileURL = fileURL
            } else if reference.isRasterImageCandidate {
                if let downsampled = await ImagePreviewDownsampler.previewDataAsync(
                    from: data,
                    maxPixelSize: ImagePreviewDownsampler.filePreviewMaxPixelSize
                ) {
                    guard !Task.isCancelled, loadGeneration == generation else { return }
                    previewData = downsampled
                } else {
                    guard !Task.isCancelled, loadGeneration == generation else { return }
                    if reference.isExtensionlessRemoteMediaCandidate {
                        if Self.isAudioData(data) {
                            audioData = data
                        } else {
                            let fileURL = try writeTemporaryVideoFile(data)
                            temporaryVideoURL = fileURL
                            videoFileURL = fileURL
                        }
                    } else {
                        errorMessage = String(localized: "Could not decode this image.")
                    }
                }
            } else if reference.isQuickLookPreviewable {
                let fileURL = try writeTemporaryDocumentFile(data)
                guard !Task.isCancelled, loadGeneration == generation else {
                    try? FileManager.default.removeItem(at: fileURL)
                    return
                }
                temporaryDocumentURL = fileURL
                documentFileURL = fileURL
            } else if reference.isTextPreviewable {
                guard !Task.isCancelled, loadGeneration == generation else { return }
                textContent = String(data: data, encoding: .utf8)
                    ?? String(localized: "Could not decode this file as text.")
            } else {
                errorMessage = String(localized: "Preview is not available for this media type.")
            }
        } catch {
            guard !Task.isCancelled, loadGeneration == generation else { return }
            lastError = error
            errorMessage = error.localizedDescription
        }
    }

    func originalImageData() async throws -> Data {
        try await originalMediaData()
    }

    func originalMediaData() async throws -> Data {
        if let originalData {
            return originalData
        }

        let data = try await transcriptMediaData()
        try Task.checkCancellation()
        originalData = data
        originalByteCount = data.count
        return data
    }

    func exportPayload() async throws -> FileExportPayload {
        let data = try await originalMediaData()
        return TranscriptMediaExportSupport.payload(
            for: reference,
            data: data,
            resolvedKind: resolvedExportKind
        )
    }

    private func transcriptMediaData() async throws -> Data {
        switch reference.source {
        case .localPath:
            guard let sessionID = resolvedSessionID else {
                throw TranscriptMediaPreviewError.missingSessionID
            }
            return try await apiClient.transcriptMediaData(for: reference, sessionID: sessionID)
        case .remoteURL:
            return try await apiClient.transcriptMediaData(for: reference, sessionID: resolvedSessionID ?? "")
        }
    }

    private var resolvedSessionID: String? {
        guard let sessionID = sessionID?.trimmingCharacters(in: .whitespacesAndNewlines),
              !sessionID.isEmpty
        else {
            return nil
        }
        return sessionID
    }

    func cleanupTemporaryFiles() {
        loadGeneration += 1
        isLoading = false
        audioData = nil
        textContent = nil
        removeTemporaryVideoFile()
        removeTemporaryDocumentFile()
        videoFileURL = nil
        documentFileURL = nil
    }

    private var temporaryDocumentURL: URL?

    private func writeTemporaryVideoFile(_ data: Data) throws -> URL {
        let ext = reference.videoFileExtension
        let filename = "transcript-media-\(UUID().uuidString).\(ext)"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: [.atomic])
        return url
    }

    private func writeTemporaryDocumentFile(_ data: Data) throws -> URL {
        let filename = reference.displayName
        guard let fileURL = QuickLookExtensions.temporaryFileURL(filename: filename, data: data) else {
            throw TranscriptMediaDocumentError.writeFailed
        }
        return fileURL
    }

    private func removeTemporaryVideoFile() {
        if let temporaryVideoURL {
            try? FileManager.default.removeItem(at: temporaryVideoURL)
        }
        temporaryVideoURL = nil
    }

    private func removeTemporaryDocumentFile() {
        if let temporaryDocumentURL {
            try? FileManager.default.removeItem(at: temporaryDocumentURL)
        }
        temporaryDocumentURL = nil
    }

    private static func isAudioData(_ data: Data) -> Bool {
        (try? AVAudioPlayer(data: data)) != nil
    }

    private var resolvedExportKind: TranscriptMediaResolvedExportKind? {
        if previewData != nil {
            return .image
        }

        if audioData != nil {
            return .audio
        }

        if videoFileURL != nil {
            return .video
        }

        return nil
    }
}

private enum TranscriptMediaPreviewError: LocalizedError {
    case missingSessionID

    var errorDescription: String? {
        String(localized: "Preview is not available for this media without a server session.")
    }
}

private enum TranscriptMediaDocumentError: LocalizedError {
    case writeFailed

    var errorDescription: String? {
        String(localized: "Could not prepare document for preview.")
    }
}

extension TranscriptMediaReference {
    var fileExtension: String {
        switch source {
        case let .remoteURL(url):
            return url.pathExtension.lowercased()
        case let .localPath(path):
            return URL(fileURLWithPath: path).pathExtension.lowercased()
        }
    }

    var isQuickLookPreviewable: Bool {
        QuickLookExtensions.isPreviewable(fileExtension)
    }

    var isTextPreviewable: Bool {
        Self.textExtensions.contains(fileExtension)
    }

    var isMarkdownFile: Bool {
        Self.markdownExtensions.contains(fileExtension)
    }

    fileprivate var videoFileExtension: String {
        let ext = fileExtension
        return ext.isEmpty ? "mp4" : ext
    }

    private static let textExtensions: Set<String> = [
        "css", "html", "js", "json", "log", "md", "markdown", "mdown", "mkd",
        "py", "rb", "rs", "sh", "sql", "swift", "toml", "ts", "txt",
        "xml", "yaml", "yml"
    ]

    private static let markdownExtensions: Set<String> = [
        "md", "markdown", "mdown", "mkd"
    ]
}
