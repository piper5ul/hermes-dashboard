import XCTest
import AVFoundation
import ImageIO
import SwiftData
import UIKit
import UniformTypeIdentifiers
@testable import HermesMobile

final class APIClientCommandExecTests: APIClientTestCase {
    func testCommandExecBuildsExpectedPathAndDecodesOutput() async throws {
        let client = makeClient { request in
            XCTAssertEqual(request.url?.path, "/api/commands/exec")
            XCTAssertEqual(request.httpMethod, "POST")

            let data = try XCTUnwrap(apiTestBodyData(from: request))
            let body = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            XCTAssertEqual(body?["command"] as? String, "reload-skills")

            return apiTestJSONResponse("""
            {
              "output": "Skills reloaded OK"
            }
            """, for: request)
        }

        let response = try await client.execCommand(name: "reload-skills")

        XCTAssertEqual(response.output, "Skills reloaded OK")
    }

    func testCommandExecToleratesMissingOutputField() async throws {
        let client = makeClient { request in
            XCTAssertEqual(request.url?.path, "/api/commands/exec")

            return apiTestJSONResponse("{}", for: request)
        }

        let response = try await client.execCommand(name: "status")

        XCTAssertNil(response.output)
    }
}