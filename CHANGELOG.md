# Release Note

## v0.4.2

- Change ProffixHelpers methods from instance to static methods
- Update all ProffixHelpers() instantiations to static method calls
- Make ProffixError and ProffixErrorField immutable with final fields
- Add equality operators and hashCode to exception classes
- Refactor ProffixException toString() and toPxError() for better readability
- Extract common location header parsing logic into private method
- Cache Date

## v0.4.1

- Fix logout
- Add forceLogout parameter to logout()
- Add clearSessionCache parameter to logout()

## v0.4.0

- Update deps
- Fix ProffixException
- Implement session caching with file-based storage and retry logic
- Add retry logic for failed requests

## v0.3.8

- Update deps

## v0.3.7

- Update deps

## v0.3.5

- Dart 3
- Update deps

## v0.3.4

- Add Params to GetFile
- Update deps

## v0.3.3

- Fix big sized Upload Datei / Download Datei
- Optimize tests
- Update deps

## v0.3.2

- Update deps

## v0.3.1

- Update deps

## v0.3.0

- Fix Headers for Web / JS

## v0.2.9

- Update CI
- Upgrade all libs

## v0.2.8

- Optimize Tests and Codecov
- Upgrade all libs

## v0.2.7

- Upgrade all libs
- Fix SocketException

## v0.2.6

- Upgrade all libs
- Optimize Error message on Timeout

## v0.2.5

- Add DownloadFile Function

## v0.2.4

- Add uploadFile Function

## v0.2.3

- Fix GetList as Uint8

## v0.2.2

- Fix GetList as Uint8

## v0.2.1

- Fix GetList

## v0.2.0

- Clean deps
- Optimize ProffixException

## v0.1.9

- Fix Exception

## v0.1.8

- Upgrade to Dio

## v0.1.7

- Fix Status Response

## v0.1.6

- Optimize Status Response

## v0.1.5

- Fix param null exception

## v0.1.4

- Add Params to Post method
- Fix exceptions

## v0.1.1

- Make helpers and options public
- Add check() method for checking login

## v0.0.8

- Fix Exception for SocketExceptions (wrong url)
- Upgrade tests

## v0.0.7

- Add Exceptions
- Upgrade tests

## v0.0.6

- Add detailled docs
- Fix typos
- Fix tests

## v0.0.5

- Fix PxSessionId
- Add getPxSessionId() and setPxSessionId()
- Fix getList()

## v0.0.4

- Fix Tests, Add Helper Functions

## v0.0.3

- Add Tests for Post, Put, Patch

## v0.0.2

- Add Tests, Fix Deps

## v0.0.1

- First Release
