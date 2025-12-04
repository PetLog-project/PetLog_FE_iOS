import Foundation
import Combine

class PetDashboardViewModel: BaseViewModel<PetDashboardData> {
    private var lastLoadTime: Date?
    private var currentGroupId: String?
    private let cacheValidityDuration: TimeInterval = 60 // 1 minute cache
    private let apiService = PetLogAPIService.shared
    
    var shouldRefresh: Bool {
        let groupId = UserDefaults.standard.string(forKey: "groupId")
        let isDifferentGroup = groupId != currentGroupId
        
        if isDifferentGroup {
            print("🔄 Group changed, forcing refresh")
            return true
        }
        
        guard let lastLoad = lastLoadTime else { return true }
        return Date().timeIntervalSince(lastLoad) > cacheValidityDuration
    }
    
    // MARK: - Cache Management
    
    /// Clear cached data (e.g., when group changes)
    func clearCache() {
        print("🗑️ Clearing dashboard cache")
        lastLoadTime = nil
        currentGroupId = nil
        data = nil
    }
    
    // MARK: - API Methods
    
    /// Force fetch data from API (bypass cache)
    func fetchData() async {
        print("🔄 fetchData() called - force refreshing from API")
        isLoading = true
        errorMessage = nil
        
        do {
            // Get groupId from UserDefaults
            guard UserDefaults.standard.string(forKey: "groupId") != nil else {
                throw APIError.serverError(statusCode: 404, message: "가입한 그룹이 없습니다.")
            }
            
            // Use getMyGroup() which already handles the new API response structure
            let response = try await apiService.getMyGroup()
            let dashboardData = response.data
            
            await MainActor.run {
                print("✅ API response received, updating data")
                self.data = dashboardData
                self.isLoading = false
                self.lastLoadTime = Date()
                self.currentGroupId = UserDefaults.standard.string(forKey: "groupId")
                // Schedule local reminders based on cycles
                NotificationManager.shared.scheduleActivityReminders(feeding: dashboardData.feeding, watering: dashboardData.watering)
            }
        } catch let error as APIError {
            await MainActor.run {
                // Fall back to sample data for any API error
                print("❌ API Error: \(error.localizedDescription), loading sample data")
                self.loadSample()
            }
        } catch let error as DecodingError {
            await MainActor.run {
                print("🔴 [fetchData] Decoding error: \(error)")
                if case .keyNotFound(let key, let context) = error {
                    print("   Missing key: \(key.stringValue)")
                    print("   Path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                }
                print("❌ Loading sample data as fallback")
                self.loadSample()
            }
        } catch {
            await MainActor.run {
                // On network error, fall back to sample data
                print("❌ Network error: \(error.localizedDescription), loading sample data")
                print("🔴 Error type: \(type(of: error)), Details: \(error)")
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
                // Get groupId from UserDefaults
                guard UserDefaults.standard.string(forKey: "groupId") != nil else {
                    throw APIError.serverError(statusCode: 404, message: "가입한 그룹이 없습니다.")
                }
                
                // Use getMyGroup() which already handles the new API response structure
                let response = try await apiService.getMyGroup()
                let dashboardData = response.data
                
                await MainActor.run {
                    self.data = dashboardData
                    self.isLoading = false
                    self.lastLoadTime = Date()
                    self.currentGroupId = UserDefaults.standard.string(forKey: "groupId")
                    // Schedule local reminders based on cycles
                    NotificationManager.shared.scheduleActivityReminders(feeding: dashboardData.feeding, watering: dashboardData.watering)
                }
            } catch let error as APIError {
                await MainActor.run {
                    // Fall back to sample data for any API error
                    print("API Error: \(error.localizedDescription), loading sample data")
                    self.loadSample()
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
            from: PetDashboardSamples.sampleData,
            responseType: PetDashboardResponse.self,
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
            let response = try decoder.decode(PetDashboardResponse.self, from: PetDashboardSamples.sampleData)
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
            responseType: PetDashboardResponse.self,
            extractData: { $0.data }
        )
    }
}
