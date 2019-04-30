//
//  FINOpeningHours.swift
//  Help A Paw
//
//  Created by Aleksandar Angelov on 4/14/19.
//  Copyright © 2019 Milen. All rights reserved.
//

import Foundation

@objc final class FINPlaceOpeningHours: NSObject {
    
    @objc let monday: FINPlaceDayWorkingHours?
    @objc let tuesday: FINPlaceDayWorkingHours?
    @objc let wednesday: FINPlaceDayWorkingHours?
    @objc let thursday: FINPlaceDayWorkingHours?
    @objc let friday: FINPlaceDayWorkingHours?
    @objc let saturday: FINPlaceDayWorkingHours?
    @objc let sunday: FINPlaceDayWorkingHours?
    
    private var _workingDays: [FINPlaceDayWorkingHours?] {
        return [monday, tuesday, wednesday, thursday, friday,
                saturday, sunday]
    }
    
    @objc var workingDays: NSArray {
        return _workingDays as NSArray
    }
    
    /// Init place opening hours
    ///
    /// - Parameters:
    ///   - monday: monday opening hours
    ///   - tuesday: tuesday opening hours
    ///   - wednesday: wednesday opening hours
    ///   - thursday: thursday opening hours
    ///   - friday: friday opening hours
    ///   - saturday: saturday opening hours
    ///   - sunday: sunday opening hours
    @objc init(monday: FINPlaceDayWorkingHours?, tuesday: FINPlaceDayWorkingHours?, wednesday: FINPlaceDayWorkingHours?,
               thursday: FINPlaceDayWorkingHours?, friday: FINPlaceDayWorkingHours?, saturday: FINPlaceDayWorkingHours?,
               sunday: FINPlaceDayWorkingHours?) {
        self.monday = monday
        self.tuesday = tuesday
        self.wednesday = wednesday
        self.thursday = thursday
        self.friday = friday
        self.saturday = saturday
        self.sunday = sunday
        super.init()
    }
    
    
    /// Init place that is always opened
    @objc convenience override init() {
        self.init(monday: FINPlaceDayWorkingHours(day: .monday, opening: FINPlaceHours.midnight, closing: FINPlaceHours.midnight),
                  tuesday: FINPlaceDayWorkingHours(day: .tuesday, opening: FINPlaceHours.midnight, closing: FINPlaceHours.midnight),
                  wednesday: FINPlaceDayWorkingHours(day: .tuesday, opening: FINPlaceHours.midnight, closing: FINPlaceHours.midnight),
                  thursday: FINPlaceDayWorkingHours(day: .thursday, opening: FINPlaceHours.midnight, closing: FINPlaceHours.midnight),
                  friday: FINPlaceDayWorkingHours(day: .friday, opening: FINPlaceHours.midnight, closing: FINPlaceHours.midnight),
                  saturday: FINPlaceDayWorkingHours(day: .saturday, opening: FINPlaceHours.midnight, closing: FINPlaceHours.midnight),
                  sunday: FINPlaceDayWorkingHours(day: .sunday, opening: FINPlaceHours.midnight, closing: FINPlaceHours.midnight))
    }
    
    @objc var isOpenNow: Bool {
        return isNonstop || _workingDays.contains(where: { $0?.isOpen ?? false })
    }
    
    @objc var isNonstop: Bool {
        return !_workingDays.contains(where: { !($0?.isFullDay ?? false) })
    }
    
}

@objc final class FINPlaceDayWorkingHours: NSObject {
    
    @objc let opening: FINPlaceHours
    @objc let closing: FINPlaceHours
    
    @objc let day: FINPlaceDay
    
    @objc init(day: FINPlaceDay, opening: FINPlaceHours, closing: FINPlaceHours) {
        self.day = day
        self.opening = opening
        self.closing = closing
    }
    
    @objc var isOpen: Bool {
        let date = Date()
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.weekday, .hour, .minute], from: date)
        let (weekday, hour, minute) = (components.weekday!, components.hour!, components.minute!)
        let actualMinutes = (hour * 60) + minute
        let openingMinutes = (opening.hour * 60) + opening.minute
        let closingMinutes = (closing.hour * 60) + closing.minute
        return (weekday - 1) == day.rawValue && (isFullDay || (openingMinutes...closingMinutes).contains(actualMinutes))
    }
    
    @objc var isFullDay: Bool {
        return opening.isMidnight && closing.isMidnight
    }
    
}

@objc enum FINPlaceDay: Int {
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6
    case sunday = 0
}

@objc class FINPlaceHours: NSObject {
    
    @objc let hour: Int
    @objc let minute: Int
    
    @objc init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }
    
    @objc var isMidnight: Bool {
        return hour == 0 && minute == 0
    }
    
    
    /// Initialize midnight place hours
    static var midnight: FINPlaceHours {
        return FINPlaceHours(hour: 0, minute: 0)
    }
    
}
