//
//  MovieWatchingActivity.swift
//  SharePlayDemo
//
//  Created by ENFINY INNOVATIONS on 10/26/21.
//

import Foundation
import GroupActivities

struct MovieData: Hashable, Codable {
    var url: URL
    var title:  String
    var description: String
}


// A group activity to watch a movie together.
struct MovieWatchingActivity: GroupActivity {
    
    static var activityIdentifier: String = "com.unplug.groupActivity"
    
    // The movie to watch.
    let movie: MovieData
    
    
    
    // Metadata that the system displays to participants.
    var metadata: GroupActivityMetadata {
        var metadata = GroupActivityMetadata()
        metadata.type = .watchTogether
        metadata.fallbackURL = movie.url
        metadata.title = movie.title
        return metadata
    }
}
