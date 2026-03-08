# Contributing

Thanks for considering a contribution to Ticklet.

## Getting Started

1. Open `Ticklet.xcodeproj` in Xcode.
2. Use the shared `Ticklet` scheme.
3. Run the app on macOS.

## Development Notes

- Keep changes focused and easy to review.
- Add or update tests when behavior changes.
- Prefer small pull requests with a clear summary.

## Before Opening a Pull Request

Run the test suite locally:

```sh
xcodebuild test -project Ticklet.xcodeproj -scheme Ticklet -destination 'platform=macOS'
```

## Pull Requests

- Describe the change and its intent.
- Include any manual verification steps when needed.
- Link related issues when applicable.
