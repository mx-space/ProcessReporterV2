//
//  S3Uploader.swift
//  ProcessReporter
//
//  Created by Innei on 2025/4/13.
//

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

    // 计算 HMAC-SHA256 的辅助函数
    func hmacSha256(key: Data, message: Data) -> Data {
        var hmac = HMAC<SHA256>(key: SymmetricKey(data: key))
        hmac.update(data: message)
        return Data(hmac.finalize())
    }

    func uploadImage(_ imageData: Data, to path: String) async throws -> String {
        let md5Filename = imageData.md5()
        let objectKey = path + "/\(md5Filename).png"

        try await uploadToS3(
            objectKey: objectKey,
            fileData: imageData,
            contentType: "image/png"
        )

        return "\(path)/\(md5Filename)"
    }

    // 通用的 S3 兼容存储上传函数
    func uploadToS3(
        objectKey: String,
        fileData: Data,
        contentType: String
    ) async throws {
        let service = "s3"
        let xAmzDate = ISO8601DateFormatter.s3DateFormatter.string(from: Date())
        let dateStamp = String(xAmzDate.prefix(8)) // YYYYMMDD

        // 计算哈希化的负载
        let hashedPayload = fileData.sha256()

        // 设置请求头
        let host = URL(string: endpoint)?.host ?? ""
        let contentLength = String(fileData.count)
        let headers = [
            "Host": host,
            "Content-Type": contentType,
            "Content-Length": contentLength,
            "x-amz-date": xAmzDate,
            "x-amz-content-sha256": hashedPayload,
        ]

        // 创建规范请求
        let sortedHeaders = headers.keys.sorted()
        let canonicalHeaders = sortedHeaders.map { key in
            let value = headers[key]!.trimmingCharacters(in: .whitespacesAndNewlines)
            return "\(key.lowercased()):\(value)"
        }.joined(separator: "\n")
        let signedHeaders = sortedHeaders.map { $0.lowercased() }.joined(separator: ";")

        let canonicalRequest = [
            "PUT",
            "/\(bucket)/\(objectKey)",
            "", // 无查询参数
            canonicalHeaders,
            "", // 额外换行符
            signedHeaders,
            hashedPayload,
        ].joined(separator: "\n")

        // 创建待签名字符串
        let algorithm = "AWS4-HMAC-SHA256"
        let credentialScope = "\(dateStamp)/\(region)/\(service)/aws4_request"
        let hashedCanonicalRequest = canonicalRequest.sha256()
        let stringToSign = [
            algorithm,
            xAmzDate,
            credentialScope,
            hashedCanonicalRequest,
        ].joined(separator: "\n")

        // 计算签名
        let kSecret = Data(("AWS4" + secretKey).utf8)
        let kDate = hmacSha256(key: kSecret, message: Data(dateStamp.utf8))
        let kRegion = hmacSha256(key: kDate, message: Data(region.utf8))
        let kService = hmacSha256(key: kRegion, message: Data(service.utf8))
        let kSigning = hmacSha256(key: kService, message: Data("aws4_request".utf8))
        let signature = hmacSha256(key: kSigning, message: Data(stringToSign.utf8)).map { String(format: "%02x", $0) }.joined()

        // 组装 Authorization 头
        let authorization = "\(algorithm) Credential=\(accessKey)/\(credentialScope), SignedHeaders=\(signedHeaders), Signature=\(signature)"

        // 创建并发送 PUT 请求
        let url = URL(string: "\(endpoint)/\(bucket)/\(objectKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = fileData
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.setValue(authorization, forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 200 {
                print("上传成功")
            } else {
                throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "上传失败，状态码：\(httpResponse.statusCode)"])
            }
        }
    }

    // 为了兼容性保留的 R2 上传方法
    func uploadFileToR2(
        accountId: String,
        accessKeyId: String,
        secretAccessKey: String,
        bucketName: String,
        objectKey: String,
        fileData: Data,
        contentType: String
    ) async throws {
        // 保存当前选项
        let originalOptions = options

        // 临时设置 R2 选项
        let r2Options = S3UploaderOptions(
            bucket: bucketName,
            region: "auto", // Cloudflare R2 使用 "auto" 作为区域
            accessKey: accessKeyId,
            secretKey: secretAccessKey,
            endpoint: "https://\(accountId).r2.cloudflarestorage.com"
        )
        options = r2Options

        // 使用通用上传方法
        try await uploadToS3(
            objectKey: objectKey,
            fileData: fileData,
            contentType: contentType
        )

        // 恢复原始选项
        options = originalOptions
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
