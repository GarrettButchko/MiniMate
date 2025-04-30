//
//  LocationSearch.swift
//  MiniMate
//
//  Created by Garrett Butchko on 1/15/25.
//
import MapKit
import SwiftUI
import Contacts

class LocationHandler: NSObject, ObservableObject, CLLocationManagerDelegate{
    
    @Published var mapItems: [MKMapItem] = []
    @Published var selectedItem: MKMapItem?
    private let manager = CLLocationManager()
    @Published var userLocation: CLLocationCoordinate2D?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func bindingForSelectedItem() -> Binding<MKMapItem?> {
        Binding(
            get: { self.selectedItem },
            set: { self.selectedItem = $0 }
        )
    }
    
    func bindingForSelectedItemID() -> Binding<String?> {
        Binding(
            get: { self.selectedItem?.idString },
            set: { newID in
                self.selectedItem = self.mapItems.first(where: { $0.idString == newID })
            }
        )
    }

    
    func setSelectedItem(_ item: MKMapItem?){
        selectedItem = item
    }
    
    func performSearch(in region: MKCoordinateRegion, completion: @escaping (Bool) -> Void) {
        // Clear previous results
        self.mapItems.removeAll()

        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = "mini golf"
        searchRequest.region = region

        // Filter to mini golf category on iOS 16+
        if #available(iOS 16.0, *) {
            searchRequest.pointOfInterestFilter = MKPointOfInterestFilter(including: [.miniGolf])
        }

        let search = MKLocalSearch(request: searchRequest)
        search.start { (response, error) in
            if let error = error {
                print("Error during search: \(error.localizedDescription)")
                completion(false)
                return
            }

            guard let response = response else {
                print("No response received.")
                completion(false)
                return
            }

            // Update published map items
            self.mapItems = response.mapItems
            completion(true)
        }
    }



    
    func offsetRegionCenter(_ region: MKCoordinateRegion, byLatitudeDelta delta: CLLocationDegrees) -> MKCoordinateRegion {
        var newRegion = region
        newRegion.center.latitude -= delta
        return newRegion
    }
    
    func updateCameraPosition(_ selectedResult: MKMapItem?) -> MapCameraPosition {
        var cameraPosition: MapCameraPosition = .automatic
        
        
        if let selected = selectedResult {
            let original = selected.placemark.coordinate
            
            // Shift coordinate downward slightly to move camera view up
            let adjustedCoordinate = CLLocationCoordinate2D(
                latitude: original.latitude - 0.00042, // tweak this value as needed
                longitude: original.longitude
            )
            
            cameraPosition = .camera(
                MapCamera(
                    centerCoordinate: adjustedCoordinate,
                    distance: 500,
                    heading: 0,
                    pitch: 0
                )
            )
        } else if !mapItems.isEmpty {
            // Zoom out to fit all results into top half
            if let region = computeBoundingRegion(from: mapItems, offsetDownward: true) {
                cameraPosition = .region(region)
            }
        } else if let userLocation = userLocation {
            // Only user location available
            cameraPosition = .region(
                MKCoordinateRegion(center: userLocation,
                                   span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
            )
        }
        
        return cameraPosition
    }
    
    /// Calculates a region that includes all coordinates with a vertical offset for top-half focus.
    private func computeBoundingRegion(from items: [MKMapItem], offsetDownward: Bool = false) -> MKCoordinateRegion? {
        let coords = items.map { $0.placemark.coordinate }

        guard !coords.isEmpty else { return nil }

        let minLat = coords.map { $0.latitude }.min() ?? 0
        let maxLat = coords.map { $0.latitude }.max() ?? 0
        let minLon = coords.map { $0.longitude }.min() ?? 0
        let maxLon = coords.map { $0.longitude }.max() ?? 0

        // Slight padding for better display
        let latPadding = (maxLat - minLat) * 0.3
        let lonPadding = (maxLon - minLon) * 0.3

        let centerLat = ((minLat + maxLat) / 2) - (offsetDownward ? latPadding : 0)
        let centerLon = (minLon + maxLon) / 2

        let span = MKCoordinateSpan(latitudeDelta: (maxLat - minLat) + latPadding,
                                    longitudeDelta: (maxLon - minLon) + lonPadding)

        return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
                                  span: span)
    }
    
    func getPostalAddress(from mapItem: MKMapItem) -> String {
        let placemark = mapItem.placemark
        var components: [String] = []

        if let subThoroughfare = placemark.subThoroughfare { components.append(subThoroughfare) }
        if let thoroughfare = placemark.thoroughfare { components.append(thoroughfare) }
        if let locality = placemark.locality { components.append(locality) }
        if let administrativeArea = placemark.administrativeArea { components.append(administrativeArea) }

        return components.joined(separator: ", ")
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let loc = locations.last {
            userLocation = loc.coordinate
        }
    }
    
    func setClosestValue() {
        guard selectedItem == nil, let userLocation = userLocation else { return }

            let region = MKCoordinateRegion(
                center: userLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )

            performSearch(in: region) { result in
                if result {
                    self.setSelectedItem(self.mapItems.first)
                }
            }
    }
}
