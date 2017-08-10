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

open class BeaconAdvertiseRequest: NSObject, Request {
	
	
	open var UUID: String
	open var state: RequestState = .idle
	fileprivate(set) var region: CLBeaconRegion
	fileprivate(set) var RSSIPower: NSNumber?
	public var name: String? = "Beacon"
	/// Authorization did change
	open var onAuthorizationDidChange: LocationHandlerAuthDidChange?
	
	init?(name: String, proximityUUID: String, major: CLBeaconMajorValue? = nil, minor: CLBeaconMinorValue? = nil) {
		self.name = name
		guard let proximityUUID = Foundation.UUID(uuidString: proximityUUID) else { // invalid Proximity UUID
			return nil
		}
		self.UUID = proximityUUID.uuidString
		if major == nil && minor == nil {
			self.region = CLBeaconRegion(proximityUUID: proximityUUID, identifier: self.UUID)
		} else if major != nil && minor != nil {
			self.region = CLBeaconRegion(proximityUUID: proximityUUID, major: major!, minor: minor!, identifier: self.UUID)
		} else {
			return nil
		}
	}
	
	open func cancel(_ error: LocationError?) {
		if self.state.isRunning == true {
			_ = Beacons.stopAdvertise(self.name!, error: error)
		}
	}
	
	open func cancel() {
		self.cancel(nil)
	}
	
	open func pause() {
		if self.state.isRunning == true {
			_ = Beacons.stopAdvertise(self.name!, error: nil)
			self.state = .paused
		}
	}
	
	open func start() {
		if self.state.canStart == true {
			self.state = .running
			Beacons.updateBeaconAdvertise()
		}
	}
	
    /// Resume or start request
    open func resume() {
        start()
    }
    
    open func onResume() {}
    
    /// Called when a request is paused
    open func onPause() {}
    
    /// Called when a request is cancelled
    open func onCancel() {}
    
    /// Define what kind of authorization it require
    open var requiredAuth: Authorization = .both
    
    /// Is a background request?
    open var isBackgroundRequest: Bool = true
    
    /// Dispatch an error
    ///
    /// - Parameter error: error
    open func dispatch(error: Error) {}
    
    /// Return `true` if request is on a queue
    open var isInQueue: Bool {
        return Location.isQueued(self)
    }
    
	internal func dataToAdvertise() -> [String:Any] {
		let data: [String:Any] = [
			CBAdvertisementDataLocalNameKey : self.name as ImplicitlyUnwrappedOptional<Any>,
			CBAdvertisementDataManufacturerDataKey : self.region.peripheralData(withMeasuredPower: self.RSSIPower),
			CBAdvertisementDataServiceUUIDsKey : self.UUID]
		return data
	}

}
