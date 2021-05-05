import AudioKit
import AudioKitUI
import SwiftUI
import AudioToolbox

struct DynamicOscillatorData {
    var isPlaying: Bool = false
    var frequency: AUValue = 440
    var amplitude: AUValue = 0.1
    var rampDuration: AUValue = 0
    var tuning = 12
    
    var noteMatrix = [
        [132.0,137.5,146.3,154.0,165.0,176.0,183.7,198.0,206.8,220.0,234.3,247.5,264.0,275.0,293.7,308.0,330.0,352.0,366.3,396.0,412.5,440.0,470.8,492.8,528], // A
        [130.52,139.85,145.68,155.0,163.16,174.81,186.46,194.62,209.77,219.1,233.08,248.23,262.22,279.7,291.35,311.16,326.31,349.62,372.93,388.08,419.54,437.03,466.16,498.8,522.08], // Bb
        [132.11,138.29,148.16,154.34,164.22,172.86,185.2,197.55,206.19,222.25,232.12,246.94,262.99,277.81,296.33,308.68,329.66,345.72,370.41,395.1,411.16,444.49,463.01,493.88,528.44], // B
        [130.8,139.96,146.5,156.96,163.5,173.96,183.12,196.2,209.28,218.44,235.44,245.9,261.6,278.6,294.3,313.92,327.0,349.24,366.24,392.4,418.56,435.56,470.88,490.5,523.25], // C
        [129.93,138.59,148.29,155.22,166.31,173.24,184.32,194.03,207.88,221.74,231.45,249.46,260.55,277.18,295.2,311.83,332.62,346.48,370.04,388.05,415.77,443.49,461.5,498.92,519.71,], // Db
        [132.15,146.83,157.11,164.45,176.2,183.54,195.28,205.56,220.25,234.93,245.21,264.29,276.04,293.66,312.75,330.37,352.39,367.08,392.04,411.12,440.49,469.86,488.94,528.59], // D
        [129.5,140.0,145.84,155.56,166.45,174.23,186.67,194.45,206.89,217.78,233.34,248.9,259.79,280.01,292.45,311.12,331.34,350.01,373.34,388.9,415.35,435.57,466.68,497.79,518.01], // Eb
        [131.85,137.21,148.33,154.51,164.81,176.35,184.59,197.77,206.01,219.2,230.73,247.22,263.7,275.23,296.66,309.84,329.62,351.05,370.82,395.54,412.02,440.04,461.47,494.43,527.39], // E
        [130.96,139.69,145.36,157.15,163.7,174.61,186.83,195.56,209.53,218.26,232.23,244.45,261.92,279.38,291.6,314.3,328.27,349.22,371.92,392.87,419.06,436.53,466.21,488.91,523.83], // F
        [129.5,138.75,148.0,154.01,166.5,173.44,185.0,185.0,197.95,207.2,222.0,231.25,246.05,259.0,277.5,296.0,308.95,333.0,347.8,370.0,394.05,416.25,444.0,462.5,493.95,518.0], // Gb
        [130.34,137.2,147.0,156.8,163.66,176.4,184.24,196.0,208.74,220.5,235.2,245.0,261.66,274.4,294.0,313.6,326.34,352.8,367.5,392.0,419.44,439.04,470.4,490.0,521.36], // G
        [129.79,138.09,145.36,155.75,166.13,173.4,186.89,195.2,207.66,221.16,233.62,249.19,259.57,277.23,290.72,311.49,332.26,345.75,373.79,389.36,415.32,444.4,465.16,498.4,519.16], // Ab
        [130.8, 138.6, 146.8, 155.6, 164.8, 174.6, 185, 196, 207.7, 220, 233.1, 246.9, 261.63, 277.2, 293.7, 311.1, 329.6, 349.2, 370, 392, 415.3, 440, 466.2, 493.9, 523.3] // EQ
    ]
    
}

class DynamicOscillatorConductor: ObservableObject, KeyboardDelegate {

    let engine = AudioEngine()

    func noteOn(note: MIDINoteNumber) {
        data.isPlaying = true
        data.frequency = note.midiNoteToFrequency()
        
        if (data.tuning != 12) {
            data.frequency = AUValue(data.noteMatrix[data.tuning][Int(note)-48])
        }
        
    }

    func noteOff(note: MIDINoteNumber) {
        data.isPlaying = false
    }

    @Published var data = DynamicOscillatorData() {
        didSet {
            if data.isPlaying {
                osc.start()
                osc.$frequency.ramp(to: data.frequency, duration: data.rampDuration)
                osc.$amplitude.ramp(to: data.amplitude, duration: data.rampDuration)
            } else {
                osc.amplitude = 0.0
            }
        }
    }

    var osc = DynamicOscillator()

    init() {
        engine.output = osc
    }

    func start() {
        osc.amplitude = 0.2
        do {
            try engine.start()
        } catch let err {
            Log(err)
        }
    }

    func stop() {
        data.isPlaying = false
        osc.stop()
        engine.stop()
    }
        
}


// ======= VIEW OBJECT =====

struct DynamicOscillatorView: View {
    @StateObject var conductor = DynamicOscillatorConductor()

    
    func sine() {
        self.conductor.osc.setWaveTable(waveform: Table(.sine))
    }
    
    func square() {
        self.conductor.osc.setWaveTable(waveform: Table(.square))
    }
    
    func triangle() {
        self.conductor.osc.setWaveTable(waveform: Table(.triangle))
    }
    
    func saw() {
        self.conductor.osc.setWaveTable(waveform: Table(.sawtooth))
    }
    
    func ATune() {
        self.conductor.data.tuning = 0
    }
    
    func BbTune() {
        self.conductor.data.tuning = 1
    }

    func BTune() {
        self.conductor.data.tuning = 2
    }

    func CTune() {
        self.conductor.data.tuning = 3
    }

    func DbTune() {
        self.conductor.data.tuning = 4
    }

    func DTune() {
        self.conductor.data.tuning = 5
    }

    func EbTune() {
        self.conductor.data.tuning = 6
    }

    func ETune() {
        self.conductor.data.tuning = 7
    }

    func FTune() {
        self.conductor.data.tuning = 8
    }

    func GbTune() {
        self.conductor.data.tuning = 9
    }

    func GTune() {
        self.conductor.data.tuning = 10
    }

    func AbTune() {
        self.conductor.data.tuning = 11
    }
    
    func EQTune() {
        self.conductor.data.tuning = 12
    }
    
    

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            VStack {
                Menu {
                    Button("Sine", action: sine)
                    Button("Square", action: square)
                    Button("Triangle", action: triangle)
                    Button("Sawtooth", action: saw)
                    
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
                
                Text("\(conductor.data.frequency, specifier: "%0.1f") Hz").font(.largeTitle)
                    .foregroundColor(.white)
                
                NodeOutputView(conductor.osc)
                KeyboardWidget(delegate: conductor)

            }.navigationBarTitle(Text("Dynamic Oscillator"))
            .onAppear {
                self.conductor.start()
            }
            .onDisappear {
                self.conductor.stop()
            }
        }
    }
}

struct DynamicOscillatorView_Previews: PreviewProvider {
    static var previews: some View {
        DynamicOscillatorView()
    }
}
