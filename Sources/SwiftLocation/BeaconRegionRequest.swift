//
//  SwiftLocation.swift
//  SwiftLocations
//
// Copyright (c) 2016 Daniele Margutti
// Web:			http://www.danielemargutti.com
// Mail:		me@danielemargutti.com
// Twitter:		@danielemargutti
//
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import CoreBluetooth
import CoreLocation

public typealias LocationHandlerAuthDidChange = ((CLAuthorizationStatus?) -> Void)


/**
 *  This option set define the type of events you can monitor via BeaconManager class's monitor() func
 */
public struct BeaconEvent : OptionSet {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    
    /// Monitor a region cross boundary event (enter and exit from the region)
    public static let RegionBoundary = BeaconEvent(rawValue: 1 << 0)
    /// Monitor beacon ranging
    public static let Ranging = BeaconEvent(rawValue: 1 << 1)
    /// Monitor both region cross boundary and beacon ranging events
    public static let All : BeaconEvent = [.RegionBoundary, .Ranging]
}

/**
 *  This structure define a beacon object
 */
public struct Beacon {
    public var proximityUUID: String
    public var major: CLBeaconMajorValue?
    public var minor: CLBeaconMinorValue?
    
    /**
     Initializa a new beacon to monitor
     
     - parameter proximity: This property contains the identifier that you use to identify your company’s beacons. You typically generate only one UUID for your company’s beacons but can generate more as needed. You generate this value using the uuidgen command-line tool
     - parameter major:     The major property contains a value that can be used to group related sets of beacons. For example, a department store might assign the same major value for all of the beacons on the same floor.
     - parameter minor:     The minor property specifies the individual beacon within a group. For example, for a group of beacons on the same floor of a department store, this value might be assigned to a beacon in a particular section.
     
     - returns: a new beacon structure
     */
    public init(proximity: String, major: CLBeaconMajorValue?, minor: CLBeaconMinorValue?) {
        self.proximityUUID = proximity
        self.major = major
        self.minor = minor
    }
}

public enum RegionState {
    case entered
    case exited
}

public typealias RegionStateDidChange = ((RegionState) -> Void)
public typealias RegionBeaconsRanging = (([CLBeacon]) -> Void)
public typealias RegionMonitorError = ((LocationError) -> Void)

public class BeaconRegionRequest: NSObject, Request {
	
	public var UUID: String
	public var state: RequestState = .idle
	fileprivate(set) var region: CLBeaconRegion
	fileprivate(set) var type: BeaconEvent
	/// Authorization did change
	public var onAuthorizationDidChange: LocationHandlerAuthDidChange?

	public var onStateDidChange: RegionStateDidChange?
	public var onRangingBeacons: RegionBeaconsRanging?
	public var onError: RegionMonitorError?
	public var name: String? = "BeaconRegionRequest"
    
	init?(beacon: Beacon, monitor: BeaconEvent) {
		self.type = monitor
		guard let proximityUUID = Foundation.UUID(uuidString: beacon.proximityUUID) else { // invalid Proximity UUID
			return nil
		}
		self.UUID = proximityUUID.uuidString
		if beacon.major == nil && beacon.minor == nil {
			self.region = CLBeaconRegion(proximityUUID: proximityUUID, identifier: self.UUID)
		} else if beacon.major != nil && beacon.minor != nil {
			self.region = CLBeaconRegion(proximityUUID: proximityUUID, major: beacon.major!, minor: beacon.minor!, identifier: "\(self.UUID)_\(beacon.major)_\(beacon.minor)")
		} else {
			return nil
		}
	}
	
	public func cancel(_ error: LocationError?) {
		_ = Beacons.remove(request: self, error: error)
	}
	
	public func cancel() {
		self.cancel(nil)
	}
	
	public func pause() {
		if Beacons.remove(request: self) == true {
			self.state = .paused
		}
	}
	
	public func start() {
		if self.state.isRunning == false {
			if Beacons.add(request: self) == true {
				self.state = .running
			}
		}
	}

    /// Resume or start request
    public func resume() {
        start()
    }
    
    public func onResume() {}
    
    /// Called when a request is paused
    public func onPause() {}
    
    /// Called when a request is cancelled
    public func onCancel() {}
    
    /// Define what kind of authorization it require
    public var requiredAuth: Authorization = .both
    
    /// Is a background request?
    public var isBackgroundRequest: Bool = true
    
    /// Dispatch an error
    ///
    /// - Parameter error: error
    public func dispatch(error: Error) {}
    
    /// Return `true` if request is on a queue
    public var isInQueue: Bool {
        return Location.isQueued(self)
    }
}
