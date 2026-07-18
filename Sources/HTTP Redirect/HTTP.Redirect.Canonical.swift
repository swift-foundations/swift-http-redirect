// ===----------------------------------------------------------------------===//
//
// Copyright (c) 2026 Coen ten Thije Boonkkamp
// Licensed under Apache License 2.0
//
// ===----------------------------------------------------------------------===//

import HTTP_Standard
public import Server

extension Redirect {
    /// Permanently redirects requests whose `Host` differs from the configured host.
    public struct Canonical: Server.Middleware {
        public let host: String

        public init(host: String) {
            self.host = host
        }

    }
}

extension Redirect.Canonical {
    public func intercept(
        _ request: Server.Request,
        next: Server.Responder
    ) async throws(Server.Error) -> Server.Response {
        // swift-linter:disable:next raw value access
        // REASON: the server membrane exposes header values through this typed boundary.
        guard let currentHost = request.headers.first("Host")?.rawValue else {
            return try await next(request)
        }

        guard currentHost != host else {
            return try await next(request)
        }

        return .redirect(
            to: Self.location(
                // swift-linter:disable:next raw value access
                // REASON: the server membrane exposes forwarded scheme values through this typed boundary.
                scheme: request.headers.first("X-Forwarded-Proto")?.rawValue ?? "http",
                host: host,
                request: request
            ),
            permanent: true
        )
    }
}

extension Redirect.Canonical {
    fileprivate static func location(
        scheme: String,
        host: String,
        request: Server.Request
    ) -> String {
        var location = "\(scheme)://\(host)\(request.pathString)"
        if let query = request.query {
            location += "?\(query)"
        }
        return location
    }
}
