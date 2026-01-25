import Foundation

enum SampleScripts {
    static let defaultScripts: [Script] = [
        Script(
            title: "Signal From The Garage",
            lines: [
                ScriptLine(type: .scene, text: "INT. GARAGE - DAY"),
                ScriptLine(type: .action, text: "Dust hangs in the sunlight as a DIY film crew tweaks their lights."),
                ScriptLine(type: .character, text: "BILL"),
                ScriptLine(type: .parenthesis, text: "(smirking)"),
                ScriptLine(type: .dialogue, text: "We need to see all of the facts."),
                ScriptLine(type: .character, text: "TED"),
                ScriptLine(type: .dialogue, text: "We don't have time."),
                ScriptLine(type: .action, text: "A phone buzzes, the shot shaky but alive."),
                ScriptLine(type: .shot, text: "CLOSE ON PHONE"),
                ScriptLine(type: .dialogue, text: "Just roll."),
                ScriptLine(type: .transition, text: "CUT TO:"),
                ScriptLine(type: .scene, text: "EXT. CITY ROOFTOP - NIGHT"),
                ScriptLine(type: .action, text: "Neon hums as the crew captures the skyline."),
                ScriptLine(type: .newAct, text: "ACT II"),
                ScriptLine(type: .action, text: "Momentum builds and the edit takes shape."),
                ScriptLine(type: .endAct, text: "END ACT II")
            ]
        )
    ]
}
