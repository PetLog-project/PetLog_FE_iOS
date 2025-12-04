//
//  S3UploadService.swift
//  PetLog_iOS
//
//  Created by Dongha Ryu on 12/02/25.
//

import Foundation

// MARK: - S3 Upload Service
class S3UploadService {
    static let shared = S3UploadService()
    
    private init() {}
    
    /// Upload image to S3 and return full S3 URL
    /// - Parameter imageData: PNG image data
    /// - Returns: Full S3 URL (e.g., https://petlog-bucket.s3.ap-northeast-2.amazonaws.com/24/PROFILE_IMAGE/...)
    func uploadImage(_ imageData: Data) async throws -> String {
        // 1. Request presigned URL with POST body (fileType + fileNames[])
        let item = try await getPresignedURL(fileName: generateFileName())
        
        // 2. Upload the bytes to S3 with the provided presigned URL
        try await uploadToS3(presignedUrl: item.presignedUrl, imageData: imageData)
        
        // 3. Construct full S3 URL from presigned URL (extract bucket and path)
        let fullS3URL = constructS3URL(from: item.presignedUrl, filePath: item.filePath)
        print("📸 [S3] Full URL constructed: \(fullS3URL)")
        return fullS3URL
    }
    
    /// Extract bucket and construct full S3 URL from presigned URL
    private func constructS3URL(from presignedUrl: String, filePath: String) -> String {
        // presignedUrl format: https://petlog-bucket.s3.ap-northeast-2.amazonaws.com/24/PROFILE_IMAGE/...?signature=...
        // Extract the base URL without query parameters
        if let baseUrl = presignedUrl.split(separator: "?").first.map(String.init) {
            // baseUrl is already the full URL path, just remove query params
            return baseUrl
        }
        // Fallback: construct from filePath (shouldn't reach here)
        return presignedUrl
    }
    
    private func generateFileName() -> String {
        "\(UUID().uuidString).png"
    }
    
    /// Get presigned URL (new API spec)
    private func getPresignedURL(fileName: String) async throws -> PresignedURLItem {
        guard let url = URL(string: APIConfig.baseURL + "/api/s3/presigned-urls") else {
            throw APIError.invalidURL
        }
        
        let body: [String: Any] = [
            "fileType": "PROFILE_IMAGE",
            "fileNames": [fileName]
        ]
        let json = try JSONSerialization.data(withJSONObject: body)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = json
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let token = UserDefaults.standard.string(forKey: "accessToken")
        print("📸 [S3] Presigned URL request:")
        print("   URL: \(url.absoluteString)")
        print("   Method: POST")
        print("   Body: fileType=PROFILE_IMAGE, fileNames=[\(fileName)]")
        print("   Token: \(token != nil ? "✅ Present" : "❌ Missing")")
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse, http.statusCode < 400 else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            let code = (response as? HTTPURLResponse)?.statusCode ?? 500
            print("❌ [S3] Presigned URL error: statusCode=\(code), message=\(msg)")
            throw APIError.serverError(statusCode: code, message: msg)
        }
        
        struct PresignedURLResponse: Decodable { let code: Int; let message: String; let data: ResponseData }
        struct ResponseData: Decodable { let presignedUrlItems: [PresignedURLItem] }
        
        let decoded = try JSONDecoder().decode(PresignedURLResponse.self, from: data)
        guard let first = decoded.data.presignedUrlItems.first else {
            throw APIError.serverError(statusCode: 500, message: "No presignedUrlItems returned")
        }
        print("📸 [S3] Got presigned URL item: \(first.filePath)")
        return first
    }
    
    /// PUT to S3 signed URL
    private func uploadToS3(presignedUrl: String, imageData: Data) async throws {
        guard let url = URL(string: presignedUrl) else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("image/png", forHTTPHeaderField: "Content-Type")
        request.httpBody = imageData
        
        print("📸 [S3] Uploading bytes to S3 (\(imageData.count) bytes)")
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode < 400 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 500
            print("❌ [S3] Upload error: statusCode=\(code)")
            throw APIError.serverError(statusCode: code, message: "S3 upload failed")
        }
        print("✅ [S3] Upload successful")
    }
}

// MARK: - Models
struct PresignedURLItem: Decodable {
    let filePath: String
    let presignedUrl: String
}
