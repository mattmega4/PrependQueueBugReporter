//
//  MediaManager.swift
//  PrependQueueBugReporter
//
//  Created by Matthew Howes Singleton on 1/25/19.
//  Copyright © 2019 Matthew Howes Singleton. All rights reserved.
//

import UIKit
import MediaPlayer

class MediaManager: NSObject {

  static let shared = MediaManager()
  var playedSongs = [MPMediaItem]()
  var lockedSongs = [MPMediaItem]()

  func getAllSongs(completion: @escaping (_ songs: [MPMediaItem]?) -> Void) {
    MPMediaLibrary.requestAuthorization { (status) in
      if status == .authorized {
        let query = MPMediaQuery()
        let mediaTypeMusic = MPMediaType.music
        let audioFilter = MPMediaPropertyPredicate(value: mediaTypeMusic.rawValue, forProperty: MPMediaItemPropertyMediaType, comparisonType: MPMediaPredicateComparison.equalTo)
        query.addFilterPredicate(audioFilter)
        let songs = query.items?.filter({ (item) -> Bool in
          //          return item.mediaType.rawValue == 1
          return item.mediaType.rawValue <= MPMediaType.anyAudio.rawValue
        })
        completion(songs)
      } else {
        completion(nil)
      }
    }
  }

  func getSongsWithCurrentArtistFor(item: MPMediaItem) -> MPMediaQuery {
    let artistPredicate = MPMediaPropertyPredicate(value: item.artist, forProperty: MPMediaItemPropertyArtist, comparisonType: .contains)
    let query = MPMediaQuery()
    query.addFilterPredicate(artistPredicate)
    return query
  }

  func removeArtistLockFor(item: MPMediaItem) -> MPMediaQuery {
    let artistPredicate = MPMediaPropertyPredicate(value: item.artist, forProperty: MPMediaItemPropertyArtist)
    let query = MPMediaQuery()
    query.removeFilterPredicate(artistPredicate)
    return query
  }

}
