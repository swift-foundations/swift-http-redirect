// ===----------------------------------------------------------------------===//
//
// Copyright (c) 2026 Coen ten Thije Boonkkamp
// Licensed under Apache License 2.0
//
// ===----------------------------------------------------------------------===//

import HTTP_Standard
import RFC_6797
public import Server

extension Redirect {
    /// Permanently redirects HTTP requests to the same resource over HTTPS.
    public struct HTTPS: Server.Middleware {
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
        _ request: Server.Request,
        next: Server.Responder
    ) async throws(Server.Error) -> Server.Response {
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
            throw Server.Error.badRequest("Missing Host header")
        }

        return .redirect(
            to: Self.location(host: host, request: request),
            permanent: true
        )
    }
}

extension Redirect.HTTPS {
    fileprivate static func location(
        host: String,
        request: Server.Request
    ) -> String {
        var location = "https://\(host)\(request.pathString)"
        if let query = request.query {
            location += "?\(query)"
        }
        return location
    }
}
