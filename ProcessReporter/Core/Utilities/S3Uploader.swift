//
//  S3Uploader.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/13.
//

import Alamofire
// Import CommonCrypto for HMAC functions
import CommonCrypto
import CryptoKit
import Foundation

struct S3UploaderOptions {
    var bucket: String
    var region: String
    var accessKey: String
    var secretKey: String
    var endpoint: String?
}

class S3Uploader {
    var options: S3UploaderOptions

    var endpoint: String {
        options.endpoint ?? "https://\(bucket).s3.\(region).amazonaws.com"
    }

    var bucket: String {
        options.bucket
    }

    var region: String {
        options.region
    }

    var accessKey: String {
        options.accessKey
    }

    var secretKey: String {
        options.secretKey
    }

    init(
        options: S3UploaderOptions
    ) {
        self.options = options
    }

    func uploadImage(_ imageData: Data, to subPath: String) async throws -> String {
        // Generate MD5 hash of the image data
        let md5Hash = MD5(data: imageData)
        let fileName = "\(md5Hash).\(getFileExtension(from: imageData))"

        // Create the full path for the file
        let path = subPath.hasPrefix("/") ? String(subPath.dropFirst()) : subPath
        let fullPath = path.hasSuffix("/") ? "\(path)\(fileName)" : "\(path)/\(fileName)"

        // Create object key (without leading slash)
        let objectKey = fullPath.hasPrefix("/") ? String(fullPath.dropFirst()) : fullPath

        // Create the URL for the upload
        let host = URL(string: endpoint)?.host
        let uploadURL = "\(endpoint)/\(fullPath)"

        // Content type based on image data
        let contentType = getMimeType(from: imageData)

        // Current date for signing
        let currentDate = ISO8601DateFormatter.s3DateFormatter.string(from: Date())
        let dateStamp = String(currentDate.prefix(8))

        // Create authorization headers for AWS Signature V4
        let headers = createSignatureV4Headers(
            httpMethod: "PUT",
            contentType: contentType,
            date: currentDate,
            dateStamp: dateStamp,
            objectKey: objectKey,
            payloadHash: sha256(data: imageData),
            host: host ?? ""
        )

        // Upload the file
        do {
            _ = try await AF.upload(imageData, to: uploadURL, method: .put, headers: headers)
                .validate()
                .serializingData()
                .value

            // Return the URL of the uploaded file
            return uploadURL
        } catch {
            throw error
        }
    }

    // Create AWS Signature V4 headers
    private func createSignatureV4Headers(
        httpMethod: String,
        contentType: String,
        date: String,
        dateStamp: String,
        objectKey: String,
        payloadHash: String,
        host: String
    ) -> HTTPHeaders {
        // Common AWS headers
        var headers: [String: String] = [
            "Content-Type": contentType,
            "x-amz-date": date,
            "x-amz-content-sha256": payloadHash,
            "x-amz-acl": "public-read",
            "Host": host,
        ]

        // Canonical request
        let canonicalRequest = createCanonicalRequest(
            httpMethod: httpMethod,
            uri: "/\(objectKey)",
            queryParams: "",
            headers: headers,
            payloadHash: payloadHash
        )

        // Create string to sign
        let stringToSign = createStringToSign(
            canonicalRequest: canonicalRequest,
            timestamp: date,
            dateStamp: dateStamp
        )

        // Calculate signature
        let signature = calculateSignature(stringToSign: stringToSign, dateStamp: dateStamp)

        // Create authorization header
        let credentialScope = "\(dateStamp)/\(region)/s3/aws4_request"
        let signedHeaders = headers.keys
            .map { $0.lowercased() }
            .sorted()
            .joined(separator: ";")

        let authorizationHeader =
            "AWS4-HMAC-SHA256 " + "Credential=\(accessKey)/\(credentialScope), "
            + "SignedHeaders=\(signedHeaders), " + "Signature=\(signature)"

        headers["Authorization"] = authorizationHeader

        return HTTPHeaders(headers)
    }

    // Create canonical request for AWS Signature V4
    private func createCanonicalRequest(
        httpMethod: String,
        uri: String,
        queryParams: String,
        headers: [String: String],
        payloadHash: String
    ) -> String {
        let canonicalHeaders =
            headers.keys
            .map { $0.lowercased() }
            .sorted()
            .map { key -> String in
                let headerKey = key.lowercased()
                let headerValue = headers[key] ?? ""
                return "\(headerKey):\(headerValue)"
            }
            .joined(separator: "\n") + "\n"

        let signedHeaders = headers.keys
            .map { $0.lowercased() }
            .sorted()
            .joined(separator: ";")

        return httpMethod + "\n" + uri + "\n" + queryParams + "\n" + canonicalHeaders + "\n"
            + signedHeaders + "\n" + payloadHash
    }

    // Create string to sign for AWS Signature V4
    private func createStringToSign(
        canonicalRequest: String,
        timestamp: String,
        dateStamp: String
    ) -> String {
        let canonicalRequestHash = sha256(string: canonicalRequest)
        let credentialScope = "\(dateStamp)/\(region)/s3/aws4_request"

        return "AWS4-HMAC-SHA256\n" + timestamp + "\n" + credentialScope + "\n"
            + canonicalRequestHash
    }

    // Calculate the signature for AWS Signature V4
    private func calculateSignature(stringToSign: String, dateStamp: String) -> String {
        let kDate = hmacSHA256(key: "AWS4" + secretKey, data: dateStamp)
        let kRegion = hmacSHA256(key: kDate, data: region)
        let kService = hmacSHA256(key: kRegion, data: "s3")
        let kSigning = hmacSHA256(key: kService, data: "aws4_request")
        return hmacSHA256(key: kSigning, data: stringToSign)
    }

    // HMAC-SHA256 hash function
    private func hmacSHA256(key: String, data: String) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), key, key.count, data, data.count, &digest)
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }

    // HMAC-SHA256 hash function with key as Data
    private func hmacSHA256(key: Data, data: String) -> String {
        let dataBytes = data.data(using: .utf8)!
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        key.withUnsafeBytes { keyBytes in
            dataBytes.withUnsafeBytes { dataBytes in
                CCHmac(
                    CCHmacAlgorithm(kCCHmacAlgSHA256), keyBytes.baseAddress, key.count,
                    dataBytes.baseAddress, dataBytes.count, &digest)
            }
        }
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }

    // SHA256 hash of a string
    private func sha256(string: String) -> String {
        let data = string.data(using: .utf8)!
        return sha256(data: data)
    }

    // SHA256 hash of data
    private func sha256(data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    // Helper function to calculate MD5 hash
    private func MD5(data: Data) -> String {
        let hash = Insecure.MD5.hash(data: data)
        return hash.map { String(format: "%02hhx", $0) }.joined()
    }

    // Helper function to determine file extension based on data
    private func getFileExtension(from data: Data) -> String {
        if data.starts(with: [0xFF, 0xD8]) {
            return "jpg"
        } else if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
            return "png"
        } else if data.starts(with: [0x47, 0x49, 0x46]) {
            return "gif"
        } else if data.starts(with: [0x52, 0x49, 0x46, 0x46]) && data.count > 8
            && data[8...11].elementsEqual([0x57, 0x45, 0x42, 0x50])
        {
            return "webp"
        } else {
            return "bin"
        }
    }

    // Helper function to determine MIME type based on data
    private func getMimeType(from data: Data) -> String {
        let ext = getFileExtension(from: data)
        switch ext {
        case "jpg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "webp":
            return "image/webp"
        default:
            return "application/octet-stream"
        }
    }
}

extension S3Uploader {
    public func setOptions(options: S3UploaderOptions) {
        self.options = options
    }
}

// Extension for ISO8601DateFormatter
extension ISO8601DateFormatter {
    static let s3DateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withYear, .withMonth, .withDay, .withTime, .withTimeZone]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}
