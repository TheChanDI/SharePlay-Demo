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
    
    private let player = AVPlayer()
    
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
        controller.player = player
        return controller
    }()
    
    // The group session to coordinate playback with.
    private var groupSession: GroupSession<MovieWatchingActivity>? {
        didSet {
            guard let session = groupSession else {
                // Stop playback if a session terminates.
                player.rate = 0
                return
            }
            // Coordinate playback with the active session.
            player.playbackCoordinator.coordinateWithSession(session)
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
        
        observeSharePlay()

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up.fill"), style: .done, target: self, action: #selector(sharePlayTapp))
        
        
        
        guard let playerView = playerViewController.view else {
            fatalError("Unable to get player view controller view.")
        }
        addChild(playerViewController)
        playerViewController.didMove(toParent: self)
        view.addSubview(playerView)
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        }
        catch {
            // report for an error
            print(error)
        }
        playerView.frame = .init(x: 0, y: 100, width: view.frame.width, height: 200)
        
        let playerItem = AVPlayerItem(url: movie.url)
        player.replaceCurrentItem(with: playerItem)
        player.play()
        
        configureLabel()
        
    }
    
    func observeSharePlay() {
        // The movie subscriber.
        CoordinationManager.shared.$enqueuedMovie
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .assign(to: \.movie, on: self)
            .store(in: &subscriptions)
        
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
    
 
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        player.pause()
    
    }
    
    @objc func sharePlayTapp() {
        CoordinationManager.shared.prepareToPlay(movie, navigationController: navigationController!)
    }
    
}
