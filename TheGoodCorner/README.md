# iOS-Test-Rendu
Rendu de test technique iOS - WEVIOO
 
 
# Reflection

> This document is initiated before development to frame the project and serves as a
> reference throughout the working sessions with the AI. The sections will be
> enriched over the course of the following commits (real feedback, decisions
> made along the way, concrete examples of AI usage).

## Project Context

iOS application (Swift/SwiftUI) displaying listings from a local API
(`server/`,  `http://localhost:8080`). The complete API contract is described in
`server/swagger.yaml`.

Goal of the exercise: demonstrate product judgment on a deliberately
narrow scope, a testable architecture, good accessibility, and the ability to handle
the gray areas of the brief/API in a reasoned way rather than by blocking.

## Retained Scope

### Base requirements (mandatory)
- List screen: image, category, title, price, urgency mention if applicable
- API order preserved (urgent first, then most recent)
- Filter by category
- Graceful handling of missing/failed images
- Detail screen on tap of a listing
- Visible states: loading / recoverable error / intentional empty
- Accessibility: labels on interactive elements, images labeled or decorative,
  Dynamic Type respected
- 3 to 5 deterministic automated tests (without depending on the local server)

### Retained "extra work" option
*(to be specified once the base scope is validated — a single option will be implemented
in depth, in accordance with the instructions)*

### Technical constraints to be strictly respected
- Swift + SwiftUI, no storyboard/xib
- No external libraries (only `URLSession`, Foundation, SwiftUI)
- iOS 16+ target
- Execution in simulator (direct localhost, no special network configuration required)
- `server/` unmodified
- Progressive Git history, no single commit

## Target Architecture

**Retained pattern: MVVM (Model-View-ViewModel)**, native to SwiftUI, chosen for its
testability (ViewModel independent of the UI) and its consistency with SwiftUI's
reactive binding (`@Published`, `ObservableObject`).

- **Model** (`Models/`): `Decodable` structures faithful to the observed contract
  (Product, `Category`, ProductsResponse), without UI/network dependency. Responsible
  solely for representing the data.

- **ViewModel** (`ViewModels/`): `ObservableObject` `@MainActor`, serves
  as intermediary between the Model and the View. Exposes an explicit state
  (`idle/loading/loaded/empty/failed`) and a computed property for filtering by
  category (instant filter change, with a new network call). Contains
  no `SwiftUI`/`UIKit` import, which guarantees its testability independently of
  the interface.

- **View** (`Views/`): pure SwiftUI — list screen, filter bar, detail screen,
  remote image component with fallback. Observes the ViewModel via `@StateObject`/
  `@ObservedObject` and merely displays the state, without business logic.

- **Networking** (cross-cutting layer consumed by the ViewModel):
  `APIClientProtocol` + exclusive `URLSession` implementation (no external
  library), injectable for tests without depending on the local server.

- **Tests**: targeted at JSON decoding (Model), URL/request construction
  (Networking).

- **Accessibility**: taken into account at the View level from the design stage (labels
  on interactive elements, distinction between decorative/informative images, respect for
  Dynamic Type), and not added after the fact.

This plan may evolve once development begins; any deviation from this
MVVM pattern will be documented below at the moment it occurs.

## Assumptions

Assumptions formulated from the brief and from two real examples of `GET /listings`
responses inspected before development.

- **Base URL**: `http://localhost:8080` by default for the simulator, made
  configurable (injectable constant) so as not to hard-code the coupling, in
  anticipation of possible use on a physical device.
- **Price**: confirmed as an integer without decimals (`price: Int`, observed values
  from `5` to `35000`), with no separate currency field in the JSON. Assumption retained:
  price in whole euros, formatted via `NumberFormatter` (`currencyCode = "EUR"`,
  `maximumFractionDigits = 0`).
- **Urgency field (`is_urgent`)**: confirmed explicitly present as `Bool` on both
  observed examples, both `true` and `false`. Defensive decoding
  (`decodeIfPresent` with default value `false`) is nevertheless retained as a precaution,
  in case the field is omitted on other listings in the dataset not
  observed — this choice has no cost and secures decoding without assuming a
  guarantee not documented in the swagger.
- **Images (`images_url`)**: confirmed as an object with two keys `thumb` and
  `small` (relative paths, e.g. `/images/ad-thumb/...` and `/images/ad-small/...`),
  present in all observed examples. As a precaution, `images_url` as well as
  each of its fields are modeled as optional, with a placeholder displayed
  if the object or both fields are absent.
- **Creation date**: ISO 8601 format with `Z` suffix (e.g.
  `2019-11-06T11:22:35Z`), decodable via the `.iso8601` strategy of `JSONDecoder`.
- **Category**: only `category_id` (Int) is present in `/listings`, which confirms
  the need for a separate call to `/categories` to resolve the displayed name.
  Both calls will be made in parallel at load time.
- **Description**: text field of highly variable length (observed from a few words to
  several hundred words). Product decision: truncated display on the list
  (e.g. `lineLimit(2)`) to preserve readability, full scrollable text on
  the detail screen, with respect for Dynamic Type.
- **List envelope**: structure confirmed consistent with the brief — `total`,
  `has_more`, `limit`, `items`, `page` at the same root level. Consistency between
  `page`, `limit`, and `total` was verified on the observed examples.
- **Category filter**: applied client-side on the set of already
  retrieved listings, as the brief does not explicitly require server-side filtering
  for the base requirements.
- **`server/` folder**: treated as a read-only external dependency, not
  modified in the submission, in accordance with the instructions.

## AI Usage

- **Tool**: Claude Sonnet 4.5, used as development assistance (code scaffolding,
  review, architecture suggestions) under direct supervision.
- Structural decisions (architecture choice, arbitration on ambiguities,
  retained scope) remain my responsibility; the AI is used as an
  execution accelerator, not as a decision-maker.
- *Rejected/corrected AI suggestion*: to be documented here with a concrete example as of the
  first assisted development sessions (no code has yet been produced with
  the AI at the time of this initial commit).

## Ambiguities Encountered and Arbitrations

| Ambiguity | Origin | Retained Arbitration |
|---|---|---|
| Visual style of the urgency mention not specified ("if applicable") | Brief | Distinct visual badge (colored capsule + icon) rather than color alone, with explicit VoiceOver label ("Urgent listing") |
| Behavior of `/listings` without `page`/`limit` parameters | Brief + swagger | Assumption: equivalent to a default first page; to be confirmed in practice |
| `is_urgent` could be omitted for certain unobserved listings | Two available API examples show the field always present | Defensive decoding retained as a precaution (`decodeIfPresent` + default `false`) |
| `images_url` could be entirely absent for certain listings | Not observed in the provided examples | Modeled as optional, with placeholder if `nil` |
| Native `ContentUnavailableView` requires iOS 17, project target = iOS 16+ | SwiftUI technical constraint vs. deployment target | Custom fallback view with the same visual intent, rather than raising the deployment target |
| Highly variable description length (up to several hundred words) | Real API examples | Truncation on the list (`lineLimit(2)`), full scrollable display on the detail screen |

These arbitrations will be confirmed, refined, or revised in the following commits, as
development progresses.
