//
//  ArtistModel.swift
//  ArtistsPresentetion
//
//  Created by Андрей Романюк on 2/18/19.
//  Copyright © 2019 Андрей Романюк. All rights reserved.
//

import Foundation

class Artist: Codable{ // Для хранения данных лучше использовать структуру, т.к это тип значения
    
    private var thumbURL = String()
    private var mbID = String()
    private var facebookProfileURL = String()
    private var imageURL = String()
    private var name = String()
    private var id = String()
    private var trackerCount = Int()
    private var upcomingEventsCount = Int()
    private var url = String()
    
    func getName() -> String {
        return self.name
    }
    func getImageUrl() -> String {
        return self.imageURL
    }
    func getThumbUrl() -> String {
        return self.thumbURL
    }
    func getFacebookPage() -> String? {
        if self.facebookProfileURL.isEmpty{
            return nil
        } else {
            return self.facebookProfileURL
        }
    }
    func getUpcomingEventCount() -> Int {
        return self.upcomingEventsCount
    }
    func getID() -> String {
        return self.id
    }
    
    enum CodingKeys: String, CodingKey {
        case thumbURL = "thumb_url"
        case mbID = "mbid"
        case name = "name"
        case facebookProfileURL = "facebook_page_url"
        case imageURL = "image_url"
        case trackerCount = "tracker_count"
        case upcomingEventsCount = "upcoming_event_count"
        case id = "id"
        case url = "url"
    }
}
