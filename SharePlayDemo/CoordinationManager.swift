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
                          self?.enqueuedMovie = nil
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
    func prepareToPlay(_ selectedMovie: MovieData) {
   
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
    
    
    func sessionEnd() {
        groupSession?.leave()
    }
}

