// ===----------------------------------------------------------------------===//
//
// Copyright (c) 2026 Coen ten Thije Boonkkamp
// Licensed under Apache License 2.0
//
// ===----------------------------------------------------------------------===//

public import Server
public import Server_Shared
import RFC_6797

extension Redirect {
    /// Permanently redirects HTTP requests to the same resource over HTTPS.
    public struct HTTPS: Server_Shared.Server.Middleware {
        public let on: Bool

        // swift-linter:disable:next bool public parameter
        // REASON: the donor policy defines the switch as the stable `on` toggle.
        public init(on: Bool) {
            self.on = on
        }
    }
}

extension Redirect.HTTPS {
    public func intercept(
        _ request: Server_Shared.Server.Request,
        next: Server_Shared.Server.Responder
    ) async throws(Server_Shared.Server.Error) -> Server_Shared.Server.Response {
        guard on else {
            return try await next(request)
        }

        // swift-linter:disable:next raw value access
        // REASON: the server membrane exposes forwarded scheme values through this typed boundary.
        let scheme = request.headers.first("X-Forwarded-Proto")?.rawValue ?? "http"
        guard scheme.lowercased() != "https" else {
            var response = try await next(request)
            let hsts = RFC_6797.StrictTransportSecurity(
                maxAge: 31_536_000,
                includeSubDomains: .present
            )
            response.headers.append(
                HTTP.Header.Field(
                    name: .strictTransportSecurity,
                    value: .init(unchecked: hsts.headerValue)
                )
            )
            return response
        }

        // swift-linter:disable:next raw value access
        // REASON: the server membrane exposes host values through this typed boundary.
        guard let host = request.headers.first("Host")?.rawValue else {
            throw Server_Shared.Server.Error.badRequest("Missing Host header")
        }

        return .redirect(
            to: Self.location(host: host, request: request),
            permanent: true
        )
    }
}

private extension Redirect.HTTPS {
    static func location(
        host: String,
        request: Server_Shared.Server.Request
    ) -> String {
        var location = "https://\(host)\(request.pathString)"
        if let query = request.query {
            location += "?\(query)"
        }
        return location
    }
}
