# DNS API to GleSYS for acme.sh

This implements the needed functionality for the acme.sh to generate
certificates using DNS-01 API for GleSYS users.

The acme.sh script is available here:
https://github.com/Neilpang/acme.sh

Information about the GleSYS API is available here:
https://github.com/glesys/api/wiki/Api-Introduction

## Dependencies

This script depends on the utility jq (https://stedolan.github.io/jq/) to be
present on the system. I needed this functionality on my Ubiqity EdgeRouter and
the utility happened to be available on it so I decided to use it instead of
decoding the JSON responses manually.

## How to use

You need an account at Glesys. Login and generate an API token. This
API key needs a few domain permissions:

- listrecords
- addrecord
- deleterecord

Remember to also give your own IP address access to use this token.

Put the script dns_gleys.sh (or make a symlink) in the directory dnsapi which
you should found in the acme.sh directory (after you have downloaded it).

Run acme.sh like this:

```
export Glesys_User=<GleSYS username>
export Glesys_Token=<GleSYS API token>
acme.sh --issue --dns dns_glesys -d example.com
```

Or, if you want to generate and use the certificate on your Ubiqitu EdgeRouter
like me, follow this great guide:
https://github.com/hungnguyenm/edgemax-acme
