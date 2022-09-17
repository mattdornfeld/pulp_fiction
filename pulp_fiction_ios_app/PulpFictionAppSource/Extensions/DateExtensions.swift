//
//  DateExtensions.swift
//  PulpFictionApp
//
//  Created by Matthew Dornfeld on 9/13/22.
//

import Foundation

public extension Date {
    private static let minute: TimeInterval = 60
    private static let hour: TimeInterval = 60 * minute
    private static let day: TimeInterval = 24 * hour
    private static let week: TimeInterval = 7 * day
    private static let dateFormatter: ISO8601DateFormatter = ISO8601DateFormatter()
    
    func addDelta(_ dateComponents: DateComponents) throws -> Date {
        return try Calendar.current.date(byAdding: dateComponents, to: self).getOrThrow()
    }
    
    func addDelta(year: Int? = nil, month: Int? = nil, day: Int? = nil, hour: Int? = nil, minute: Int? = nil, second: Int? = nil) throws -> Date {
        let dateComponents = DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second
        )
        
        return try self.addDelta(dateComponents)
    }
    
    func deltaFrom(_ date: Date) -> TimeInterval {
        self.timeIntervalSinceReferenceDate - date.timeIntervalSinceReferenceDate
    }
    
    static func fromIsoDateString(_ isoDateString: String) throws -> Date {
        return try Date.dateFormatter.date(from:isoDateString).getOrThrow()
    }
    
    func formatAsStringForView() -> String {
        formatAsStringForView(Date.now)
    }
    
    func formatAsStringForView(_ currentDate: Date) -> String {
        let formattedDate =  {() -> String in
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .short
            return dateFormatter.string(from: self)
        }()
        let calendar = Calendar.current
        
        if currentDate.deltaFrom(self) < 2 * Date.minute {
            return calendar
                .dateComponents([.second], from: self, to: currentDate)
                .second
                .map{secondsAgo in "\(secondsAgo) seconds ago"}
                .getOrElse(formattedDate)
        } else if currentDate.deltaFrom(self) < 2 * Date.hour {
            return calendar
                .dateComponents([.minute], from: self, to: currentDate)
                .minute
                .map{minutesAgo in "\(minutesAgo) minutes ago"}
                .getOrElse(formattedDate)
        } else if currentDate.deltaFrom(self) < 2 * Date.day {
            return calendar
                .dateComponents([.hour], from: self, to: currentDate)
                .hour
                .map{hoursAgo in "\(hoursAgo) hours ago"}
                .getOrElse(formattedDate)
        } else if currentDate.deltaFrom(self) < 2 * Date.week {
            return calendar
                .dateComponents([.day], from: self, to: currentDate)
                .day
                .map{daysAgo in "\(daysAgo) days ago"}
                .getOrElse(formattedDate)
        } else {
            return calendar
                .dateComponents([.day], from: self, to: currentDate)
                .day
                .map{daysAgo in "\(daysAgo / 7) weeks ago"}
                .getOrElse(formattedDate)
        }
    }
}
