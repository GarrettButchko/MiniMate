//
//  GameView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/6/25.
//

import SwiftUI
import MapKit

// MARK: - CourseView

struct CourseView: View {
    @StateObject var viewManager: ViewManager
    @StateObject var authModel: AuthViewModel
    @StateObject var locationHandler: LocationHandler
    @StateObject var gameModel: GameViewModel
    
    @State var showSheet: Bool = true
    @State var position: MapCameraPosition = .automatic
    @State var isUpperHalf: Bool = false
    @State var showHost: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // MARK: - Map
                mapView
                
                // MARK: - Overlay UI
                VStack {
                    // Top Bar
                    HStack {
                        Text("Course Search")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .padding()
                            .frame(height: 40)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 25))
                        
                        Spacer()
                        
                        LocationButton(cameraPosition: $position, isUpperHalf: $isUpperHalf, selectedResult: locationHandler.bindingForSelectedItem(), locationHandler: locationHandler)
                    }
                    
                    Spacer()
                    
                    // Bottom Panel
                    if !isUpperHalf {
                        searchButton
                    } else {
                        VStack{
                            if locationHandler.selectedItem != nil {
                                resultView
                                    .frame(maxHeight: geometry.size.height * 0.4)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            } else {
                                searchResultsView
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerSize: CGSize(width: 25, height: 25)))
                        .frame(height: geometry.size.height * 0.4)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .onAppear {
                
            }
        }
    }
    
    var mapView: some View {
        Map(position: $position, selection: locationHandler.bindingForSelectedItem()) {
            ForEach(locationHandler.mapItems, id: \.self) { item in
                Marker(item.name ?? "Unknown", coordinate: item.placemark.coordinate)
                    .tint(.green)
            }
            UserAnnotation()
        }
        .onChange(of: locationHandler.selectedItem) { oldValue, newValue in
            withAnimation {
                position = locationHandler.updateCameraPosition(newValue)
            }
        }
    }
    
    var searchButton: some View {
        Button {
            withAnimation {
                isUpperHalf.toggle()
                if let userLocation = locationHandler.userLocation {
                    let upwardOffset: CLLocationDegrees = 0.03 // how much higher to shift (tweak if needed)
                    let offsetLatitude = userLocation.latitude + upwardOffset

                    let adjustedCoordinate = CLLocationCoordinate2D(
                        latitude: offsetLatitude,
                        longitude: userLocation.longitude
                    )

                    let region = MKCoordinateRegion(
                        center: adjustedCoordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                    )

                    locationHandler.performSearch(in: region) { result in
                        if result {
                            withAnimation {
                                position = locationHandler.updateCameraPosition(nil)
                            }
                        }
                    }
                }

            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.blue)
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.white)
                    Text("Search for Nearby Courses")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
        }
        .frame(height: 50)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    var searchResultsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Courses")
                    .font(.title3).fontWeight(.bold)
                    .foregroundStyle(.mainOpp)
                Spacer()
                Button {
                    locationHandler.mapItems = []
                    withAnimation {
                        isUpperHalf = false
                    }
                } label: {
                    Text("Cancel")
                        .frame(width: 70, height: 30)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
            }
            
            ScrollView {
                VStack(alignment: .leading) {
                    if let userCoord = locationHandler.userLocation {
                        let userLoc = CLLocation(latitude: userCoord.latitude, longitude: userCoord.longitude)
                        let sortedItems = locationHandler.mapItems.sorted {
                            let loc1 = CLLocation(latitude: $0.placemark.coordinate.latitude,
                                                  longitude: $0.placemark.coordinate.longitude)
                            let loc2 = CLLocation(latitude: $1.placemark.coordinate.latitude,
                                                  longitude: $1.placemark.coordinate.longitude)
                            return loc1.distance(from: userLoc) < loc2.distance(from: userLoc)
                        }
                        
                        ForEach(sortedItems, id: \.self) { mapItem in
                            if mapItem != sortedItems[0]{
                                Divider()
                            }
                            SearchResultRow(item: mapItem, userLocation: userCoord)
                                .onTapGesture {
                                    withAnimation(){
                                        locationHandler.setSelectedItem(mapItem)
                                        position = locationHandler.updateCameraPosition(locationHandler.bindingForSelectedItem().wrappedValue)
                                    }
                                }
                        }
                    } else {
                        Text("Fetching location...")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
    }
    
    var resultView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(locationHandler.selectedItem?.name ?? "")
                    .font(.title3).fontWeight(.bold)
                    .foregroundStyle(.mainOpp)
                Spacer()
                Button {
                    withAnimation {
                        locationHandler.setSelectedItem(nil)
                    }
                } label: {
                    ZStack {
                        Text("Back")
                            .frame(width: 70, height: 30)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                }
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    
                    Button {
                        showHost = true
                        gameModel.createGame(online: false, startingLoc: locationHandler.selectedItem)
                    } label: {
                        HStack {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                            Text("Host/Start Game Here")
                                .fontWeight(.semibold)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(RoundedRectangle(cornerRadius: 15).fill().foregroundStyle(.purple))
                        .foregroundColor(.white)
                    }
                    .sheet(isPresented: $showHost) {
                        HostView(showHost: $showHost, authModel: authModel, viewManager: viewManager, locationHandler: locationHandler, gameModel: gameModel, showLocationPicker: true)
                            .presentationDetents([.large])
                    }


                    // MARK: - Contact Info
                    if let selected = locationHandler.bindingForSelectedItem().wrappedValue,
                       selected.phoneNumber != nil || selected.url != nil {
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Image(systemName: "phone.fill")
                                    Text("Contact")
                                        .font(.headline)
                                }

                                if let phone = selected.phoneNumber {
                                    Text("Phone: \(phone)")
                                }

                                if let url = selected.url {
                                    Link("Website", destination: url)
                                }
                            }
                            Spacer()
                        }
                        .font(.callout)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // MARK: - Location Info
                    HStack{
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Image(systemName: "mappin")
                                Text("Location")
                                    .font(.headline)
                            }
                            if let name = locationHandler.bindingForSelectedItem().wrappedValue?.name {
                                Text(name)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            if let selectedResult = locationHandler.bindingForSelectedItem().wrappedValue {
                                Text(locationHandler.getPostalAddress(from: selectedResult))
                                    .font(.callout)
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // MARK: - Timezone
                    if let timeZone = locationHandler.bindingForSelectedItem().wrappedValue?.timeZone {
                        HStack {
                            VStack(alignment: .leading, spacing: 4){
                                HStack(spacing: 8) {
                                    Image(systemName: "clock")
                                    Text("Timezone")
                                        .font(.headline)
                                }
                                Text(timeZone.identifier)
                                    .font(.callout)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // MARK: - Directions Button
                    
                    
                    Button(action: {
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking]
                        locationHandler.bindingForSelectedItem().wrappedValue?.openInMaps(launchOptions: launchOptions)
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.blue)
                            VStack {
                                Image(systemName: "arrow.turn.up.right")
                                    .foregroundColor(.white)
                                Text("Get Directions")
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                    .padding(.top)
                    .frame(height: 60)

                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
    }
    
    
    
}

// MARK: - LocationButton

struct LocationButton: View {
    @Binding var cameraPosition: MapCameraPosition
    @Binding var isUpperHalf: Bool
    @Binding var selectedResult: MKMapItem?
    @ObservedObject var locationHandler: LocationHandler

    var body: some View {
        Button(action: {
            withAnimation {
                cameraPosition = locationHandler.updateCameraPosition(selectedResult)
            }
        }) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 40, height: 40)
                Image(systemName: "location.fill")
                    .resizable()
                    .foregroundColor(.primary)
                    .frame(width: 20, height: 20)
            }
        }
    }

    
}

// MARK: - SearchResultRow

struct SearchResultRow: View {
    let item: MKMapItem
    let userLocation: CLLocationCoordinate2D

    var body: some View {
        VStack(alignment: .leading) {
            Text(item.name ?? "Unknown Place")
                .font(.headline)

            let offsetLat = userLocation.latitude - 0.015
            let distanceInMiles = CLLocation(latitude: offsetLat, longitude: userLocation.longitude)
                .distance(from: CLLocation(latitude: item.placemark.coordinate.latitude,
                                           longitude: item.placemark.coordinate.longitude)) / 1609.34

            Text("\(String(format: "%.1f", distanceInMiles)) mi - \(getPostalAddress(from: item))")
                .font(.subheadline)
        }
        .frame(height: 50)
    }

    private func getPostalAddress(from mapItem: MKMapItem) -> String {
        let placemark = mapItem.placemark
        var components: [String] = []

        if let subThoroughfare = placemark.subThoroughfare { components.append(subThoroughfare) }
        if let thoroughfare = placemark.thoroughfare { components.append(thoroughfare) }
        if let locality = placemark.locality { components.append(locality) }
        if let administrativeArea = placemark.administrativeArea { components.append(administrativeArea) }

        return components.joined(separator: ", ")
    }
}
