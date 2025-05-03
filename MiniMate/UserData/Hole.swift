// Models.swift
import Foundation
import SwiftData
import MapKit
import Contacts

@Model
class Hole: Equatable, Identifiable {
    @Attribute(.unique) var id: String = UUID().uuidString
    var number: Int
    var par: Int = 2
    var strokes: Int

    @Relationship(deleteRule: .nullify)
    var player: Player?

    static func == (lhs: Hole, rhs: Hole) -> Bool {
        lhs.id == rhs.id &&
        lhs.number == rhs.number &&
        lhs.par == rhs.par &&
        lhs.strokes == rhs.strokes
    }

    enum CodingKeys: String, CodingKey {
        case id, number, par, strokes
    }

    init(
          id: String = UUID().uuidString,
          number: Int,
          par: Int,
          strokes: Int = 0
        ) {
          self.id      = id
          self.number  = number
          self.par     = par
          self.strokes = strokes
        }

    func toDTO() -> HoleDTO {
        return HoleDTO(
            id: id,
            number: number,
            par: par,
            strokes: strokes
        )
    }

    static func fromDTO(_ dto: HoleDTO) -> Hole {
        return Hole(
            id: dto.id,
            number: dto.number,
            par: dto.par,
            strokes: dto.strokes
        )
    }
}

struct HoleDTO: Codable {
    var id: String
    var number: Int
    var par: Int
    var strokes: Int
}

extension MKMapItem {
    
    var idString: String {
            "\(placemark.coordinate.latitude)-\(placemark.coordinate.longitude)-\(name ?? "")"
        }
    
    func toDTO() -> MapItemDTO {
        let placemark = self.placemark
        let coordinate = placemark.coordinate
        let address = placemark.postalAddress

        return MapItemDTO(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            name: self.name,
            phoneNumber: self.phoneNumber,
            url: self.url?.absoluteString,
            poiCategory: self.pointOfInterestCategory?.rawValue,
            timeZone: self.timeZone?.identifier,
            street: address?.street,
            city: address?.city,
            state: address?.state,
            postalCode: address?.postalCode,
            country: address?.country
        )
    }
}
