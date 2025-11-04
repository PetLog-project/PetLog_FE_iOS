import Foundation

enum Gender: String, Codable, Equatable {
    case male = "MALE"
    case female = "FEMALE"
}

struct Profile: Codable, Equatable {
    let imageUrl: String
    var name: String
    var age: String
    var weight: Double  // Changed from String to Double to match API
    var gender: Gender
    
    // Computed property for display
    var weightString: String {
        return "\(weight)kg"
    }
}

struct Feeding: Codable, Equatable {
    let feedingCycle: Int
    var lastFeedingTime: Date
    let lastCheckerName: String
    var lastMemo: String
}

struct Watering: Codable, Equatable {
    let wateringCycle: Int
    var lastWateringTime: Date
    let lastCheckerName: String
    var lastMemo: String
}

struct Poop: Codable, Equatable {
    var todayPoopCount: Int
    let lastCheckerName: String
    var lastMemo: String
}

struct HomeData: Codable, Equatable {
    var profile: Profile
    var feeding: Feeding
    var watering: Watering
    var poop: Poop
    let joinCode: String
}

struct HomeResponse: Codable, Equatable {
    let statusCode: Int
    let message: String
    let data: HomeData
}

enum HomeModels {
    static let sampleJSONString = """
    {
        "statusCode" : 200,
        "message":"반려동물 정보 조회에 성공했습니다.",
        "data" : {
            "profile" : {
                "imageUrl" : "https://media.wired.com/photos/593261cab8eb31692072f129/3:2/w_2240,c_limit/85120553.jpg",
                "name" : "여름",
                "age" : "2개월",
                "weight" : 1.0,
                "gender" : "FEMALE"
            },
            "feeding" : {
                "feedingCycle" : 6,
                "lastFeedingTime" : "2025-10-31T03:38",
                "lastCheckerName" : "서은",
                "lastMemo" : "밥 조금만 줘야 함"
            },
            "watering" : {
                "wateringCycle" : 6,
                "lastWateringTime" : "2025-10-06T14:30",
                "lastCheckerName" : "예린",
                "lastMemo" : "물 안먹음"
            },
            "poop" : {
                "todayPoopCount" : 2,
                "lastCheckerName" : "동하",
                "lastMemo" : "굿"
            },
            "joinCode" : "ABC123"
        }
    }
    """

    static var sampleData: Data {
        return Data(sampleJSONString.utf8)
    }

    static func loadSample() throws -> HomeData {
        let decoder = JSONDecoder()
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
        return try decoder.decode(HomeData.self, from: sampleData)
    }
}
