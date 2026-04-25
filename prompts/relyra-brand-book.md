Relyra Brand Book

Version 0.1 — brand direction for an open-source Elixir/Phoenix SAML Service Provider library

Treat this as the working creative constitution for Relyra. It is written to be pasted into LLM context windows, design briefs, logo-generation prompts, UI implementation tasks, documentation-writing tasks, and landing-page copy tasks.

Research guardrails

The chosen name is viable enough to proceed creatively, but it is not legally cleared. I found one obvious unrelated naming overlap: ReLyra is used for a compact mechanical-keyboard shop/product, so the brand should consistently use Relyra, not reLyra, ReLyra, or any camel-case spelling. I did not find an obvious direct SAML/Elixir/enterprise-SSO product named Relyra in the searches I checked, but formal trademark, Hex, GitHub org, npm, domain, and package checks still matter before launch.  ￼

The naming environment is crowded with literal SAML names. In Elixir, samly and ex_saml are already used for Plug/Phoenix or Elixir/Phoenix SAML SP libraries; broader open-source SSO projects include SSOReady, Ory Polis/BoxyHQ Jackson, and Stytch SAML Shield. Relyra should therefore avoid generic “SAML Shield,” “SSOReady-like,” “AuthKit,” “Jackson,” “Polis,” or saml_* language as primary branding.  ￼

The visual and verbal identity should reflect the real domain: SAML is an XML-based framework for exchanging security information through assertions, requests, bindings, profiles, and metadata; Relyra’s brand should therefore feel exact, protocol-aware, and operable rather than magical.  ￼

⸻

1. Brand essence

Name

Relyra

Recommended pronunciation: REH-lee-ruh
Acceptable pronunciation if people naturally say it: ruh-LY-ruh
Never correct users aggressively. The brand should feel helpful, not precious.

Name meaning

Relyra is anchored in relying party, the SAML/OIDC term for the application that depends on an identity provider’s assertion. It also carries the everyday English idea of rely: depend, trust, count on.

The name should not be explained as fantasy, mythology, music, or “Lyra.” Avoid constellation, lyre, harp, music, or celestial imagery. The point is not poetry. The point is reliable trust under protocol pressure.

Core idea

Relyra turns messy enterprise SAML into a verified trust path.

A Phoenix app receives an assertion. Relyra verifies the path, binds the assertion to the right tenant, rejects unsafe protocol states, maps identity clearly, and leaves an audit trail.

Brand promise

Secure, observable, Phoenix-native SAML that developers can operate with confidence.

One-line positioning

Relyra is an open-source SAML Service Provider system for Elixir/Phoenix teams that need strict validation, multi-tenant enterprise SSO, and operational clarity.

Short tagline options

Use these depending on context:

1. Enterprise SAML, calmly verified.
2. Strict SSO for Phoenix.
3. The relying-party toolkit for Elixir.
4. Secure SAML without becoming a SAML expert.
5. A safer path through enterprise SSO.
6. Phoenix-native SAML with strict defaults.

Primary recommendation:

Enterprise SAML, calmly verified.

It is distinctive, calm, and aligned with the visual direction.

⸻

2. Brand personality

Relyra should feel like a well-made instrument for dangerous protocol work.

Not a hype product.
Not a dark cyber tool.
Not an enterprise SaaS billboard.
Not playful in a way that trivializes authentication.

Personality traits

1. Calm

Relyra does not panic, boast, or dramatize. It speaks clearly when something is wrong.

Use: “The assertion expired 42 seconds before it reached this ACS endpoint.”
Avoid: “Critical SAML failure!!!”

2. Exact

Relyra is obsessed with binding the right data to the right trust decision.

Use: “Relyra consumes only the verified signed assertion.”
Avoid: “Relyra makes SAML easy with magic.”

3. Transparent

Relyra explains what it checked, why it failed, and what the developer or admin should do next.

Use: “Expected Audience: … Received Audience: …”
Avoid: “Invalid configuration.”

4. Operator-friendly

The brand understands that SAML is not just code. It is certificates, metadata, customer admins, provider quirks, logs, and support tickets.

Use: “Certificate expires in 12 days. Add the replacement certificate before enabling rollover.”
Avoid: “Ask your IdP admin.”

5. Open-source serious

Relyra should look and sound like a sustainable OSS project: documented, testable, transparent, and community-oriented.

Use: “Security advisories are handled privately first, then documented publicly.”
Avoid: “Enterprise-grade military-grade SSO.”

⸻

3. Brand archetype

Relyra is The Steward, not The Warrior.

It protects trust boundaries, but it does so by maintaining order, clarity, and process. This matters visually: no aggressive shields, no swords, no hacker grids, no alarmist red-and-black cyber aesthetic.

Secondary archetype: The Cartographer. Relyra maps the path from IdP to Phoenix session and shows exactly where trust is established or rejected.

Brand tension

SAML is old, XML-heavy, and full of footguns. Relyra should not pretend otherwise.

The tone is:

“Yes, SAML is complicated. Here is the safe path.”

Not:

“SAML in five minutes with one weird trick.”

⸻

4. Positioning system

Category

Open-source Elixir/Phoenix SAML Service Provider library.

Who it is for

Primary users:

* Phoenix SaaS engineers adding enterprise SSO.
* Platform/auth teams managing multi-tenant SAML.
* OSS maintainers who need a secure, sustainable protocol boundary.
* Security engineers reviewing authentication behavior.
* Customer IT admins configuring Okta, Entra, Google Workspace, Ping, OneLogin, ADFS, Shibboleth, or Keycloak.

What Relyra is

Relyra is:

* A SAML SP implementation.
* A Phoenix-native integration layer.
* A multi-tenant SSO configuration system.
* A security-first validation pipeline.
* A support/debugging tool for real-world IdP setup.
* An OSS project with a visible security posture.

What Relyra is not

Relyra is not:

* A hosted SSO broker.
* A commercial enterprise identity platform.
* An IdP.
* An OIDC provider.
* A “drop this in and forget security” wrapper.
* A generic auth framework.
* A SAML tutorial pretending to be a library.

Differentiation

Relyra should differentiate on:

1. Strict defaults
    Unsafe SAML behavior is not silently accepted.
2. Phoenix-native ergonomics
    Router macros, Plug integration, Ecto optionality, LiveView admin workflows, telemetry.
3. Operational maturity
    Certificate expiry, metadata refresh, audit events, debug bundles, provider presets.
4. Security explainability
    Error taxonomy, validation trace, test corpus, clear threat model.
5. Open-source trust
    No SaaS lock-in, no hidden auth boundary, no black-box protocol handling.

⸻

5. Messaging pillars

Pillar 1: Verify the right thing

SAML failures often happen when software verifies one XML node but consumes another. Relyra’s core message should repeatedly reinforce exactness.

Sample copy:

Relyra validates the assertion it actually consumes. No loose parsing. No casual signatures. No “close enough” identity.

Pillar 2: Safe defaults, explicit escape hatches

Unsafe compatibility exists only when the operator understands the risk.

Sample copy:

Legacy IdP settings are possible, but never quiet. Relyra marks unsafe options clearly, records them in audit events, and gives teams a path back to strict mode.

Pillar 3: Built for Phoenix teams

Relyra belongs in Phoenix apps, not next to them as a mysterious service.

Sample copy:

Use Phoenix routes, Plug pipelines, telemetry, Ecto schemas, and LiveView workflows. Relyra fits the way Phoenix teams already build and operate software.

Pillar 4: Enterprise setup without ticket ping-pong

Customer admins need self-service clarity.

Sample copy:

Show the ACS URL, Entity ID, metadata, certificate status, and attribute mapping in one place. Help the customer admin finish configuration without a week of screenshots.

Pillar 5: Observable by design

Auth is a production system. Relyra should leave traces.

Sample copy:

Every SAML login becomes a validation trace: what arrived, what was checked, what was trusted, what was rejected, and why.

⸻

6. Visual identity direction

Creative concept

The Verified Path

A SAML login is a path: browser → IdP → assertion → ACS → validation → user mapping → Phoenix session.

Relyra’s visual identity should express a path that is:

* connected,
* inspected,
* signed,
* bounded,
* and safe to follow.

Visual mood

Use words like:

* calm
* exact
* structured
* luminous
* technical
* restrained
* legible
* diagrammatic
* trusted
* maintained

Avoid words like:

* edgy
* cyberpunk
* hacker
* magical
* mystical
* luxury
* playful
* cute
* futuristic sci-fi
* military
* “zero trust” cliché

Core visual metaphors

Use these:

* signed path
* verified node
* trust boundary
* assertion frame
* certificate seal
* metadata map
* relay line
* Phoenix route
* tenant connection
* audit trace

Avoid these:

* padlocks as the main logo
* generic shields
* keys
* fingerprints
* hooded hackers
* glowing server rooms
* constellation/lyre/music imagery
* chain links
* blockchain-like nodes
* purple SaaS blobs
* corporate handshake stock photos

⸻

7. Logo direction

Logo objective

The logo should feel like a protocol mark, not a consumer app icon.

It should work as:

* a GitHub org avatar,
* a Hex package icon,
* a favicon,
* a docs header,
* a CLI/generator badge,
* a LiveView admin header,
* a landing-page hero mark.

Preferred logo structure

Option A: The Relying Path monogram

A custom R built from:

* a vertical left stem representing the Service Provider,
* a right-side node or curve representing the Identity Provider,
* a diagonal leg representing the verified assertion path,
* a small dot/node where verification occurs.

The mark should not look like a generic “R in a circle.” It should suggest routing, binding, and verification.

Option B: The Assertion Frame

A rectangular or bracket-like frame containing a single verified node. Think:

* XML node,
* signed assertion,
* bounded trust object,
* exact consumption.

This is more abstract and may work well for a technical audience.

Option C: The Trust Path

Two endpoints connected by a line that passes through a check node or seal. The form should be restrained and geometric.

This option is friendlier for landing pages and diagrams, but riskier because node-link logos are common. It needs distinctive geometry.

Wordmark

Canonical wordmark text:

Relyra

Preferred casing:

Relyra

Avoid:

* RELYRA as the main brand; too loud.
* relyra as the main brand; too package-only.
* reLyra; overlaps with the existing keyboard styling and feels awkward.
* RelyRa; too artificial.

Wordmark feel

The wordmark should be:

* human but technical,
* slightly condensed,
* highly legible,
* not rounded-bubbly,
* not sharp-cyber,
* not pharma-soft.

A good direction is a custom wordmark based loosely on a grotesque sans with subtle cuts or terminals. The R and y should carry identity. The a should be simple, not overly geometric.

Logo geometry

Recommended:

* 1.5px or 2px stroke logic at base icon size.
* Rounded joins, not pillowy rounded ends.
* Angles based on 30°, 45°, or 60°.
* Optical balance over strict symmetry.
* Use negative space to imply a verified route.

Clear space

Minimum clear space around logo:

* Use the height of the lowercase r stem as the clear-space unit.
* For app icons, use 14–18% internal padding.

Minimum sizes

* Full horizontal lockup: 120px wide minimum.
* Icon only: 24px minimum in UI, 16px favicon with simplified detail.
* Do not use the full wordmark below 120px wide; use icon.

Logo color usage

Preferred logo colorways:

1. Ink mark on Paper.
2. Paper mark on Ink.
3. Relay Blue mark on Paper.
4. Paper mark on Deep Relay.
5. One-color monochrome for docs, README badges, and package registries.

Avoid gradient-only logos. Gradients can appear in hero art, not as the core identity.

Logo misuse

Do not:

* Put the mark inside a shield by default.
* Add a padlock.
* Add a key.
* Add a flame or Phoenix bird.
* Use music/lyre/constellation references.
* Use neon glow.
* Use 3D glassmorphism as the primary logo.
* Use a cartoon mascot as the primary identity.
* Stretch the wordmark.
* Render “Relyra” in a pharma-like rounded typeface.

Logo-generation prompt

Use this prompt when exploring logo concepts:

Create a restrained, technical logo for “Relyra,” an open-source Elixir/Phoenix SAML Service Provider library. The brand idea is “the verified trust path.” Explore a custom R monogram or abstract assertion-frame mark using thin geometric paths, one verified node, and a sense of bounded trust. The mark should feel calm, exact, open-source, protocol-aware, and secure without using padlocks, shields, keys, hackers, flames, birds, music, constellations, or generic SaaS blobs. Prefer flat vector geometry, strong small-size legibility, and a wordmark in title case: Relyra.

⸻

8. Color system

The color system should be calm, technical, and warm enough to avoid “cold enterprise security vendor.” Relyra should not look like a generic black-and-neon cybersecurity site.

Accessibility baseline: design for WCAG AA contrast. WCAG 2.2 describes accessibility guidance broadly; WCAG text contrast guidance targets at least 4.5:1 for normal text, while non-text UI components should be distinguishable with sufficient contrast.  ￼

Primary palette

Token	Hex	Use
Ink	#101827	Primary text, dark backgrounds, logo
Graphite	#263245	Secondary dark surfaces, headings
Paper	#FCFBF7	Main light background
Mist	#EEF2F6	Soft panels, code background, disabled surfaces
Relay Blue	#3454D1	Primary actions, links, active states
Deep Relay	#1D2E82	Dark brand blue, hero blocks, emphasis
Proof Teal	#147D77	Success-adjacent, verified states, secondary accent
Keyline Violet	#6D5DF2	Rare accent, diagrams, focus highlights
Accessible Border	#7E8A9A	Form borders and meaningful UI boundaries
Soft Line	#D8E0EA	Dividers only; not enough for meaningful controls
Certificate Gold	#C08A2B	Certificate/caution accent, not body text on light backgrounds

Semantic colors

Token	Hex	Use
Success	#027A48	Successful validation, enabled connection
Warning	#B45309	Expiring certificates, unsafe compatibility
Error	#B42318	Rejected assertion, invalid signature
Info	#3454D1	Neutral guidance, setup steps

Dark mode palette

Token	Hex	Use
Dark Background	#0B1020	Main dark background
Dark Surface	#111827	Cards, panels
Dark Border	#334155	Subtle boundaries
Dark Text	#F8FAFC	Primary text
Dark Muted	#CBD5E1	Secondary text
Dark Blue	#8CA2FF	Links/actions on dark
Dark Teal	#61D6C8	Verified accents
Dark Violet	#A99BFF	Focus/diagram accent
Dark Amber	#FBBF24	Warning
Dark Red	#FDA29B	Error
Dark Green	#86EFAC	Success

Color ratios

Recommended visual ratio:

* 70% Paper / Ink / Mist: calm base.
* 20% Relay Blue / Deep Relay: navigation, action, active state.
* 7% Proof Teal: verified, success-adjacent, trust path.
* 3% Violet / Gold / semantic colors: emphasis only.

Color rules

Do:

* Use blue for primary actions.
* Use teal for verified protocol states.
* Use amber for time-bound risk, especially certificate expiry or unsafe compatibility.
* Use red only for rejection, danger, or destructive action.
* Use Paper rather than pure white for most marketing surfaces.
* Use Ink rather than pure black.

Do not:

* Use red for normal “security” branding.
* Use green as the main brand color; it makes Relyra feel like monitoring software.
* Use purple gradients as the default; too much SaaS overlap.
* Use gray-on-gray for form borders that need to be recognized as controls.
* Use Certificate Gold as normal body text on light backgrounds.

CSS token starter

:root {
  --relyra-ink: #101827;
  --relyra-graphite: #263245;
  --relyra-paper: #FCFBF7;
  --relyra-mist: #EEF2F6;
  --relyra-soft-line: #D8E0EA;
  --relyra-border: #7E8A9A;
  --relyra-blue: #3454D1;
  --relyra-blue-deep: #1D2E82;
  --relyra-teal: #147D77;
  --relyra-violet: #6D5DF2;
  --relyra-gold: #C08A2B;
  --relyra-success: #027A48;
  --relyra-warning: #B45309;
  --relyra-error: #B42318;
  --relyra-info: #3454D1;
}
[data-theme="dark"] {
  --relyra-ink: #F8FAFC;
  --relyra-paper: #0B1020;
  --relyra-mist: #111827;
  --relyra-soft-line: #334155;
  --relyra-border: #64748B;
  --relyra-blue: #8CA2FF;
  --relyra-blue-deep: #A9B7FF;
  --relyra-teal: #61D6C8;
  --relyra-violet: #A99BFF;
  --relyra-gold: #FBBF24;
  --relyra-success: #86EFAC;
  --relyra-warning: #FBBF24;
  --relyra-error: #FDA29B;
}

⸻

9. Typography

The type system should reinforce exactness and readability. Because Relyra handles security-critical configuration and documentation, ambiguous glyphs are a brand problem, not just a design problem.

Recommended open-source stack

Display / marketing headings

IBM Plex Sans Condensed or IBM Plex Sans

Use for:

* landing-page hero headings,
* docs landing headings,
* GitHub README hero image,
* section headers,
* diagrams.

IBM Plex is an open-source typeface family with Sans, Serif, Mono, and Condensed variants designed to work across UI and other media.  ￼

Product UI and documentation body

Atkinson Hyperlegible

Use for:

* admin UI body text,
* form labels,
* validation traces,
* docs body copy,
* warning text,
* setup instructions.

Atkinson Hyperlegible was designed for clearer letter and number differentiation, especially for low-vision readers, which fits Relyra’s emphasis on unambiguous configuration and error reading.  ￼

Code

JetBrains Mono

Use for:

* code blocks,
* inline code,
* XML snippets,
* terminal commands,
* config examples,
* request IDs,
* certificate fingerprints.

JetBrains Mono is available under the SIL Open Font License and is designed for developer/code use.  ￼

Font fallback stack

--font-display: "IBM Plex Sans Condensed", "IBM Plex Sans", system-ui, sans-serif;
--font-body: "Atkinson Hyperlegible", system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
--font-code: "JetBrains Mono", ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;

Type scale

Use a restrained scale.

Role	Size	Line height	Weight
Hero	56–72px	0.95–1.05	650–700
H1	40–48px	1.05	650–700
H2	30–36px	1.12	650
H3	22–26px	1.2	650
Body large	18–20px	1.55	400
Body	16px	1.55	400
Small	14px	1.45	400–500
Caption	12–13px	1.4	500
Code	13–15px	1.55	400–500

Typography rules

Do:

* Use short headings.
* Use generous line height for docs.
* Use monospace for protocol fields: Audience, Recipient, InResponseTo, RelayState.
* Use tabular numerals for metrics, certificate dates, and validation traces.
* Keep code examples readable over clever.

Do not:

* Use all caps for long labels.
* Use decorative serifs.
* Use condensed text for body copy.
* Use low-contrast gray body text.
* Use tiny code blocks.
* Use ambiguous error codes without explanation.

⸻

10. Layout and composition

Grid

Use a rational 12-column grid for marketing pages and a simpler 8px spacing system for product UI.

Spacing scale:

2, 4, 8, 12, 16, 24, 32, 48, 64, 96, 128

Layout feel

Relyra layouts should feel like technical documentation and product design had a shared design director.

Use:

* crisp panels,
* generous whitespace,
* precise dividers,
* stable alignment,
* diagrammatic sections,
* code next to explanation,
* clear status regions.

Avoid:

* crowded dashboards,
* decorative cards with no hierarchy,
* excessive gradients,
* full-screen animated blobs,
* dense marketing walls,
* novelty layouts that make docs harder to read.

Card style

Default cards:

* background: Paper or Mist,
* border: Soft Line,
* radius: 12px,
* padding: 24px,
* shadow: minimal or none.

Important cards:

* border-left or top accent in Relay Blue, Proof Teal, Warning, or Error.
* never rely on color alone; include icon and heading.

Border radius

* Small controls: 8px.
* Cards: 12px.
* Large panels: 16px.
* Pills/badges: fully rounded only when semantically a badge.

Shadows

Use shadows sparingly.

Preferred:

box-shadow: 0 1px 2px rgba(16, 24, 39, 0.06),
            0 8px 24px rgba(16, 24, 39, 0.06);

Avoid dramatic SaaS shadows.

⸻

11. Iconography

Icon style

* Outline icons.
* 1.75px or 2px stroke.
* Rounded caps and joins.
* Simple geometry.
* No filled emoji-like icons.
* No complex pictograms at small sizes.

Core icon set

Relyra should eventually have custom icons for:

* SAML connection
* Identity Provider
* Service Provider
* Metadata
* Certificate
* Assertion
* Signature
* Replay cache
* RelayState
* Audience
* Recipient
* Request ID
* Tenant
* Attribute mapping
* Group mapping
* Provisioning
* Audit event
* Unsafe option
* Debug bundle

Icon metaphors

Use:

* document with bounded node for assertion,
* certificate rectangle with fingerprint lines,
* two endpoints plus route for connection,
* clock + certificate for expiry,
* bracketed dot for exact node,
* map pin/path for RelayState,
* stacked lines for metadata.

Avoid:

* shield everywhere,
* lock everywhere,
* generic user silhouette everywhere,
* fingerprint for identity,
* matrix/code rain.

⸻

12. Illustration and imagery

Illustration style

Use abstract technical illustrations:

* thin-line diagrams,
* layered protocol paths,
* bounded XML/document shapes,
* metadata cards,
* connection maps,
* validation timelines,
* subtle grid backgrounds,
* certificate rollover timelines,
* multi-tenant connection matrices.

Preferred style:

* flat vector,
* two-color or three-color,
* mostly Ink, Mist, Blue, Teal,
* precise geometry,
* slight warmth through Paper background.

Acceptable imagery

Acceptable:

* abstract protocol diagrams,
* simplified UI screenshots,
* terminal/code snippets,
* clean product panels,
* redacted validation traces,
* architectural diagrams,
* close-up neutral hardware textures if used sparingly,
* paper/document/certificate textures as very subtle backgrounds.

Not acceptable:

* stock photos of hackers,
* stock photos of office handshakes,
* “security person in hoodie,”
* glowing padlocks,
* blue neon city grids,
* robot/AI imagery,
* fantasy/rune imagery,
* lyres, harps, constellations,
* Phoenix bird/flame as main motif,
* cheesy enterprise photography.

Diagram style

All diagrams should follow this mental model:

[Phoenix App / SP] → [AuthnRequest] → [IdP]
[IdP] → [SAMLResponse] → [ACS]
[ACS] → [Validation Trace] → [Principal] → [Session Adapter]

Use labels like:

* Build request
* Store request ID
* Receive response
* Decode safely
* Verify signature
* Validate conditions
* Reject replay
* Map principal
* Establish session

Never draw “magic arrows” that hide the dangerous parts.

⸻

13. Motion design

Relyra motion should feel like validation, not entertainment.

Use motion for:

* step-by-step validation traces,
* connection test progress,
* metadata refresh status,
* certificate rollover timeline,
* drawer/panel transitions,
* subtle focus movement.

Motion principles:

* short duration: 120–220ms for UI.
* easing: calm ease-out.
* no bouncing.
* no confetti for security success.
* no alarming shake for errors.
* respect prefers-reduced-motion.

Good animation metaphor:

A route line progresses through checkpoints, and each checkpoint resolves into verified, warning, or rejected state.

Bad animation metaphor:

A shield explodes into sparks.

⸻

14. Product UI design

UI personality

The UI should feel like an admin cockpit for trust configuration.

It should be calm, readable, and explicit. It should not feel like a consumer onboarding wizard or a dark SIEM dashboard.

Primary product areas

1. SAML Connections

Table columns:

* Connection name
* Organization
* Provider
* Status
* Signing certificate
* Last login
* Last test
* Updated

Statuses:

* Draft
* Testing
* Enabled
* Disabled
* Error
* Certificate expiring
* Metadata stale
* Unsafe option enabled

2. Connection Detail

Sections:

* Overview
* SP details
* IdP details
* Certificates
* Security settings
* Attribute mapping
* Provisioning
* Test connection
* Audit log

3. Test Connection

The test UI is a brand-defining moment. It should show exactly what happened.

Example:

✓ Received SAMLResponse
✓ Decoded base64 payload
✓ Parsed XML with external entities disabled
✓ Matched issuer
✓ Verified assertion signature
✓ Validated audience
✓ Validated recipient
✓ Checked InResponseTo
✓ Rejected replay
✓ Mapped principal
Ready to establish a session for this connection.

Failed state:

Validation stopped at Audience.
Expected:
https://app.example.com/sso/acme/metadata
Received:
https://staging.example.com/sso/acme/metadata
How to fix:
In your IdP, set Audience URI / SP Entity ID to the expected value above.

4. Certificate Rollover

Use timeline UI:

Current certificate       expires in 18 days
Replacement certificate   imported from metadata
Rollover mode             both certificates trusted
Next refresh              in 6 hours

5. Unsafe Options

Unsafe options must be visible and auditable.

Example panel:

Unsafe compatibility option enabled
SHA-1 signatures are allowed for this connection until 2026-12-31.
Reason:
Customer ADFS migration.
Risk:
SHA-1 is deprecated and should not be used for new SAML integrations.
Audit:
This setting will be recorded on every login attempt.

OWASP’s SAML guidance highlights replay and protocol-message caching concerns, so Relyra’s UI should make replay/cache state visible rather than burying it in configuration.  ￼

Component rules

Buttons

Primary:

* Relay Blue background.
* Paper/white text.
* Label with verb + object: “Test connection,” “Import metadata,” “Enable SAML.”

Secondary:

* Paper background.
* Ink text.
* Border.

Danger:

* Error background only for destructive operations.
* Destructive labels must be explicit: “Disable connection,” not “Delete” unless deletion is real.

Forms

Labels should be precise:

Use:

* “IdP Entity ID”
* “Single Sign-On URL”
* “Signing certificate”
* “SP Entity ID”
* “ACS URL”
* “NameID format”
* “Require signed assertion”

Avoid:

* “URL”
* “Cert”
* “Thing”
* “SAML value”

Help text

Help text should answer:

1. What is this?
2. Where do I get it?
3. What breaks if it is wrong?

Example:

The IdP Entity ID identifies the identity provider that issued the assertion.
Relyra rejects responses whose Issuer does not match this value.

Empty states

Good:

No SAML connections yet.
Create a connection for each customer organization that signs in through an enterprise identity provider.

Bad:

Nothing here!

Loading states

Good:

Validating metadata…
Checking signing certificates…

Bad:

Loading magic…

⸻

15. UX microcopy

Microcopy principles

Every security message should include:

1. What happened
2. Why it matters
3. What to do next

Error voice

Errors should be calm and specific.

Use:

Relyra rejected this response because the assertion signature could not be verified with any trusted certificate for this connection.

Avoid:

Invalid SAML.

Use:

This RelayState value is not allowed. Relyra only redirects to destinations created by the server-side relay store.

Avoid:

Bad RelayState.

Use:

This assertion has already been consumed. Relyra rejected it to prevent replay.

Avoid:

Replay detected!!!

Confirmation modals

Enable connection

Enable SAML connection?
Users in this organization will be able to sign in through this identity provider.
Before enabling, confirm that:
• A break-glass admin login exists.
• The test login completed successfully.
• The signing certificate is current.

Primary button:

Enable connection

Secondary:

Keep testing

Disable connection

Disable SAML connection?
Users will no longer be able to sign in through this identity provider. Existing application sessions are not revoked automatically.

Primary destructive button:

Disable connection

Secondary:

Cancel

Enable unsafe option

Allow SHA-1 signatures for this connection?
This weakens the default signing policy and should only be used for a time-boxed legacy migration.
Relyra will record this setting in audit events and validation traces.

Primary button:

Allow until selected date

Secondary:

Keep strict policy

Success messages

Use success messages that state what was verified.

Good:

Metadata imported. Relyra found 2 signing certificates and 1 POST SSO endpoint.

Good:

Connection test passed. The assertion was verified, mapped, and checked for replay.

Avoid:

All good!

⸻

16. Documentation voice

Docs personality

The docs should be:

* precise,
* patient,
* security-aware,
* friendly to Phoenix developers,
* respectful of SAML complexity,
* explicit about unsafe tradeoffs.

Documentation motto

Explain the protocol only as much as needed to make the safe path understandable.

Tone rules

Do:

* Say “Relyra rejects…”
* Say “By default…”
* Say “In production…”
* Say “This matters because…”
* Say “Use this option only when…”
* Show exact config.
* Explain provider labels.

Do not:

* Say “just.”
* Say “magic.”
* Say “simple” when the concept is not simple.
* Hide risky options.
* Blame the user or the IdP admin.
* Use jokes in error explanations.
* Overpromise SLO or IdP-initiated security.

Preferred docs structure

Every guide should follow this shape:

1. What you will build
2. Requirements
3. Install
4. Generate config
5. Add routes
6. Configure provider
7. Test connection
8. Enable safely
9. Troubleshooting
10. Production checklist

Callout types

Safe default

> Safe default  
> Relyra requires a signed assertion or signed response by default. Do not disable this in production.

Why this matters

> Why this matters  
> The Audience value tells Relyra which Service Provider the assertion was issued for. If it does not match your SP Entity ID, the assertion may belong to another app or environment.

Unsafe compatibility

> Unsafe compatibility  
> This setting exists for legacy IdPs. Use it only with an expiry date and an audit reason.

Provider label

> Okta label  
> Okta calls this value “Audience URI (SP Entity ID).” Relyra calls it `sp_entity_id`.

Documentation vocabulary

Preferred terms:

* SAML connection
* identity provider
* service provider
* relying party
* assertion
* response
* metadata
* ACS URL
* Entity ID
* signing certificate
* validation trace
* replay cache
* request store
* relay state
* provider preset
* unsafe compatibility option

Avoid as primary language:

* “customer IdP thing”
* “SAML blob”
* “auth magic”
* “payload” when “assertion” or “response” is clearer
* “SSO app” when “SAML connection” is clearer

⸻

17. Brand voice examples

Homepage hero

Enterprise SAML, calmly verified.
Relyra is an open-source SAML Service Provider system for Elixir and Phoenix. Add multi-tenant enterprise SSO with strict validation, provider presets, telemetry, and admin workflows your support team can actually operate.

CTA buttons:

* Get started
* View security model

README intro

# Relyra
Relyra is a security-first SAML 2.0 Service Provider library for Elixir and Phoenix.
It gives Phoenix teams the pieces they need to run enterprise SSO safely: strict response validation, replay protection, multi-tenant connection resolution, metadata import/export, telemetry, and optional Ecto/LiveView admin workflows.

Short product description

Relyra helps Phoenix SaaS teams add secure SAML SSO without outsourcing the trust boundary or becoming SAML experts.

Security positioning

Relyra treats every SAML response as hostile until it has been parsed safely, verified against trusted certificates, bound to the right connection, checked for replay, and mapped intentionally.

Admin UI intro

Configure SAML for this organization.
Relyra will guide you through SP details, IdP metadata, certificate validation, attribute mapping, and a test login before the connection can be enabled.

Error page

SAML sign-in was rejected.
Relyra could not verify that this assertion was intended for this application. No session was created.
Error code:
:invalid_audience

Landing-page proof points

Strict by default
Reject unsigned assertions, deprecated algorithms, replayed responses, unsafe RelayState, and mismatched audiences unless explicitly configured otherwise.
Phoenix-native
Use routes, plugs, telemetry, behaviours, and optional Ecto/LiveView workflows instead of a black-box sidecar.
Built to operate
Track certificate expiry, metadata freshness, connection health, validation failures, and audit events from day one.

⸻

18. Landing page direction

Homepage structure

1. Hero

Headline:

Enterprise SAML, calmly verified.

Subhead:

Relyra is an open-source SAML Service Provider system for Elixir/Phoenix teams that need strict validation, multi-tenant SSO, and operational clarity.

Primary CTA:

Get started

Secondary CTA:

Read the security model

Hero visual:

* A simplified validation trace panel.
* Show a SAML response moving through checkpoints.
* Avoid abstract blobs.

2. The problem

Headline:

SAML is not hard because of one endpoint. It is hard because of everything around it.

Bullets:

* Provider-specific setup.
* Certificates and rollover.
* Replay protection.
* Signed XML.
* Tenant resolution.
* Attribute mapping.
* Debugging support tickets.

3. The Relyra path

Show five columns:

1. Configure connection
2. Import metadata
3. Start login
4. Validate response
5. Establish session

4. Security defaults

Use a checklist:

* Safe XML parsing
* Signature verification
* Exact signed node consumption
* Audience/recipient/destination checks
* Replay protection
* RelayState safety
* Algorithm policy

5. Phoenix-native

Show code:

scope "/sso", MyAppWeb do
  pipe_through :browser
  saml_routes MyApp.SSO,
    connection_resolver: MyApp.SSO.ConnectionResolver,
    session_adapter: MyAppWeb.SAMLSession
end

6. Admin-ready

Show UI screenshot/illustration:

* metadata import,
* certificate status,
* test connection,
* attribute preview.

7. Observability

Show telemetry/audit examples.

8. OSS footer

Emphasize:

* MIT/Apache license, depending on final choice.
* Security policy.
* Changelog.
* Test fixtures.
* Contribution guide.

Homepage visual rhythm

Alternate:

* explanation,
* code,
* UI screenshot,
* diagram,
* checklist.

Do not create a pure marketing page with no technical proof.

⸻

19. Product information architecture

Recommended nav:

Relyra
├── Overview
├── Connections
│   ├── All connections
│   ├── New connection
│   └── Provider presets
├── Certificates
├── Metadata
├── Login attempts
├── Audit log
├── Settings
└── Help / Debug bundles

Connection detail:

Connection: Acme Okta
├── Overview
├── SP details
├── IdP details
├── Certificates
├── Security
├── Attributes
├── Provisioning
├── Test
└── Audit

⸻

20. Component language

Status badges

Use sentence-case labels.

State	Label	Color
Draft	Draft	Graphite
Testing	Testing	Relay Blue
Enabled	Enabled	Success
Disabled	Disabled	Muted
Error	Error	Error
Expiring	Certificate expiring	Warning
Unsafe	Unsafe option enabled	Warning
Stale	Metadata stale	Warning

Validation trace labels

Use exact verbs:

* Received
* Decoded
* Parsed
* Matched
* Verified
* Validated
* Checked
* Rejected
* Mapped
* Established

Avoid vague verbs:

* Processed
* Handled
* Did
* Completed

Form action labels

Good:

* Import metadata
* Download SP metadata
* Test connection
* Enable connection
* Add certificate
* Rotate certificate
* Save security settings
* Preview attributes
* Create mapping

Bad:

* Submit
* Go
* Continue
* Confirm
* OK

⸻

21. Code and developer experience brand

Relyra’s API should feel like the brand:

* explicit,
* typed,
* behaviour-driven,
* safe by default.

Module naming

Recommended package family:

relyra
relyra_core
relyra_plug
relyra_phoenix
relyra_ecto
relyra_live_admin
relyra_test_support

Recommended modules:

Relyra
Relyra.SAML
Relyra.Connection
Relyra.Principal
Relyra.Assertion
Relyra.Metadata
Relyra.Security
Relyra.Security.Signature
Relyra.Security.AlgorithmPolicy
Relyra.Phoenix.Router
Relyra.Ecto
Relyra.LiveAdmin
Relyra.TestSupport

API naming principles

Use:

start_login
consume_response
validate_signature
validate_conditions
reject_replay
map_principal
establish_session
import_metadata
generate_sp_metadata
refresh_metadata
rotate_certificate
test_connection

Avoid:

do_saml
handle
process
magic_login
parse_everything

Code examples

Code examples should be complete enough to run. Avoid pseudo-config unless explicitly marked.

Preferred style:

defmodule MyAppWeb.SAMLSession do
  @behaviour Relyra.SessionAdapter
  def sign_in(conn, principal, user: user, connection: connection) do
    conn =
      conn
      |> Phoenix.Controller.put_flash(:info, "Signed in with #{connection.display_name}")
      |> MyAppWeb.UserAuth.log_in_user(user)
    {:ok, conn}
  end
end

⸻

22. Security language

Security claims

Use claims Relyra can actually prove.

Good:

* “strict defaults”
* “rejects unsigned assertions by default”
* “requires replay protection in production”
* “verifies signatures against configured IdP certificates”
* “emits validation traces”
* “supports certificate rollover”

Avoid:

* “unhackable”
* “bulletproof”
* “military-grade”
* “zero-risk”
* “guaranteed secure”
* “perfect SAML”
* “complete SAML security”

Security pages

Relyra should have first-class pages for:

* Security model
* Threat model
* Safe defaults
* Unsafe compatibility options
* CVE/test corpus
* Disclosure policy
* Supported versions
* Dependency policy

Security copy example

Relyra does not trust SAML input because it arrived from a known endpoint. A response becomes usable only after Relyra verifies the signature, binds it to the configured connection, validates protocol conditions, checks replay state, and maps the principal through application-defined callbacks.

⸻

23. Open-source community voice

Project governance voice

Relyra should be warm but firm.

Good:

Thanks for the report. Because this may affect authentication safety, please send details through the private security advisory process rather than opening a public issue.

Good:

We are open to supporting this IdP behavior behind an explicit compatibility option. We will not make it the default because it weakens validation for everyone.

Bad:

That IdP is broken. Won’t fix.

README badges

Use restrained badges:

* Hex version
* CI
* License
* Security policy
* Docs
* OpenSSF Scorecard if applicable

Avoid badge walls.

Community principles

* Security issues get private handling.
* Unsafe defaults are not accepted for convenience.
* Provider-specific fixes should come with fixtures.
* New features should improve operability, not just pass one IdP.
* Docs are part of the product.

⸻

24. Brand do/don’t summary

Do

* Use Relyra title case.
* Anchor the story in relying party, verified path, and operational SAML.
* Use calm technical colors.
* Use precise copy.
* Show validation traces.
* Show diagrams.
* Show real Phoenix code.
* Explain tradeoffs.
* Design for accessibility.
* Make unsafe options visible.
* Keep the brand OSS-serious.

Don’t

* Use reLyra.
* Use lyre/music/constellation imagery.
* Use shields, locks, keys, or hacker imagery as core identity.
* Sound like a commercial identity platform.
* Promise SAML is easy in a misleading way.
* Hide protocol terms.
* Use vague errors.
* Use red as a dominant brand color.
* Use neon cyber gradients.
* Use “magic,” “bulletproof,” or “military-grade.”

⸻

25. Brand sample: homepage hero

Enterprise SAML, calmly verified.
Relyra is an open-source SAML Service Provider system for Elixir and Phoenix. It gives SaaS teams strict validation, multi-tenant SSO configuration, provider presets, telemetry, and admin workflows for operating enterprise login safely.
[Get started] [Read the security model]

Supporting proof cards:

Strict by default
Relyra rejects unsafe SAML responses unless you explicitly opt into a documented compatibility mode.
Phoenix-native
Routes, plugs, behaviours, telemetry, Ecto, and LiveView admin workflows designed for real Phoenix apps.
Operable SSO
Certificate expiry, metadata refresh, validation traces, audit events, and debug bundles for production support.

⸻

26. Brand sample: docs intro

# Add SAML SSO to Phoenix with Relyra
This guide adds a SAML connection to a Phoenix application using Relyra’s strict defaults.
You will configure:
- SP metadata
- an IdP metadata source
- request and replay stores
- a session adapter
- a connection resolver
- a test login
By the end, your app will be able to start SP-initiated SAML login, consume a signed response, validate protocol conditions, reject replay, map a principal, and establish a Phoenix session.

⸻

27. Brand sample: UI validation failure

Assertion rejected
Relyra verified the signature, but the assertion was not issued for this Service Provider.
Expected Audience:
https://app.example.com/sso/acme/metadata
Received Audience:
https://acme.example.com/saml/metadata
How to fix:
In your identity provider, update the Audience URI / SP Entity ID to match the expected value above.
Error code:
:invalid_audience

⸻

28. Brand sample: unsafe setting warning

Unsafe compatibility setting
This connection allows IdP-initiated SSO.
Risk:
The Service Provider cannot verify a request ID for this flow because the login was not started by Relyra.
Required safeguards:
• Replay detection
• Explicit connection binding
• RelayState allowlist or server-side RelayState
• Audit logging
Use this only when your customer requires IdP dashboard launch.

⸻

29. Designer brief

Use this when briefing a human designer:

Relyra is an open-source SAML Service Provider library for Elixir/Phoenix. The brand should feel calm, exact, technical, and trustworthy. It should not look like a generic cybersecurity vendor or a SaaS identity platform. The central visual metaphor is “the verified trust path”: a SAML assertion travels through explicit checkpoints before becoming a Phoenix session. Explore a custom R monogram, assertion-frame icon, or trust-path mark. Avoid shields, locks, keys, hackers, flames, birds, music, and constellation imagery. Use a restrained palette: Ink, Paper, Relay Blue, Proof Teal, and small Violet/Amber accents. Typography should prioritize legibility and developer credibility. The final system must work for GitHub, Hex, docs, product UI, diagrams, and a self-service SAML admin interface.

⸻

30. LLM context block

Paste this into future AI design/copy/code sessions:

Relyra is an open-source SAML 2.0 Service Provider system for Elixir/Phoenix. Its audience is Phoenix SaaS teams that need secure enterprise SSO without becoming SAML experts. The brand idea is “the verified trust path”: Relyra receives hostile SAML input, parses it safely, verifies signatures, validates issuer/audience/recipient/destination/time conditions, rejects replay, maps a principal, and establishes a Phoenix session.
Brand personality: calm, exact, transparent, operator-friendly, open-source serious. Never hype. Never say SAML is magic or trivial. Do not use cyberpunk, hacker, lock, shield, key, flame, bird, music, lyre, or constellation imagery. Do not style the name as reLyra. Use Relyra title case.
Core tagline: “Enterprise SAML, calmly verified.”
Visual direction: restrained technical design, protocol diagrams, verified nodes, assertion frames, trust paths, precise cards, generous whitespace. Primary colors: Ink #101827, Paper #FCFBF7, Mist #EEF2F6, Relay Blue #3454D1, Deep Relay #1D2E82, Proof Teal #147D77, Keyline Violet #6D5DF2, Warning #B45309, Error #B42318, Success #027A48. Typography: IBM Plex Sans/Condensed for display, Atkinson Hyperlegible for UI/docs body, JetBrains Mono for code.
Voice: explain what happened, why it matters, and what to do next. Prefer exact protocol terms: SAML connection, IdP, SP, relying party, assertion, response, metadata, ACS URL, Entity ID, signing certificate, validation trace, replay cache, RelayState. Avoid vague copy like “Invalid SAML.” Use specific errors like “Relyra rejected this response because the assertion signature could not be verified with any trusted certificate for this connection.”
Relyra should look and sound like a well-maintained OSS security library: strict defaults, explicit unsafe compatibility, clear docs, validation traces, telemetry, audit events, provider presets, and production runbooks.

⸻

31. Final creative north star

Relyra should feel like the library you choose when the enterprise customer says:

“We require SAML before procurement can continue.”

And the Phoenix engineer thinks:

“I need this working safely, explainably, and without a support nightmare.”

The brand answer is:

Relyra — Enterprise SAML, calmly verified.