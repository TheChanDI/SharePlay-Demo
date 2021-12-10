//
//  VideoPlayerVC.swift
//  SharePlayDemo
//
//  Created by ENFINY INNOVATIONS on 10/26/21.
//

import AVKit
import Combine
import GroupActivities


class VideoPlayerVC: UIViewController {
    
    private var player: AVPlayer?
    
//    var rateObserver: NSKeyValueObservation?
    
    var movie: MovieData!
    
    private var subscriptions = Set<AnyCancellable>()
    
    lazy var label: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 19)
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var playerViewController: AVPlayerViewController = {
        let controller = AVPlayerViewController()
        controller.allowsPictureInPicturePlayback = true
//        controller.canStartPictureInPictureAutomaticallyFromInline = true
        return controller
    }()
    
    
    
    // The group session to coordinate playback with.
    private var groupSession: GroupSession<MovieWatchingActivity>? {
        didSet {
            guard let session = groupSession else {
                // Stop playback if a session terminates.
                player?.rate = 0
                return
            }
            player?.playbackCoordinator.coordinateWithSession(session)
            player?.play()
        }
    }
    
    init(movie: MovieData) {
        super.init(nibName: nil, bundle: nil)
        self.movie = movie
        label.text = "\(movie.title)"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "shareplay"), style: .done, target: self, action: #selector(sharePlayTapp))
        
    
        guard let playerView = playerViewController.view else {
            fatalError("Unable to get player view controller view.")
        }
        addChild(playerViewController)
        playerViewController.didMove(toParent: self)
        view.addSubview(playerView)
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        }
        catch {
            // report for an error
            print(error)
        }
        playerView.frame = .init(x: 0, y: 100, width: view.frame.width, height: 200)
        
        let playerItem = AVPlayerItem(url: movie.url)
        player = AVPlayer(playerItem: playerItem)
        playerViewController.player = player
        player

//        player?.play()
        observeSharePlay()
        configureLabel()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        endVC()
    }
    
    func endVC() {
        CoordinationManager.shared.sessionEnd()
  
        player?.replaceCurrentItem(with: nil)
        playerViewController.player = nil
        playerViewController.dismiss(animated: true, completion: nil)
        player = nil
    }
    
    func observeSharePlay() {
        
        // The group session subscriber.
        CoordinationManager.shared.$groupSession
            .receive(on: DispatchQueue.main)
            .assign(to: \.groupSession, on: self)
            .store(in: &subscriptions)
        
    }
    
    func configureLabel() {
        view.addSubview(label)
        label.frame = .init(x: 20, y: 310, width: view.frame.width - 20, height: 30)
    }
    
    
    @objc func sharePlayTapp() {
        //This is for to check wether you are starting the activity or not
        //true means you are the one to start the activity.
        GlobalConstant.isSharablePerform = true
        CoordinationManager.shared.prepareToPlay(movie)
    }
    
    
    func reloadData(data: MovieData) {
        label.text = "\(data.title)"
        let playerItem = AVPlayerItem(url: data.url)
        player = AVPlayer(playerItem: playerItem)
        playerViewController.player = player
        player?.play()
        
    }
}
