## [Unreleased]

## 0.1.8 - 07/29/24

- remove sinatra to simplify and fix some unintended parsing bugs
- drop jruby from CI matrix
- add base64 dependency for future compatibility

## 0.1.7 - 07/17/24

- fix #closed? on nil error when shutting down puma

## 0.1.6 - 07/15/24

- clear memoized x509 data for Cert#cert_pem=
- drop ruby 3.1 syntax
- simplify bind/listening output
- add a foreground cert provisioning success log message

## 0.1.5 - 4/11/24

- further fixes to expired order/cert renewal

## 0.1.4 - 4/11/24

- fix for expired order/cert renewal

## 0.1.3 - 3/1/24

- update dependencies
- add github actions and dependabot config
- add rubygems rake tasks

## 0.1.2 - 1/16/24

- Add port number to https url log line

## 0.1.1 - 1/16/24

- puma 5.6 compatibility

## 0.1.0 - 12/29/23

- Initial release
