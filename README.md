# Setup

Create a `AppStoreConfiguration.swift` file in the `Sources` folder.

`AppStoreConfiguration.swift`
```Swift
@preconcurrency import AppStoreConnect_Swift_SDK

let APPSTORE_CONFIGURATION = try! APIConfiguration(
    issuerID: "...",
    privateKeyID: "...",
    privateKey: "..."
)
```

# Usage

Create metadata files that looks like this. All values are optional.
Place them in one folder and provide the folder path to the script.

```JSON
{
    "name": "...",
    "subtitle": "...",
    "privacyPolicyURL": "...",
    "privacyChoicesURL": "...",
    "privacyPolicyText": "...",
}
```

Then use it like this:

```
USAGE: appstore-update-metadata <localizations-path> --bundle-id <bundle-id>

ARGUMENTS:
  <localizations-path>    The path to the folder where the '.json' files are.

OPTIONS:
  --bundle-id <bundle-id> The bundle id of the app to update the metadata for.
  -h, --help              Show help information.
```
