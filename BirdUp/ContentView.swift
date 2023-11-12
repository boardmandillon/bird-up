//
//  ContentView.swift
//  BirdUp
//
//  Created by Dillon Boardman on 11/11/2023.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            CameraViewController().ignoresSafeArea()
        }.background(Color.black)
    }
}

#Preview {
    ContentView()
}
