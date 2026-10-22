import Compression
import Foundation

struct ZIPArchiveEntry: Hashable, Sendable {
    let path: String
    let flags: UInt16
    let compressionMethod: UInt16
    let crc32: UInt32
    let compressedSize: UInt64
    let uncompressedSize: UInt64
    let localHeaderOffset: UInt64

    var filename: String {
        path.replacingOccurrences(of: "\\", with: "/").split(separator: "/").last.map(String.init) ?? path
    }
}

enum ZIPArchiveError: LocalizedError {
    case malformed
    case encryptedEntry(String)
    case unsupportedZIP64
    case unsupportedCompression(String, UInt16)
    case decodedEntryTooLarge(String)
    case checksumMismatch(String)

    var errorDescription: String? {
        switch self {
        case .malformed:
            "L’archive ZIP est incomplète ou mal formée."
        case let .encryptedEntry(name):
            "Le fichier \(name) est chiffré et ne peut pas être importé."
        case .unsupportedZIP64:
            "Cette archive utilise le format ZIP64, qui n’est pas encore pris en charge."
        case let .unsupportedCompression(name, method):
            "Le fichier \(name) utilise une méthode de compression non prise en charge (\(method))."
        case let .decodedEntryTooLarge(name):
            "Le fichier \(name) dépasse la taille maximale d’import prise en charge."
        case let .checksumMismatch(name):
            "La vérification d’intégrité a échoué pour \(name)."
        }
    }
}

final class ZIPArchiveReader {
    private static let endOfCentralDirectorySignature: UInt32 = 0x06054B50
    private static let centralDirectorySignature: UInt32 = 0x02014B50
    private static let localFileHeaderSignature: UInt32 = 0x04034B50
    // The official IDFM GTFS feed has a stop_times.txt entry larger than 1 GB.
    // Keep a bounded limit while allowing that public feed to be imported.
    private static let maximumDecodedEntrySize: UInt64 = 1_536 * 1_024 * 1_024

    private let archiveURL: URL
    private let entries: [ZIPArchiveEntry]

    init(url: URL) throws {
        archiveURL = url
        entries = try Self.readDirectory(from: url)
    }

    func entry(named filename: String) -> ZIPArchiveEntry? {
        entries
            .filter { $0.filename.lowercased() == filename.lowercased() }
            .sorted { lhs, rhs in
                let leftDepth = lhs.path.split(separator: "/").count
                let rightDepth = rhs.path.split(separator: "/").count
                return leftDepth == rightDepth ? lhs.path < rhs.path : leftDepth < rightDepth
            }
            .first
    }

    func data(for entry: ZIPArchiveEntry) throws -> Data {
        guard entry.flags & 0x0001 == 0 else {
            throw ZIPArchiveError.encryptedEntry(entry.filename)
        }
        guard entry.uncompressedSize <= Self.maximumDecodedEntrySize,
              entry.uncompressedSize <= UInt64(Int.max),
              entry.compressedSize <= UInt64(Int.max) else {
            throw ZIPArchiveError.decodedEntryTooLarge(entry.filename)
        }

        let handle = try FileHandle(forReadingFrom: archiveURL)
        defer { try? handle.close() }
        try handle.seek(toOffset: entry.localHeaderOffset)
        let header = try Self.readExactly(30, from: handle)
        guard Self.uint32(header, at: 0) == Self.localFileHeaderSignature else {
            throw ZIPArchiveError.malformed
        }
        guard Self.uint16(header, at: 6) == entry.flags,
              Self.uint16(header, at: 8) == entry.compressionMethod else {
            throw ZIPArchiveError.malformed
        }

        let filenameLength = UInt64(Self.uint16(header, at: 26))
        let extraLength = UInt64(Self.uint16(header, at: 28))
        let dataOffset = entry.localHeaderOffset + 30 + filenameLength + extraLength
        try handle.seek(toOffset: dataOffset)
        let compressed = try Self.readExactly(Int(entry.compressedSize), from: handle)

        let decoded: Data
        switch entry.compressionMethod {
        case 0:
            decoded = compressed
        case 8:
            decoded = try Self.inflate(compressed, expectedSize: Int(entry.uncompressedSize))
        default:
            throw ZIPArchiveError.unsupportedCompression(entry.filename, entry.compressionMethod)
        }

        guard UInt64(decoded.count) == entry.uncompressedSize,
              Self.crc32(decoded) == entry.crc32 else {
            throw ZIPArchiveError.checksumMismatch(entry.filename)
        }
        return decoded
    }

    private static func readDirectory(from url: URL) throws -> [ZIPArchiveEntry] {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        let fileSize = try handle.seekToEnd()
        let tailSize = min(fileSize, 65_557)
        guard tailSize >= 22 else { throw ZIPArchiveError.malformed }
        try handle.seek(toOffset: fileSize - tailSize)
        let tail = try readExactly(Int(tailSize), from: handle)
        guard let endRecordOffset = findEndRecord(in: tail) else { throw ZIPArchiveError.malformed }

        let diskNumber = uint16(tail, at: endRecordOffset + 4)
        let centralDirectoryDisk = uint16(tail, at: endRecordOffset + 6)
        let entriesOnDisk = uint16(tail, at: endRecordOffset + 8)
        let entryCount = uint16(tail, at: endRecordOffset + 10)
        let centralDirectorySize = uint32(tail, at: endRecordOffset + 12)
        let centralDirectoryOffset = uint32(tail, at: endRecordOffset + 16)

        guard diskNumber == 0, centralDirectoryDisk == 0, entriesOnDisk == entryCount else {
            throw ZIPArchiveError.malformed
        }
        guard entryCount != UInt16.max,
              centralDirectorySize != UInt32.max,
              centralDirectoryOffset != UInt32.max else {
            throw ZIPArchiveError.unsupportedZIP64
        }

        let directoryEnd = UInt64(centralDirectoryOffset) + UInt64(centralDirectorySize)
        guard directoryEnd <= fileSize else { throw ZIPArchiveError.malformed }
        try handle.seek(toOffset: UInt64(centralDirectoryOffset))

        var result: [ZIPArchiveEntry] = []
        result.reserveCapacity(Int(entryCount))
        for _ in 0..<entryCount {
            let header = try readExactly(46, from: handle)
            guard uint32(header, at: 0) == centralDirectorySignature else { throw ZIPArchiveError.malformed }

            let flags = uint16(header, at: 8)
            let compressionMethod = uint16(header, at: 10)
            let crc = uint32(header, at: 16)
            let compressedSize = uint32(header, at: 20)
            let uncompressedSize = uint32(header, at: 24)
            let filenameLength = Int(uint16(header, at: 28))
            let extraLength = Int(uint16(header, at: 30))
            let commentLength = Int(uint16(header, at: 32))
            let entryDisk = uint16(header, at: 34)
            let localHeaderOffset = uint32(header, at: 42)

            guard compressedSize != UInt32.max,
                  uncompressedSize != UInt32.max,
                  localHeaderOffset != UInt32.max,
                  entryDisk == 0 else {
                throw ZIPArchiveError.unsupportedZIP64
            }

            let nameData = try readExactly(filenameLength, from: handle)
            let extraData = try readExactly(extraLength, from: handle)
            _ = try readExactly(commentLength, from: handle)
            guard !Self.containsZIP64ExtraField(extraData) else { throw ZIPArchiveError.unsupportedZIP64 }

            guard let path = String(data: nameData, encoding: .utf8) else { throw ZIPArchiveError.malformed }
            result.append(ZIPArchiveEntry(
                path: path,
                flags: flags,
                compressionMethod: compressionMethod,
                crc32: crc,
                compressedSize: UInt64(compressedSize),
                uncompressedSize: UInt64(uncompressedSize),
                localHeaderOffset: UInt64(localHeaderOffset)
            ))
            guard try handle.offset() <= directoryEnd else { throw ZIPArchiveError.malformed }
        }
        return result
    }

    private static func findEndRecord(in data: Data) -> Int? {
        guard data.count >= 22 else { return nil }
        for offset in stride(from: data.count - 22, through: 0, by: -1) {
            guard uint32(data, at: offset) == endOfCentralDirectorySignature else { continue }
            let commentLength = Int(uint16(data, at: offset + 20))
            if offset + 22 + commentLength == data.count { return offset }
        }
        return nil
    }

    private static func containsZIP64ExtraField(_ extra: Data) -> Bool {
        var offset = 0
        while offset + 4 <= extra.count {
            let fieldID = uint16(extra, at: offset)
            let fieldLength = Int(uint16(extra, at: offset + 2))
            if fieldID == 0x0001 { return true }
            offset += 4 + fieldLength
        }
        return false
    }

    private static func inflate(_ source: Data, expectedSize: Int) throws -> Data {
        if expectedSize == 0 { return Data() }
        var output = Data(count: expectedSize)
        let decodedSize = output.withUnsafeMutableBytes { destination in
            source.withUnsafeBytes { sourceBuffer in
                guard let destinationBase = destination.bindMemory(to: UInt8.self).baseAddress,
                      let sourceBase = sourceBuffer.bindMemory(to: UInt8.self).baseAddress else { return 0 }
                return compression_decode_buffer(
                    destinationBase,
                    destination.count,
                    sourceBase,
                    source.count,
                    nil,
                    COMPRESSION_ZLIB
                )
            }
        }
        guard decodedSize == expectedSize else { throw ZIPArchiveError.malformed }
        output.count = decodedSize
        return output
    }

    private static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in data {
            crc = crcTable[Int((crc ^ UInt32(byte)) & 0xFF)] ^ (crc >> 8)
        }
        return crc ^ 0xFFFF_FFFF
    }

    private static let crcTable: [UInt32] = (0..<256).map { index in
        var value = UInt32(index)
        for _ in 0..<8 {
            value = value & 1 == 1 ? (value >> 1) ^ 0xEDB8_8320 : value >> 1
        }
        return value
    }

    private static func readExactly(_ count: Int, from handle: FileHandle) throws -> Data {
        if count == 0 { return Data() }
        guard count >= 0,
              let data = try handle.read(upToCount: count),
              data.count == count else { throw ZIPArchiveError.malformed }
        return data
    }

    private static func uint16(_ data: Data, at offset: Int) -> UInt16 {
        UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
    }

    private static func uint32(_ data: Data, at offset: Int) -> UInt32 {
        UInt32(data[offset])
            | (UInt32(data[offset + 1]) << 8)
            | (UInt32(data[offset + 2]) << 16)
            | (UInt32(data[offset + 3]) << 24)
    }
}
