import Foundation
import Combine

// MARK: - Generic ViewModel Base
class BaseViewModel<T: Codable>: ObservableObject {
    @Published var data: T?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    let decoder: JSONDecoder
    
    init() {
        decoder = JSONDecoder()
        setupDateDecoding()
    }
    
    private func setupDateDecoding() {
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
            
            iso8601Formatter.formatOptions = [.withInternetDateTime]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
            
            let customFormatter = DateFormatter()
            customFormatter.locale = Locale(identifier: "en_US_POSIX")
            customFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
            if let date = customFormatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string: \(dateString)")
        }
    }
    
    // MARK: - Generic Data Loading
    func load<Response: Codable>(
        from data: Data,
        responseType: Response.Type,
        extractData: @escaping (Response) -> T
    ) {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .background).async {
            do {
                let response = try self.decoder.decode(responseType, from: data)
                DispatchQueue.main.async {
                    self.data = extractData(response)
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("Decoding error: \(error)")
                }
            }
        }
    }
    
    // MARK: - Direct Data Loading
    func loadDirect(from data: Data) {
        load(from: data, responseType: T.self) { $0 }
    }
}

// MARK: - Network Service Protocol
protocol NetworkService {
    func fetch<T: Codable>(_ type: T.Type, from data: Data) async throws -> T
}

// MARK: - Default Network Service
class DefaultNetworkService: NetworkService {
    private let decoder: JSONDecoder
    
    init() {
        decoder = JSONDecoder()
        // Add same date decoding strategy as BaseViewModel
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
            
            iso8601Formatter.formatOptions = [.withInternetDateTime]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
            
            let customFormatter = DateFormatter()
            customFormatter.locale = Locale(identifier: "en_US_POSIX")
            customFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
            if let date = customFormatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string: \(dateString)")
        }
    }
    
    func fetch<T: Codable>(_ type: T.Type, from data: Data) async throws -> T {
        return try decoder.decode(type, from: data)
    }
}