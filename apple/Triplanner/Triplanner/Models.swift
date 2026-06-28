import Foundation

struct Trip: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var country: String
    var cities: [String]
    var startDate: Date?
    var endDate: Date?
    var accommodation: String
    var myMapsURL: String
    var outbound: FlightInfo
    var inbound: FlightInfo
    var budgetAmount: Double
    var budgetCurrency: String
}

struct FlightInfo: Codable, Equatable {
    var flightNumber: String
    var origin: String
    var destination: String
    var localDeparture: String
    var localArrival: String
}

struct TripMember: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var tintName: String
}

struct ScheduleItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date
    var startTime: String
    var endTime: String
    var title: String
    var note: String
    var placeName: String
    var sourceMapNote: String
    var kind: ScheduleKind
}

enum ScheduleKind: String, Codable, CaseIterable {
    case place = "장소"
    case food = "식사"
    case move = "이동"
    case flight = "항공"
}

struct PlaceCandidate: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var category: String
    var mapURL: String
    var mapNote: String
    var appNote: String
    var isFavorite: Bool
}

struct NoteGroup: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var body: String
    var imageNames: [String]
}

struct ChecklistItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var owner: String
    var isDone: Bool
}

struct ExpenseItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var category: String
    var title: String
    var amount: Double
    var currency: String
    var paidBy: String
    var intendedPayer: String
    var participants: [String]
}

extension Date {
    static func from(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value) ?? Date()
    }

    var dayLabel: String {
        formatted(.dateTime.locale(Locale(identifier: "ko_KR")).month().day().weekday(.abbreviated))
    }
}

