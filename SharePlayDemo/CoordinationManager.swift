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
    
    @Published var enqueuedMovie: MovieData?
    
    @Published var groupSession: GroupSession<MovieWatchingActivity>?
    
    
    private init() {
        
        Task {
            
            // Await new sessions to watch movies together.
            
            
            for await groupSession in MovieWatchingActivity.sessions() {
                
                print("group session is: \(groupSession) ----------->")
                // Remove previous subscriptions.
                subscriptions.removeAll()
                
                // Observe changes to the session state.
                groupSession.$state.sink { [weak self] state in
                    switch state {
                    case .waiting:
                        // Received after activating activity.
                        debugPrint("session is waiting state: ----->")
                        
                        break;
                    case .joined:
                        // Never received after calling `session.join()`.
                        debugPrint("session is joining state: ----->")
                        
                        break;
                    case .invalidated(_):
                        // Never received after calling `session.leave()`, ending the FaceTime call, or after other participating user ends session for everyone.
                        
                        self?.groupSession = nil
                        self?.subscriptions.removeAll()
                        //                          self?.enqueuedMovie = nil
                        GlobalConstant.isSharablePerform = false
                        break;
                        
                    default:
                        break
                    }
                    
                }.store(in: &subscriptions)
                
                // Set the app's active group session.
                groupSession.join()
                
                // Observe when the local user or a remote participant starts an activity.
                groupSession.$activity.sink { [weak self] activity in
                    // Set the movie to enqueue it in the player.
                    self?.enqueuedMovie = activity.movie
                }.store(in: &subscriptions)
                self.groupSession = groupSession
                
                
            }
            
        }
        
        
        
    }
    
    
    
    // Prepares the app to play the movie.
    func prepareToPlay(_ selectedMovie: MovieData)  {
        
        // Return early if the app enqueues the movie.
        guard enqueuedMovie != selectedMovie else { return }
        
        Task {
            
            let activity = MovieWatchingActivity(movie: selectedMovie)
            
            do {
                _ = try await activity.activate()
            } catch {
                print("Unable to activate the activity: \(error)")
            }
            
        }
        
        
    }
    
    
    func sessionEnd() {
        groupSession?.leave()
    }
}

