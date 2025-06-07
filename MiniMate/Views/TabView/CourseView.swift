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
    @Environment(\.colorScheme) private var colorScheme
    
    @ObservedObject var viewManager: ViewManager
    @ObservedObject var authModel: AuthViewModel
    @ObservedObject var locationHandler: LocationHandler
    
    @State var position: MapCameraPosition = .automatic
    @State var isUpperHalf: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            if locationHandler.hasLocationAccess {
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
                                .shadow(radius: 10)
                            
                            Spacer()
                            
                            LocationButton(cameraPosition: $position, isUpperHalf: $isUpperHalf, selectedResult: locationHandler.bindingForSelectedItem(), locationHandler: locationHandler)
                                .shadow(radius: 10)
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
                            .shadow(radius: 10)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            } else {
                HStack(alignment: .center){
                    Spacer()
                    VStack(alignment: .center){
                        Spacer()
                        Text("Please allow location services to use this area of the app.")
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .onAppear(){
            isUpperHalf = false
            locationHandler.mapItems = []
            locationHandler.selectedItem = nil
            position = locationHandler.updateCameraPosition()
        }
    }
    
    var mapView: some View {
        Map(position: $position, selection: locationHandler.bindingForSelectedItem()) {
            withAnimation(){
                ForEach(locationHandler.mapItems, id: \.self) { item in
                    if CourseResolver.matchName(item.name!) {
                        Marker(item.name ?? "Unknown", coordinate: item.placemark.coordinate)
                            .tint(.purple)
                    } else {
                        Marker(item.name ?? "Unknown", coordinate: item.placemark.coordinate)
                            .tint(.green)
                    }
                }
            }
            UserAnnotation()
        }
        .onChange(of: locationHandler.selectedItem) { oldValue, newValue in
            withAnimation {
                position = locationHandler.updateCameraPosition(newValue)
            }
        }
        .mapControls {
            MapCompass()
                .mapControlVisibility(.hidden)
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
                        withAnimation {
                            if result {
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
        .shadow(radius: 10)
    }
    
    var searchResultsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Courses")
                    .font(.title3).fontWeight(.bold)
                    .foregroundStyle(.mainOpp)
                Spacer()
                Button {
                    withAnimation {
                        isUpperHalf = false
                        locationHandler.mapItems = []
                        position = locationHandler.updateCameraPosition()
                    }
                } label: {
                    
                    Text("Cancel")
                        .frame(width: 70, height: 30)
                        .background(colorScheme == .light
                                    ? AnyShapeStyle(Color.white)
                                    : AnyShapeStyle(.ultraThinMaterial))
                        .clipShape(Capsule())
                    
                }
            }
            
            ScrollView {
                VStack(alignment: .leading) {
                    if let userCoord = locationHandler.userLocation {
                        ForEach(locationHandler.mapItems, id: \.self) { mapItem in
                            if mapItem != locationHandler.mapItems[0]{
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
                            .background(colorScheme == .light
                                        ? AnyShapeStyle(Color.white)
                                        : AnyShapeStyle(.ultraThinMaterial))
                            .clipShape(Capsule())
                        
                        
                    }
                }
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Button(action: {
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
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
                            .padding()
                        }
                    }
                    
                    if CourseResolver.matchName(locationHandler.bindingForSelectedItem().wrappedValue?.name ?? "Unknown") {
                        HStack{
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Image("logoOpp")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                    Text("Supported Location")
                                        .font(.headline)
                                }
                                
                                Text((locationHandler.bindingForSelectedItem().wrappedValue?.name ?? "Unknown") + " is a Mini Mate officially supported location, meaning par information and more are available here!")
                                        .font(.callout)
                                
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.purple.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // MARK: - Contact Info
                    if let selected = locationHandler.bindingForSelectedItem().wrappedValue,
                       selected.phoneNumber != nil || selected.url != nil {
                        
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: "phone.fill")
                                    Text("Contact")
                                        .font(.headline)
                                }

                                if let phone = selected.phoneNumber,
                                   let phoneURL = URL(string: "tel://\(phone.filter { $0.isNumber })") {
                                    Link(destination: phoneURL) {
                                        Label("Call \(phone)", systemImage: "phone")
                                            .font(.callout)
                                            .foregroundColor(.white)
                                            .padding(.horizontal)
                                            .padding(.vertical, 6)
                                            .background(Color.green)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }

                                if let url = selected.url {
                                    Link(destination: url) {
                                        Label("Visit Website", systemImage: "safari")
                                            .font(.callout)
                                            .foregroundColor(.white)
                                            .padding(.horizontal)
                                            .padding(.vertical, 6)
                                            .background(Color.blue)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                            Spacer()
                        }
                        .padding()
                        .background(colorScheme == .light
                                    ? AnyShapeStyle(Color.white)
                                    : AnyShapeStyle(.ultraThinMaterial))
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
                    .background(colorScheme == .light
                                ? AnyShapeStyle(Color.white)
                                : AnyShapeStyle(.ultraThinMaterial))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    
                    
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
                        .background(colorScheme == .light
                                    ? AnyShapeStyle(Color.white)
                                    : AnyShapeStyle(.ultraThinMaterial))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // MARK: - Timezone
                    
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
        HStack{
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
            Spacer()
            
            if CourseResolver.matchName(item.name ?? "Unknown Place"){
                Image(systemName: "star.fill")
                    .foregroundStyle(.purple)
            }
        }
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
