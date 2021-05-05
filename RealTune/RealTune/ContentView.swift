//
//  ContentView.swift
//  RealTune
//
//  Created by Josh Gerontis on 2/15/21.
//


class myOscillator {
    
}


import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack{
                NavigationLink(destination: TunerView()) {
                    Text("Tuner")
                }
                NavigationLink(destination: OscillatorView()) {
                    Text("Keyboard")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
