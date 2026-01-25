import XCTest
@testable import ScriptFlow

final class ScriptFlowTests: XCTestCase {
    func testSampleScriptDecoding() throws {
        guard let url = Bundle(for: Self.self).url(forResource: "SampleScript", withExtension: "json", subdirectory: nil) else {
            throw XCTSkip("SampleScript.json not in test bundle")
        }
        let data = try Data(contentsOf: url)
        let scripts = try JSONDecoder().decode([ScriptDocument].self, from: data)
        XCTAssertFalse(scripts.isEmpty)
    }
}
