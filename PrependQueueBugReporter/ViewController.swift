//
//  ViewController.swift
//  PrependQueueBugReporter
//
//  Created by Matthew Howes Singleton on 1/25/19.
//  Copyright © 2019 Matthew Howes Singleton. All rights reserved.
//

import UIKit
import MediaPlayer

class ViewController: UIViewController {

  @IBOutlet weak var songLabel: UILabel!
  @IBOutlet weak var albumLabel: UILabel!
  @IBOutlet weak var artistLabel: UILabel!
  @IBOutlet weak var artistLockButton: UIButton!
  @IBOutlet weak var prevSongButton: UIButton!
  @IBOutlet weak var playPauseButton: UIButton!
  @IBOutlet weak var nextSongButton: UIButton!

  let mediaPlayer = MPMusicPlayerController.systemMusicPlayer
  var newSongs = [MPMediaItem]()
  var currentSong: MPMediaItem?
  var audioSession = AVAudioSession.sharedInstance()
  var artistIsLocked = false
  var isPlaying = false

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.

    DispatchQueue.main.async {
      self.mediaPlayer.beginGeneratingPlaybackNotifications()
      NotificationCenter.default.addObserver(self, selector: #selector(self.songChanged(_:)), name: NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange, object: self.mediaPlayer)

      MediaManager.shared.getAllSongs { (songs) in
        guard let theSongs = songs else {
          return
        }
        self.mediaPlayer.nowPlayingItem = nil
        self.newSongs.removeAll()
        self.newSongs = theSongs.filter({ (item) -> Bool in
          return !MediaManager.shared.playedSongs.contains(item)
        })

        self.mediaPlayer.setQueue(with: MPMediaItemCollection(items: self.newSongs.shuffled()))
        self.mediaPlayer.shuffleMode = .songs
        self.mediaPlayer.repeatMode = .none
      }
    }

    var canBecomeFirstResponder: Bool { return true }
    self.becomeFirstResponder()
    do {
      try AVAudioSession.sharedInstance().setCategory(.soloAmbient, mode: .default, options: .duckOthers)
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      print("Error setting the AVAudioSession:", error.localizedDescription)
    }

  }

  @objc func songChanged(_ notification: Notification) {
    DispatchQueue.main.async {
       self.getCurrentlyPlayedInfo()
    }
  }

  func getCurrentlyPlayedInfo() {

    if let songInfo = self.mediaPlayer.nowPlayingItem {
      self.songLabel.text = songInfo.title ?? ""
      self.albumLabel.text = songInfo.albumTitle ?? ""
      self.artistLabel.text = songInfo.artist ?? ""

    }
  }

  func tappedLockLogic() {
    if self.artistIsLocked == true {
      self.artistLockButton.setTitle("Artist Locked", for: .normal)
    } else {
      self.artistLockButton.setTitle("Artist Unlocked", for: .normal)
    }
  }

  func clearSongInfo() {
    DispatchQueue.main.async {

      self.songLabel.text = ""
      self.albumLabel.text = ""
      self.artistLabel.text = ""
    }
  }


  @IBAction func prevSongButtonTapped(_ sender: UIButton) {
    mediaPlayer.prepareToPlay(completionHandler: { (error) in
      DispatchQueue.main.async {
        self.mediaPlayer.prepareToPlay()
        self.mediaPlayer.skipToPreviousItem()

      }
      self.getCurrentlyPlayedInfo()
    })

  }

  @IBAction func playPauseButtonTapped(_ sender: UIButton) {
    isPlaying = !isPlaying
    if self.isPlaying {
      self.playPauseButton.setTitle("Pause", for: .normal)
      DispatchQueue.main.async {
        self.mediaPlayer.prepareToPlay()
        self.mediaPlayer.play()
        self.getCurrentlyPlayedInfo()
      }
    } else {
      self.playPauseButton.setTitle("Play", for: .normal)
      DispatchQueue.main.async {
        self.mediaPlayer.pause()
        self.getCurrentlyPlayedInfo()
      }

    }



  }

  @IBAction func nextSongButtonTapped(_ sender: UIButton) {
    mediaPlayer.prepareToPlay(completionHandler: { (error) in
      DispatchQueue.main.async {
        //        guard let nowPlaying = self.mediaPlayer.nowPlayingItem else {
        //          return
        //        }
        //        if self.albumIsLocked && MediaManager.shared.hasPlayedAllSongsFromAlbumFor(song: nowPlaying) || self.artistIsLocked && MediaManager.shared.hasPlayedAllSongsFromArtistFor(song: nowPlaying) || self.genreIsLocked && MediaManager.shared.hasPlayedAllSongsFromGenreFor(song: nowPlaying) {
        //          self.unlockEverythingAndPlay()
        //        } else {
        self.mediaPlayer.prepareToPlay()
        self.mediaPlayer.skipToNextItem()
        //        }

        self.getCurrentlyPlayedInfo()
      }
    })
  }

  @IBAction func artistLockButtonTapped(_ sender: UIButton) {
    DispatchQueue.main.async {
      if let nowPlaying = self.mediaPlayer.nowPlayingItem {
        if sender.isSelected {
          sender.isSelected = false
          self.artistIsLocked = false
          self.artistLockButton.setTitle("Artist Unlocked", for: .normal)
          self.tappedLockLogic()
          let unlockArtist = MediaManager.shared.removeArtistLockFor(item: nowPlaying)
          if var items = unlockArtist.items?.filter({ (item) -> Bool in
            return item.mediaType.rawValue <= MPMediaType.anyAudio.rawValue
          }) {
            items.shuffle()
            let descriptor = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: MPMediaItemCollection(items: self.newSongs.shuffled()))
            self.mediaPlayer.prepend(descriptor)
            self.getCurrentlyPlayedInfo()
          }
          self.tappedLockLogic()

        } else {
          sender.isSelected = true
          self.artistIsLocked = true
          self.artistLockButton.setTitle("Artist Locked", for: .normal)
          let lockArtist = MediaManager.shared.getSongsWithCurrentArtistFor(item: nowPlaying)
          if var items = lockArtist.items {
            items.shuffle()
            let descriptor = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: MPMediaItemCollection(items: items))
            self.mediaPlayer.prepend(descriptor)
          }
          self.tappedLockLogic()
        }
      }
    }
  }
  
}

