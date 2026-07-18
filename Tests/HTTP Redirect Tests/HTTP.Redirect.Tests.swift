import HTTP_Redirect
import HTTP_Standard
import Server
import Server_Shared
import Testing

@Suite("HTTP redirect policies")
struct RedirectTests {
    private static func headers(_ fields: [(String, String)]) -> HTTP.Headers {
        HTTP.Headers(fields.map { name, value in
            HTTP.Header.Field(name: .init(name), value: .init(unchecked: value))
        })
    }

    @Test
    func `canonical host`() async throws(Server_Shared.Server.Error) {
        let middleware = Redirect.Canonical(host: "www.example.com")
        let request = Server_Shared.Server.Request(
            method: .get,
            path: ["docs", "intro"],
            query: "page=2",
            headers: Self.headers([
                ("Host", "example.com"),
                ("X-Forwarded-Proto", "https")
            ])
        )

        let response = try await middleware.intercept(request) { _ in
            .status(.ok)
        }

        #expect(response.status == .movedPermanently)
        // swift-linter:disable:next raw value access
        // REASON: the test verifies the serialized Location header at the protocol boundary.
        #expect(response.headers.first("Location")?.rawValue == "https://www.example.com/docs/intro?page=2")
    }

    @Test
    func `canonical host pass through`() async throws(Server_Shared.Server.Error) {
        let middleware = Redirect.Canonical(host: "www.example.com")
        let request = Server_Shared.Server.Request(
            method: .get,
            path: ["docs"],
            headers: Self.headers([("Host", "www.example.com")])
        )

        let response = try await middleware.intercept(request) { _ in
            .status(.noContent)
        }

        #expect(response.status == .noContent)
    }

    @Test
    func `HTTPS redirect`() async throws(Server_Shared.Server.Error) {
        let middleware = Redirect.HTTPS(on: true)
        let request = Server_Shared.Server.Request(
            method: .get,
            path: ["login"],
            headers: Self.headers([
                ("Host", "example.com"),
                ("X-Forwarded-Proto", "http")
            ])
        )

        let response = try await middleware.intercept(request) { _ in
            .status(.ok)
        }

        #expect(response.status == .movedPermanently)
        // swift-linter:disable:next raw value access
        // REASON: the test verifies the serialized Location header at the protocol boundary.
        #expect(response.headers.first("Location")?.rawValue == "https://example.com/login")
    }

    @Test
    func `HTTPS pass through`() async throws(Server_Shared.Server.Error) {
        let middleware = Redirect.HTTPS(on: true)
        let request = Server_Shared.Server.Request(
            method: .get,
            path: [],
            headers: Self.headers([
                ("Host", "example.com"),
                ("X-Forwarded-Proto", "https")
            ])
        )

        let response = try await middleware.intercept(request) { _ in
            .status(.ok)
        }

        #expect(response.status == .ok)
        // swift-linter:disable:next raw value access
        // REASON: the test verifies the RFC 6797 field serialization at the protocol boundary.
        #expect(response.headers.first("Strict-Transport-Security")?.rawValue == "max-age=31536000; includeSubDomains")
    }
}
