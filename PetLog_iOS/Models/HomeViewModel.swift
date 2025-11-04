import Foundation
import Combine

class HomeViewModel: BaseViewModel<HomeData> {
    private var lastLoadTime: Date?
    private let cacheValidityDuration: TimeInterval = 60 // 1 minute cache
    private let apiService = PetLogAPIService.shared
    
    var shouldRefresh: Bool {
        guard let lastLoad = lastLoadTime else { return true }
        return Date().timeIntervalSince(lastLoad) > cacheValidityDuration
    }
    
    // MARK: - API Methods
    
    /// Force fetch data from API (bypass cache)
    func fetchData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.getMyGroup()
            await MainActor.run {
                self.data = response.data
                self.isLoading = false
                self.lastLoadTime = Date()
            }
        } catch let error as APIError {
            await MainActor.run {
                // If 404 (no group), fall back to sample data
                if case .serverError(let statusCode, _) = error, statusCode == 404 {
                    print("No group found (404), loading sample data")
                    self.loadSample()
                } else {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                // On network error, fall back to sample data
                print("Network error, loading sample data")
                self.loadSample()
            }
        }
    }
    
    /// Load data from API
    func loadFromAPI() {
        // Skip if cache is still valid
        guard shouldRefresh else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await apiService.getMyGroup()
                await MainActor.run {
                    self.data = response.data
                    self.isLoading = false
                    self.lastLoadTime = Date()
                }
            } catch let error as APIError {
                await MainActor.run {
                    // If 404 (no group), fall back to sample data
                    if case .serverError(let statusCode, _) = error, statusCode == 404 {
                        print("No group found (404), loading sample data")
                        self.loadSample()
                    } else {
                        self.errorMessage = error.localizedDescription
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    // On network error, fall back to sample data
                    print("Network error, loading sample data")
                    self.loadSample()
                }
            }
        }
    }
    
    // MARK: - Sample Data Methods (for testing/preview)
    
    func loadSample() {
        // Skip if cache is still valid
        guard shouldRefresh else { return }
        
        load(
            from: HomeModels.sampleData,
            responseType: HomeResponse.self,
            extractData: { response in
                var data = response.data
                // Adjust feeding time to show "feeding time" card (6 hours ago exactly)
                data.feeding.lastFeedingTime = Date().addingTimeInterval(-6 * 3600)
                return data
            }
        )
        lastLoadTime = Date()
    }
    
    // Synchronous version for previews
    func loadSampleSync() {
        do {
            let response = try decoder.decode(HomeResponse.self, from: HomeModels.sampleData)
            var data = response.data
            // Adjust feeding time to show "feeding time" card (6 hours ago exactly)
            data.feeding.lastFeedingTime = Date().addingTimeInterval(-6 * 3600)
            self.data = data
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
    
    func load(from data: Data) {
        load(
            from: data,
            responseType: HomeResponse.self,
            extractData: { $0.data }
        )
    }
}
