# app-telemetry

The Swift package `WithMarfaTelemetry`: a PostHog client for WithMarfa's own apps (MAPP, Marfa Mini). Errors go out as PostHog `$exception` events and a fixed set of log events as OTLP/HTTP JSON to PostHog's logs endpoint. It has no third-party dependency, no token and no default destination, and it is inert until an app configures it (`Telemetry.shared.configure(_:)`) and turns `isEnabled` on.

It is not part of Marfa, and Marfa's own code carries no vendor dependency. It depends on the Marfa Swift package (`withmarfa/marfa-swift`, product `Marfa`) for `MarfaError` and `MarfaError.fixedText`, which stay there. It is not a standard that an app built on Marfa should follow, and no text here says it is.

## Layout and build

- `Sources/WithMarfaTelemetry` is the library, `Tests/WithMarfaTelemetryTests` its tests. `Package.swift` is the only manifest: `swift-tools-version: 6.4`, iOS 27 and macOS 27, Swift 6 language mode.
- `Telemetry` is the public reporter. `Configuration.swift` holds `Destination`, which refuses a host that is not `https` (or `http` on this machine) or that carries a user name or password, and a token that is empty or holds white space, and `Configuration`. `Logs.swift` holds `LogLevel` and `LogAttribute`, `Wire.swift` the bytes of each post, `Transport.swift` the one `URLSession` that sends, `RateLimit.swift` the `ExceptionLimiter`.
- `swift build` and `swift test` are the build and the tests. `scripts/lint.sh` is the format lint: run it before a push, since `Lint Swift` in CI runs `scripts/lint.sh --portable` on Linux, which leaves out `BeginDocumentationCommentWithOneLineSummary` because swift-format splits a comment into sentences differently there, and `Build + test` runs every rule.
- Nothing reaches a body but a `StaticString`, a number, a boolean, the app's own configuration, the operating system and chip, a count of withheld exceptions, or a server refusal code that `FixedErrorText.isCode` accepts. `MarfaError.fixedText` in `Marfa` is the exhaustive `switch` that gives an error's fixed type and sentence, so a new `MarfaError` case needs both written there before it compiles, and neither may include a value the error carries. A change here keeps every path to a body inside this list.
- `ExceptionLimiter` allows one exception for each type and operation in 60 seconds and 30 an hour. Tests inject the transport (`Recorder`) and the clock (`TestClock`) and use no network beyond a loopback server. No test touches the keychain.
- The package has its own `PrivacyInfo.xcprivacy`. A change to what the package sends changes it, and the README says the same.
- The OTLP scope name in `Wire.swift` is `WithMarfaTelemetry`, and a test pins it.

## CI

- `.github/workflows/ci.yml` runs `Lint workflows` (actionlint, and shellcheck on `scripts/`), `Lint Swift` (`scripts/lint.sh --portable` in the Swift release's Linux container) and `Build + test` (a macOS runner; `swift build --build-tests` with no warning in this package's own sources and tests, then `swift test`). The package is small, so every change runs all of it.
- A draft pull request runs only the Linux lints. The last job, `Full CI`, waits for every other job and fails if any failed or was cancelled; a skipped job counts as passed. On a draft it is named `Draft CI`, so the required `Full CI` stays expected, and blocks a merge, until the run that marking the pull request ready starts has finished. A draft and a ready pull request have separate concurrency groups, so marking one ready never cancels the full run.
- `Full CI` and `Pull request description` are the required checks. `pr-description.yml` runs `scripts/check-pr-description.sh`, which fails a description that does not follow the organization's pull request template.
- `codeql.yml` analyzes the workflows. Swift is not analyzed. Neither it nor Dependabot (`.github/dependabot.yml`, GitHub Actions and Swift packages) is a required check.

## Versions

A version is a tag on this repository, which is where SwiftPM reads versions from. The session that finishes a logical set of merged work, unless its brief says not to, creates the next tag from `main` with `gh release create`, each the previous plus 0.0.1 whatever the change: `v0.0.1`, `v0.0.2` and so on. No one writes a version into a file, and there is no release workflow.

## Writing

- Public prose (README, docs, issues, pull requests) follows the Google developer documentation style guide, in American English.
- Code comments follow the language's own conventions. A comment stays only if it says what the code cannot: a constraint from outside, a non-obvious reason, a trap. Never what the code does, history, a ticket or a person. When in doubt, it goes.
- The module, product, package and OTLP scope are all named `WithMarfaTelemetry`.

## Working here

- American English in code, comments and commits. Scoped Conventional Commits (`feat(package):`, `fix(ci):`), lowercase, present tense, under 70 characters.
- Make worktrees in `.claude/worktrees/` (`git worktree add .claude/worktrees/<name> -b <branch> origin/main`). Once the work is merged, remove the worktree and its local branch (`git worktree remove`, then `git branch -D`, because git sees a squash-merged branch as unmerged), run `git worktree prune` and `git pull --ff-only` on `main`. If git refuses a removal, report it rather than forcing it.
- Feature branches and pull requests; never push `main`. Merge with a squash, branch deleted, once the review the risk calls for is done and every required check has passed.
- Workflows use standard GitHub-hosted runners only.
- No personal details of any machine or person: no absolute paths, hostnames, account names or credentials.
- Removed means gone: no shims, aliases or compatibility paths.
- Swift 6 language mode; Swift Testing, not XCTest.

## Code Review Rules

Report only a real problem: one that breaks the issue's acceptance criteria, a rule written in this file (quote it) or correctness, and say how it fails: the input, state or step, and what goes wrong. If you cannot say how it fails, it is not a finding. Leave formatting, lint and anything CI catches to CI, and skip any convention that is not written down. Check the whole tree, not only the diff, and name each finding by the check it breaks.

- **Done.** The acceptance criteria are met, the change was run for real in the conditions it will meet and not only compiled, new behavior has a test that was seen failing first, and what the pull request claims is true. A test that asserts absence has a witness: the same path with the condition removed produces the thing.
- **True.** A comment, doc, instruction file, README statement or privacy manifest the change touches or leaves untrue is a finding, fixed in the same change. New prose follows the standard under Writing for its kind. A claim of completeness ("all callers updated") is checked by searching, not accepted.
- **Nothing reaches a body by another door.** Every value in a request is on the list under Layout and build, at every path that builds one, including one the change adds. Nothing is allowed because a name or field someone else controls says it is safe.
- **Nothing left behind.** Dead code, shims, old names and references to removed things.
- **Inert until configured.** With no configuration, or with `isEnabled` off, nothing is queued, nothing is sent and nothing already queued survives turning it back on.
- **Real conditions.** A real clock, slow or absent peers, a redirect, an untidy host or token, and the 500-record and 20-exception queue limits. One failed send stays contained and never takes down the app or the queue.
- **Tests stay local.** A test uses the injected transport and clock or a loopback server, and no test reads or writes the keychain.
- **Flaky tests.** An unexplained flaky test is a finding: reproduce it, or say exactly why it cannot recur.

Mark a finding blocking when it changes what is sent or when, or breaks a criterion or rule, and a quick fix when it is a name, a stale reference or a wrong count. Keep a problem that was there before the change apart from findings against it, and list it only if it is clearly wrong and would keep coming up.
