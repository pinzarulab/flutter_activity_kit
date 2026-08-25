//
//  LiveActivityWidgetBundle.swift
//  LiveActivityWidget
//
//  Created by Daniel Pinzaru on 25.08.2026.
//

import WidgetKit
import SwiftUI

@main
struct LiveActivityWidgetBundle: WidgetBundle {
    var body: some Widget {
        LiveActivityWidget()
        LiveActivityWidgetControl()
        LiveActivityWidgetLiveActivity()
    }
}
