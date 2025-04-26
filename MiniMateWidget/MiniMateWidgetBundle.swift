//
//  MiniMateWidgetBundle.swift
//  MiniMateWidget
//
//  Created by Garrett Butchko on 4/25/25.
//

import WidgetKit
import SwiftUI

@main
struct MiniMateWidgetBundle: WidgetBundle {
    var body: some Widget {
        MiniMateWidget()
        MiniMateWidgetControl()
        MiniMateWidgetLiveActivity()
    }
}
