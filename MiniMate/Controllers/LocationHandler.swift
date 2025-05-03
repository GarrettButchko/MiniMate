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
    
    func performSearch(
      in region: MKCoordinateRegion,
      completion: @escaping (Bool) -> Void
    ) {
      // 1️⃣ Build the request
      let request = MKLocalSearch.Request()
      request.naturalLanguageQuery = "mini golf"
      request.region               = region
      if #available(iOS 16.0, *) {
        request.pointOfInterestFilter = .init(including: [.miniGolf])
      }

      // 2️⃣ Start the search
      let search = MKLocalSearch(request: request)
      search.start { response, error in
        if let error = error {
          print("Error during search: \(error.localizedDescription)")
          DispatchQueue.main.async { completion(false) }
          return
        }
        guard let items = response?.mapItems else {
          print("No response or no mapItems.")
          DispatchQueue.main.async { completion(false) }
          return
        }

        // 3️⃣ Optionally sort by distance from userLocation
        let sorted: [MKMapItem]
        if let coord = self.userLocation {
          let userLoc = CLLocation(latitude: coord.latitude,
                                   longitude: coord.longitude)
          sorted = items.sorted { a, b in
            let la = CLLocation(latitude: a.placemark.coordinate.latitude,
                                longitude: a.placemark.coordinate.longitude)
            let lb = CLLocation(latitude: b.placemark.coordinate.latitude,
                                longitude: b.placemark.coordinate.longitude)
            return la.distance(from: userLoc) < lb.distance(from: userLoc)
          }
        } else {
          sorted = items
        }

        // 4️⃣ Publish back on the main thread
        DispatchQueue.main.async {
          self.mapItems = sorted
          completion(true)
        }
      }
    }




    
    func offsetRegionCenter(_ region: MKCoordinateRegion, byLatitudeDelta delta: CLLocationDegrees) -> MKCoordinateRegion {
        var newRegion = region
        newRegion.center.latitude -= delta
        return newRegion
    }
    
    func updateCameraPosition(_ selectedResult: MKMapItem? = nil) -> MapCameraPosition {
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
    
    /// Returns a region centered on `coord` that spans `radiusInMeters * 2` in each direction.
    func makeRegion(
      centeredOn coord: CLLocationCoordinate2D,
      radiusInMeters: CLLocationDistance = 5000
    ) -> MKCoordinateRegion {
      MKCoordinateRegion(
        center: coord,
        latitudinalMeters: radiusInMeters * 2,
        longitudinalMeters: radiusInMeters * 2
      )
    }
}
