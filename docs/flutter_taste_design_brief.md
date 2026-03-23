# Flutter Taste Design Brief

## Purpose

This document adapts the installed `taste-skill` into a Flutter-native design system for the badminton tournament scheduler app. It keeps the skill's useful constraints:

- avoid generic dashboard UI
- use strong typography and disciplined color
- reduce card spam
- design all loading, empty, and error states intentionally
- keep motion subtle and purposeful

It drops the React-, Tailwind-, and Framer-specific parts.

## Product Fit

This app is an operations tool first. It needs personality, but not visual chaos. Tournament staff must be able to scan the UI under time pressure.

Use these baseline dials for this product:

- `DESIGN_VARIANCE = 4`
- `MOTION_INTENSITY = 2`
- `VISUAL_DENSITY = 4`

Interpretation:

- layouts should feel calm and ordered, not rigid
- motion should stay almost invisible and only confirm state change
- the interface should feel airy, with room around important controls

## Visual Direction

### Tone

Use a calm spring operations aesthetic:

- airy pastel surfaces
- soft botanical color accents
- no neon
- no purple bias
- no glassy effects on core work surfaces
- no oversized marketing-style headings inside scheduler views
- the UI should feel light in weight, soft in contrast, and easy to scan

### Recommended Palette

- Background: warm ivory with a hint of blush
- Surface: soft cream or petal white
- Primary accent: pastel sage or mint
- Secondary accent: muted blossom pink, used sparingly
- Warning: soft daffodil
- Error: dusty coral
- Success: leaf green, softer than the primary action color

The palette should feel seasonal and fresh, but the app still needs one dominant action color. Do not turn every state into a bright pastel sticker set.

## Typography

### Font Direction

Avoid `Inter`.

Recommended Flutter-friendly pairings:

- `Plus Jakarta Sans` + `JetBrains Mono`
- `Outfit` + `IBM Plex Mono`
- `Manrope` + `IBM Plex Mono`

Use the sans family for UI and the mono family only for:

- scores
- court codes
- seeds
- sequence numbers
- standings stats

### Type Rules

- dashboard page titles: light-to-medium weight, compact, left-aligned
- section titles: restrained, not oversized
- labels above inputs, never floating as the only context
- tabular figures for scores and rankings
- body copy should stay short and operational
- avoid heavy black text except for the most important headings

## Layout Rules

### Global

- prefer a clear shell with a left rail or top navigation and a stable content width
- desktop layouts should feel anchored, not stretched edge to edge
- mobile must collapse aggressively into one column
- use whitespace and dividers before adding extra containers
- give sections more breathing room than a dense admin dashboard would

### Anti-Card Rule

Do not put every metric and every row into separate elevated cards.

Use cards only when one of these is true:

- the content is actionable and needs a soft container
- the content is modal or temporary
- the content must visually detach from a noisy background

Prefer these patterns for dense screens:

- section headers with divider lines
- grouped list surfaces
- split panes
- bordered rows with generous padding
- sticky summary bars
- soft tonal panels instead of hard outlined boxes when clarity is preserved

### Screen-Specific Guidance

#### Scheduler Board

- treat this as the most functional screen
- keep it lighter than a typical ops board, but do not sacrifice scan speed
- emphasize queue, court state, and conflict state
- current match and blocked match states must be instantly distinguishable

#### Score Approval

- use a review-workbench layout
- proposed score, match metadata, and decision controls should read top-to-bottom without visual clutter
- rejected or invalid submissions need inline explanation, not toast-only feedback

#### Public View

- can be more open and airy than admin screens
- should still keep the same palette and typography
- court board and standings should be readable from a distance

## Motion Rules

Use Flutter implicit animations and route transitions sparingly.

Allowed motion:

- `AnimatedSwitcher` for state changes
- `AnimatedContainer` for selection and status transitions
- subtle slide/fade for drawers, sheets, and approval states
- restrained pulse only for truly live objects, such as a match in progress
- very soft scale changes on press for buttons and tappable tiles

Avoid:

- perpetual animations on every tile
- parallax
- liquid glass
- busy hover choreography on operational screens

Timing guidance:

- quick feedback: `120ms` to `160ms`
- standard transition: `180ms` to `240ms`
- emphasized transition: `280ms`

Animate only `opacity`, `transform`, color, and elevation. Do not animate layout unpredictably on dense screens.

## Component Principles

### Buttons

- primary button uses the single accent color, but in a pastel treatment
- destructive button should not compete with primary actions
- pressed state should feel tactile through scale or shadow reduction

### Inputs

- labels always above fields
- helper text should be present when ambiguity exists
- error text lives below the field
- avoid overly rounded "pill" inputs for dense admin flows

### Chips and Badges

- use chips for status and filters
- use muted fills, not saturated badges everywhere
- court and match states must be color-safe and readable without color alone
- prefer tonal badges over outlined pills unless density demands otherwise

### Tables and Lists

- row height should stay compact but breathable
- use dividers and alignment instead of heavy boxing
- numeric columns should use monospaced tabular styles

### Empty, Loading, Error States

Every major surface must define all three:

- loading: skeletons that resemble the final layout
- empty: explain why nothing is shown and what action is available
- error: inline recovery path, not just a snackbar
- skeletons should be soft and low-contrast, not shiny or metallic

## Flutter Implementation Guidance

### Theme Structure

Create:

- one central `ThemeData`
- one small token layer for colors, spacing, radii, and motion durations
- a handful of reusable surface widgets for:
  - section container
  - elevated action panel
  - status chip
  - skeleton block

### Material 3

Use Material 3 as the base, but override the defaults heavily enough that the app does not look stock:

- custom color scheme
- custom text scale and weights
- custom input decoration theme
- custom button themes
- custom divider density

### Responsiveness

Define breakpoints deliberately:

- phone: single-column
- tablet: two-pane where useful
- desktop/web: scheduler-specific multi-pane layouts

Do not let wide web screens become empty oceans. Constrain content and anchor important surfaces.

## Do Not Do

- no purple gradients
- no glowing blue CTAs
- no generic three-card hero rows
- no default Material look
- no card-per-item dashboards
- no oversized rounded pills everywhere
- no decorative motion on core operations screens
- no harsh black-on-white contrast everywhere

## First Components To Build

Build these first and use them to set the visual language:

1. app shell with navigation
2. section header and grouped surface
3. status chip system
4. scheduler queue item
5. court tile
6. score approval card
7. standings table row
8. loading skeleton kit

## Translation From The Original Skill

What we keep:

- anti-generic design bias
- typography discipline
- one-dominant-accent discipline with a few supporting spring tones
- anti-card-overuse
- proper state design
- performance-minded motion

What we change:

- React and Next.js rules become Flutter widget architecture rules
- Tailwind rules become token and component rules
- Framer Motion rules become restrained Flutter animations
- premium marketing motion becomes operational clarity with a softer spring palette
