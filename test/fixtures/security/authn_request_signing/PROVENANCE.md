# authn_request_signing fixtures

These fixtures exist to pin the exact HTTP-Redirect AuthnRequest signing bytes for
Phase 35. The redirect fixtures are minted from the production `Binding.encode_redirect/3`
and `Signature.sign_redirect_query/3` seams using a committed RSA-2048 PEM and a
canonical AuthnRequest XML input with fixed ID, IssueInstant, Destination, and RelayState.

## Fixtures

| File | Bytes | sha256 |
| --- | ---: | --- |
| `golden_authnrequest.xml` | `601` | `3c49da4bb59444e21dbd01824cd0efb1c61cd2575926015fd5390e792ff2750a` |
| `golden_signing_key.pem` | `1676` | `cbecf5f31fe8c7b3a81fa05259e992111a169c13f8fb68009c5e8bbc5bd5e57d` |
| `golden_redirect.txt` | `962` | `e08daeb5421b72d17409f17c8a60ce7736c9d102450bad10291dea0387079a06` |
| `golden_redirect_adfs.txt` | `966` | `8fc898c1819a3f8ee687fd701051a93aab1578a9b923449ca9982405e4c1a0f8` |

## Notes

- `golden_authnrequest.xml` is the canonical input and carries fixed values:
  `ID="_relyra-phase35-golden-authnreq"`, `IssueInstant="2026-05-26T00:00:00Z"`,
  `Destination="https://idp.example.com/sso"`, `AssertionConsumerServiceURL="https://sp.example.com/saml/acs"`.
- `golden_redirect.txt` is the RFC 3986 uppercase-hex signed redirect query.
- `golden_redirect_adfs.txt` is the ADFS-lower variant. It differs only in percent-encoded
  hex case from the uppercase fixture.

## Spec chain

- OASIS SAML 2.0 Bindings §3.4.4.1 defines the signed query template and the raw-octet
  invariant.
- RFC 1951 defines the raw DEFLATE encoding used before base64.
- RFC 3986 §2.1 defines percent-encoding; the default fixture keeps uppercase hex.
- The lowercase-hex ADFS variant follows the `lowercase_urlencoding` behavior documented
  by the Python toolkit lineage used in the phase research.

## Mint procedure

On May 26, 2026, the redirect fixtures were minted from the committed `golden_authnrequest.xml`
and `golden_signing_key.pem` by calling `Relyra.Protocol.Binding.encode_redirect/3` with the
fixed RelayState `rs_relyra_phase35_golden`, `signature_method` set to
`http://www.w3.org/2001/04/xmldsig-more#rsa-sha256`, and encodings `:rfc3986_upper` /
`:adfs_lower`.

Re-mint policy: never re-mint these files without updating this manifest with new byte counts
and hashes.
