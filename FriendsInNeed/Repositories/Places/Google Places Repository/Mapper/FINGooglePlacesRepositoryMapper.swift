//
//  GooglePlacesRepositoryMapper.swift
//  Help A Paw
//
//  Created by Aleksandar Angelov on 4/30/19.
//  Copyright © 2019 Milen. All rights reserved.
//

import Foundation

struct FINGooglePlacesRepositoryMapper {
    
    // MARK: - Map list of FINPlace-s
    /// Map json dictionary to list of places
    ///
    /// - Parameter jsonDict: json dictionary containing the data
    /// - Returns: optional list of places
    func places(from jsonDict: [String: Any]) -> [FINPlace]? {
        guard let resultsDict = jsonDict["results"] as? [[String: Any]] else {
            return nil
        }
        let places = resultsDict.compactMap({ placeDict -> FINPlace? in
            let geometryDict = placeDict["geometry"] as? [String: Any]
            let locationDict = geometryDict?["location"] as? [String: Any]
            let openingHoursDict = placeDict["opening_hours"] as? [String: Any]
            guard let placeId = placeDict["place_id"] as? String,
                let name = placeDict["name"] as? String,
                let lat = locationDict?["lat"] as? Double,
                let long = locationDict?["lng"] as? Double,
                let iconUrlString = placeDict["icon"] as? String,
                let vicinity = placeDict["vicinity"] as? String,
                let isOpenNow = openingHoursDict?["open_now"] as? Bool,
                let rating = placeDict["rating"] as? Double,
                let totalUsersRating = placeDict["user_ratings_total"] as? Int else {
                    return nil
            }
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            let iconUrl = URL(fileURLWithPath: iconUrlString)
            return FINPlace(placeId: placeId, name: name, location: coordinate, iconUrl: iconUrl, vicinity: vicinity,
                            isOpenNow: isOpenNow, rating: rating, totalUsersRating: totalUsersRating, type: .veterinaryClinic)
        })
        return places
    }
    
    // MARK: - Map FINPlaceDetails
    /// Map json dictionary to list of places
    ///
    /// - Parameter jsonDict: json dictionary containing the data
    /// - Returns: optional place details
    func placeDetails(from jsonDict: [String: Any], placeId: String) -> FINPlaceDetails? {
        guard let resultDict = jsonDict["result"] as? [String: Any],
            let openingHoursDict = resultDict["opening_hours"] as? [String: Any],
            let periodsDict = openingHoursDict["periods"] as? [[String: Any]],
            let phoneNumber = resultDict["international_phone_number"] as? String else {
                return nil
        }
        
        var placeOpeningHours: FINPlaceOpeningHours?
        if periodsDict.count == 1 {
            if let period = periodsDict.first, let open = period["open"] as? [String: Any],
                let day = open["day"] as? Int, let time = open["time"] as? String,
                (day == 0 && time == "0000") {
                placeOpeningHours = FINPlaceOpeningHours()
            }
        } else {
            let sunday = placeDayWorkingHours(from: periodsDict, index: 0)
            let monday = placeDayWorkingHours(from: periodsDict, index: 1)
            let tuesday = placeDayWorkingHours(from: periodsDict, index: 2)
            let wednesday = placeDayWorkingHours(from: periodsDict, index: 3)
            let thursday = placeDayWorkingHours(from: periodsDict, index: 4)
            let friday = placeDayWorkingHours(from: periodsDict, index: 5)
            let saturday = placeDayWorkingHours(from: periodsDict, index: 6)
            placeOpeningHours = FINPlaceOpeningHours(monday: monday, tuesday: tuesday, wednesday: wednesday, thursday: thursday,
                                                     friday: friday, saturday: saturday, sunday: sunday)
        }
        if let placeOpeningHours = placeOpeningHours {
            return FINPlaceDetails(placeId: placeId, phoneNumber: phoneNumber, openingHours: placeOpeningHours)
        } else {
            return nil
        }
    }
    
    
    private func placeDayWorkingHours(from periodsDict: [[String: Any]], index: Int) -> FINPlaceDayWorkingHours? {
        guard (0..<periodsDict.count).contains(index) else {
            return nil
        }
        let periodDict = periodsDict[index]
        guard let closeDict = periodDict["close"] as? [String: Any], let openDict = periodDict["open"] as? [String: Any],
            let closingPlaceHours = placeHours(from: closeDict), let openingPlaceHours = placeHours(from: openDict),
            let day = closeDict["day"] as? Int, let placeDay = FINPlaceDay(rawValue: day) else {
                return nil
        }
        return FINPlaceDayWorkingHours(day: placeDay, opening: openingPlaceHours, closing: closingPlaceHours)
    }
    
    private func placeHours(from openCloseDict: [String: Any]) -> FINPlaceHours? {
        guard let time = openCloseDict["time"] as? String, time.count == 4,
            let hour = Int(time.prefix(2)), let minute = Int(time.suffix(2)) else {
                return nil
        }
        return FINPlaceHours(hour: hour, minute: minute)
    }
    
    // MARK: - Map PlacesRepositoryError
    /// Map status to dictionary to PlacesRepositoryError
    ///
    /// - Parameter jsonDict: json dictionary containing the data
    /// - Returns: optional PlacesRepositoryError
    func placesRepositoryError(from jsonDict: [String: Any]) -> PlacesRepositoryError? {
        guard let status = jsonDict["status"] as? String else {
            return .decoding
        }
        return PlacesRepositoryError(status: status)
    }
    
}
