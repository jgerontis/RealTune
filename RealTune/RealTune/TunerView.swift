import AudioKit
import AudioKitUI
import AudioToolbox
import SwiftUI

struct TunerData {
    var pitch: Double = 0.0
    var centDifference: Double = 0.0
    var amplitude: Float = 0.0
    var noteNameWithSharps = "-"
    var noteNameWithFlats = "-"
    var noteName = "-"
}

class TunerConductor: ObservableObject {
    @StateObject var conductor = TunerConductor()
    let engine = AudioEngine()
    var mic: AudioEngine.InputNode
    var tappableNode1: Fader
    var tappableNodeA: Fader
    var tappableNode2: Fader
    var tappableNodeB: Fader
    var tappableNode3: Fader
    var tappableNodeC: Fader
    var tracker: PitchTap!
    var silence: Fader
    var sharpNames: Bool = true
    
    var noteMatrix = [
        [16.5,17.19,18.29,19.25,20.62,22.0,22.96,24.75,25.85,27.5,29.29,30.94], // A
        [16.32,17.48,18.21,19.38,20.39,21.85,23.31,24.33,26.22,27.39,29.14,31.03], // Bb
        [16.51,17.29,18.52,19.29,20.53,21.61,23.15,24.69,25.77,27.78,29.02,30.87], // B
        [16.35,17.5,18.31,19.62,20.44,21.75,22.89,24.52,26.16,27.3,29.43,30.74], // C
        [16.24,17.32,18.54,19.4,20.79,21.66,23.04,24.25,25.98,27.72,28.93,31.18], // Db
        [16.52,18.35,19.64,20.56,22.02,22.94,24.41,25.7,27.53,29.37,30.65], // D
        [16.19,17.5,18.23,19.45,20.81,21.78,23.33,24.31,25.86,27.22,29.17,31.11], // Eb
        [16.48,17.15,18.54,19.31,20.6,22.04,23.07,24.72,25.75,27.4,28.84,30.9], // E
        [16.37,17.46,18.17,19.64,20.46,21.83,23.35,24.45,26.19,27.28,29.03,30.56], // F
        [16.19,17.34,18.5,19.25,20.81,21.68,23.12,23.12,24.74,25.9,27.75,28.91,30.76], // Gb
        [16.29,17.15,18.38,19.6,20.46,22.05,23.03,24.5,26.09,27.56,29.4,30.62], // G
        [16.22,17.26,18.17,19.47,20.77,21.68,23.36,24.4,25.96,27.64,29.2,31.15], // Ab
        [16.35, 17.32, 18.35, 19.45, 20.6, 21.83, 23.12, 24.5, 25.96, 27.5, 29.14, 30.87] // EQ
    ]

    var noteFrequencies = [16.35, 17.32, 18.35, 19.45, 20.6, 21.83, 23.12, 24.5, 25.96, 27.5, 29.14, 30.87]
   
    
    let noteNamesWithSharps = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
    let noteNamesWithFlats = ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"]

    @Published var data = TunerData()

    func update(_ pitch: AUValue, _ amp: AUValue) {
        data.pitch = Double(pitch)
        data.amplitude = amp

        var frequency = pitch
        while frequency > Float(noteFrequencies[noteFrequencies.count - 1]) {
            frequency /= 2.0
        }
        while frequency < Float(noteFrequencies[0]) {
            frequency *= 2.0
        }

        var minDistance: Float = 10_000.0
        var index = 0

        for possibleIndex in 0 ..< noteFrequencies.count {
            let distance = fabsf(Float(noteFrequencies[possibleIndex]) - frequency)
            if distance < minDistance {
                index = possibleIndex
                minDistance = distance
            }
        }
        let octave = Int(log2f(pitch / frequency))
        data.noteNameWithSharps = "\(noteNamesWithSharps[index])\(octave)"
        data.noteNameWithFlats = "\(noteNamesWithFlats[index])\(octave)"
        if sharpNames {
            data.noteName = data.noteNameWithSharps
        } else {
            data.noteName = data.noteNameWithFlats
        }
        data.centDifference = Double( 1200 * log2( Double(frequency) / Double(noteFrequencies[index]) ) )
        data.centDifference = round(data.centDifference)
    }

    init() {
        guard let input = engine.input else {
            fatalError()
        }

        mic = input
        tappableNode1 = Fader(mic)
        tappableNode2 = Fader(tappableNode1)
        tappableNode3 = Fader(tappableNode2)
        tappableNodeA = Fader(tappableNode3)
        tappableNodeB = Fader(tappableNodeA)
        tappableNodeC = Fader(tappableNodeB)
        silence = Fader(tappableNodeC, gain: 0)
        engine.output = silence

        tracker = PitchTap(mic) { pitch, amp in
            DispatchQueue.main.async {
                if (amp[0] > 0.05) {
                    self.update(pitch[0], amp[0])
                }
            }
        }
    }

    func start() {

        do {
            try engine.start()
            tracker.start()
        } catch let err {
            Log(err)
        }
    }

    func stop() {
        engine.stop()
    }
}

struct TunerView: View {
    @State private var value = 25.0

    @ObservedObject var conductor = TunerConductor()
    
    func displayFlat() {
        conductor.sharpNames = false
    }

    func displaySharp() {
        conductor.sharpNames = true
    }

    func ATune() {
        conductor.noteFrequencies = conductor.noteMatrix[0]
    }
    
    func BbTune() {
        conductor.noteFrequencies = conductor.noteMatrix[1]
    }
    
    func BTune() {
        conductor.noteFrequencies = conductor.noteMatrix[2]
    }
    
    func CTune() {
        conductor.noteFrequencies = conductor.noteMatrix[3]
    }
    
    func DbTune() {
        conductor.noteFrequencies = conductor.noteMatrix[4]
    }
    
    func DTune() {
        conductor.noteFrequencies = conductor.noteMatrix[5]
    }
    
    func EbTune() {
        conductor.noteFrequencies = conductor.noteMatrix[6]
    }
    
    func ETune() {
        conductor.noteFrequencies = conductor.noteMatrix[7]
    }
    
    func FTune() {
        conductor.noteFrequencies = conductor.noteMatrix[8]
    }
    
    func GbTune() {
        conductor.noteFrequencies = conductor.noteMatrix[9]
    }
    
    func GTune() {
        conductor.noteFrequencies = conductor.noteMatrix[10]
    }
    
    func AbTune() {
        conductor.noteFrequencies = conductor.noteMatrix[11]
    }
    
    func EQTune() {
        conductor.noteFrequencies = conductor.noteMatrix[12]
    }

    var body: some View {
        
        ZStack {
            Color.black
                .ignoresSafeArea()
                    
            VStack {
                HStack{
                    Spacer()
                    Menu {
                        Button("Flat Note Names", action: displayFlat)
                        Button("Sharp Note Names", action: displaySharp)
                        
                        Menu("Tuning") {
                            Group {
                                Button("EQ-Tuning", action: EQTune)
                                Button("A-Tuning", action: ATune)
                                Button("Bb-Tuning", action: BbTune)
                                Button("B-Tuning", action: BTune)
                                Button("C-Tuning", action: CTune)
                                Button("Db-Tuning", action: DbTune)
                            }
                            Group {
                                Button("D-Tuning", action: DTune)
                                Button("Eb-Tuning", action: EbTune)
                                Button("E-Tuning", action: ETune)
                                Button("F-Tuning", action: FTune)
                                Button("Gb-Tuning", action: GbTune)
                                Button("G-Tuning", action: GTune)
                                Button("Ab-Tuning", action: AbTune)
                            }
                        }
                        
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    
                }
                
               
                HStack {
                    Spacer()
                    Text("\(conductor.data.pitch, specifier: "%0.1f") Hz").font(.largeTitle)
                        .foregroundColor(.white)
                    Spacer()
                }.padding()
                HStack {
                    Spacer()
                   
                    Text("\(conductor.data.noteName)").font(.largeTitle)
                        .foregroundColor(.white)
                    Spacer()
                }
                
                GaugeView(coveredRadius: 180, maxValue: 100, stepperSplit: 10, value: $conductor.data.centDifference)
                
                NodeOutputView(conductor.tappableNodeA).clipped()

            }.navigationBarTitle(Text("Tuner"))
                .onAppear {
                    self.conductor.start()
                }
                .onDisappear {
                    self.conductor.stop()
                }
            }
        
    }
}


struct TunerView_Previews: PreviewProvider {
    static var previews: some View {
        TunerView()
    }
}
