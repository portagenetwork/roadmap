# Security Policy

## Supported Versions

The following versions are currently supported with security fixes:

| Version | Supported |
| ------- | --------- |
| 4.1.1+portage-4.10.1 and later | ✅ |
| Earlier than 4.1.1+portage-4.10.1 | ❌ |

If you are using an older version, we strongly recommend upgrading to the latest supported release.

## Reporting a Vulnerability

If you discover a security vulnerability, please report it privately through GitHub's private vulnerability reporting:
https://github.com/portagenetwork/roadmap/security/advisories/new

If GitHub private reporting is not possible, you may contact us at:<br>
dmp-assistant(at)tech(dot)alliancecan(dot)ca

Please do not open a public issue for security vulnerabilities.

Please include:
- A description of the vulnerability and its potential impact
- Steps to reproduce, or a proof of concept if available
- Any relevant logs, screenshots, or configuration details

What to expect:
- Acknowledgment within a few business days
- Assessment and follow-up on next steps
- Coordination with you on remediation and disclosure timing if the report is confirmed

We ask that you give us reasonable time to address the issue before any public disclosure.

## Known Security Issues

### Unauthorized access to plan contributors (fixed in 4.1.1+portage-4.10.1)

Prior to release `4.1.1+portage-4.10.1`, any signed-in user could access the `GET plans/:id/contributors` endpoint for **any** plan, regardless of whether they had access to the underlying plan itself.

This was resolved in [PR #1416](https://github.com/portagenetwork/roadmap/pull/1416). All users are encouraged to upgrade to `4.1.1+portage-4.10.1` or later.

**Credit:** https://github.com/Santoshkumarpuppala
