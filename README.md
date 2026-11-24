# WithMarfaTelemetry

WithMarfaTelemetry is a small Swift package that sends an app's errors and a fixed set of log events to a PostHog project. WithMarfa uses it in its own apps, such as Marfa for Mac and Marfa Mini.

This package is not part of Marfa, and Marfa does not depend on it. It isn't a standard that an app built on Marfa should follow. If you build an app on the [Marfa Swift package](https://github.com/withmarfa/marfa-swift), you can ignore this package.

The package sends nothing until the app does two things: it calls `configure(_:)` with a PostHog destination of its own, and it sets `isEnabled` to `true`. The package has no default destination, no project token, and no third-party dependency.

## What it sends

Errors go to PostHog as `$exception` events. Log records go to PostHog's logs endpoint as OTLP/HTTP JSON.

An exception event carries:

- The error's type and one sentence that says what went wrong. Both are fixed in the source.
- The operation the app was running, fixed in the source.
- A server refusal code, only when the code has the shape of one: lowercase letters and underscores, at most 48 characters.
- The number of exceptions withheld since the previous one.
- The app's name and version, which the app supplies.
- The operating system name and version, and the chip architecture.
- A random identifier that is new each time the app starts and is not linked to a person.

A log record carries a name fixed in the source, a severity level, a timestamp, and attributes that are numbers, Booleans, or words fixed in the source. A batch also carries the app's name and version and the operating system and chip.

## What it never sends

The types make it hard to send anything else. An error is described by text fixed in the source, and a log attribute has no case for a `String` read at run time. The package never sends:

- Item text, titles, tags, item IDs, or natural keys.
- Keys or credentials.
- The identifier or address of a Marfa instance or server.
- File paths or search text.
- An error's `message` or `localizedDescription`.
- A person's name, email address, or device identifier.

Don't work around the types to pass any of these. Each can hold a person's words or identify their instance.

## Limits

A failure that repeats is reported at most once for each type and operation in 60 seconds, and at most 30 times an hour. At most 500 log records wait to be sent. Past that, the oldest is dropped, and the next batch says how many were. A report that fails to send is lost and isn't retried. Requests carry no cookies, use no cache, and follow no redirects, so a redirect can't carry the project token to another host.

## Install

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/withmarfa/app-telemetry-swift", from: "0.0.1")
],
targets: [
    .target(
        name: "MyApp",
        dependencies: [.product(name: "WithMarfaTelemetry", package: "app-telemetry-swift")]
    )
]
```

The package requires iOS 27 or macOS 27 and Swift 6.4. It depends on the Marfa Swift package for `MarfaError`.

## Use

Configure the reporter once, turn it on, and report from anywhere:

```swift
import Foundation
import Marfa
import WithMarfaTelemetry

let destination = try Telemetry.Destination(
    host: URL(string: "https://eu.i.posthog.com")!,
    projectToken: "phc_your_project_token"
)
Telemetry.shared.configure(
    .init(destination: destination, serviceName: "myapp", serviceVersion: "1.2.3")
)
Telemetry.shared.isEnabled = true

// A `MarfaError` named `error` becomes an exception with fixed text.
Telemetry.shared.report(error, during: "drain")

// An error of the app's own.
Telemetry.shared.report(
    type: "editor_process_ended", sentence: "the editor process ended", during: "edit"
)

// A log record.
Telemetry.shared.log("drain_finished", level: .info, attributes: ["pending": 3, "outcome": "ok"])

// When the app quits.
await Telemetry.shared.flush()
```

`Destination` accepts an `https` host, or an `http` host on the same machine for a test, with no user name or password, and a project token without white space. It refuses anything else.

Turning `isEnabled` off drops everything queued and stops a send that is under way.

## Privacy manifest

The package includes a `PrivacyInfo.xcprivacy` file. It declares no tracking and two kinds of collected data, Other Diagnostic Data and Performance Data. Neither is linked to a person, and both are collected for app functionality. The app must still describe its own use of the package in its App Store privacy answers.

## License

Apache License 2.0. See [LICENSE](LICENSE).
