//
//  CoordinationManager.swift
//  SharePlayDemo
//
//  Created by ENFINY INNOVATIONS on 10/26/21.
//

import Foundation
import Combine
import GroupActivities
import UIKit

class CoordinationManager {
    
    static let shared = CoordinationManager()
    
    private var subscriptions = Set<AnyCancellable>()
    
    // Published values that the player, and other UI items, observe.
    @Published var enqueuedMovie: MovieData?
    @Published var groupSession: GroupSession<MovieWatchingActivity>?
    
    var navigationController: UINavigationController?
    
    private init() {
        
        Task {
            print("I am from init!")
            // Await new sessions to watch movies together.
            for await groupSession in MovieWatchingActivity.sessions() {
                // Set the app's active group session.
                self.groupSession = groupSession
                
                // Remove previous subscriptions.
                subscriptions.removeAll()
                
                // Observe changes to the session state.
                groupSession.$state.sink { [weak self] state in
//                    if case .invalidated = state {
//                        // Set the groupSession to nil to publish
//                        // the invalidated session state.
//                        self?.groupSession = nil
//                        self?.subscriptions.removeAll()
//                    }
                    
                    switch state {
                      case .waiting:
                          // Received after activating activity.
                          debugPrint("session is waiting state: ----->")
                        self?.configureSession(groupSession)
                          break;
                      case .joined:
                          // Never received after calling `session.join()`.
                          debugPrint("session is joining state: ----->")
                          break;
                      case .invalidated(let error):
                          // Never received after calling `session.leave()`, ending the FaceTime call, or after other participating user ends session for everyone.
                          debugPrint("session is invalidated state: ----->")
                          debugPrint(error, "error during session ---------->")
                          self?.groupSession = nil
                          self?.subscriptions.removeAll()
                          break;
  
                      default:
                          break
                      }
                    
                }.store(in: &subscriptions)
                
                groupSession.join()
                
//                configureSession(groupSession)
                
                // Observe when the local user or a remote participant starts an activity.
                groupSession.$activity.sink { [weak self] activity in
                    // Set the movie to enqueue it in the player.
                    self?.enqueuedMovie = activity.movie
                }.store(in: &subscriptions)
            }
        }
    }
    
    
    func configureSession(_ session: GroupSession<MovieWatchingActivity>) {
        
        guard let movie = enqueuedMovie else {return}
        
        let vc = VideoPlayerVC(movie: movie)
        navigationController?.pushViewController(vc, animated: true)
        
    }
    
    // Prepares the app to play the movie.
    func prepareToPlay(_ selectedMovie: MovieData, navigationController: UINavigationController) {
        print("I am prepareToPLay() ------->")
        self.navigationController = navigationController
        // Return early if the app enqueues the movie.
        guard enqueuedMovie != selectedMovie else { return }
        
        if let groupSession = groupSession {
            // If there's an active session, create an activity for the new selection.
            if groupSession.activity.movie != selectedMovie {
                groupSession.activity = MovieWatchingActivity(movie: selectedMovie)
            }
        } else {
            
            Task {
                // Create a new activity for the selected movie.
                let activity = MovieWatchingActivity(movie: selectedMovie)
                
                // Await the result of the preparation call.
                switch await activity.prepareForActivation() {
                    
                case .activationDisabled:
                    // Playback coordination isn't active, or the user prefers to play the
                    // movie apart from the group. Enqueue the movie for local playback only.
                    self.enqueuedMovie = selectedMovie
                    
                case .activationPreferred:
                    // The user prefers to share this activity with the group.
                    // The app enqueues the movie for playback when the activity starts.
                    do {
                        _ = try await activity.activate()
                    } catch {
                        print("Unable to activate the activity: \(error)")
                    }
                    
                case .cancelled:
                    // The user cancels the operation. Do nothing.
                    break
                    
                default: ()
                }
            }
        }
    }
}
