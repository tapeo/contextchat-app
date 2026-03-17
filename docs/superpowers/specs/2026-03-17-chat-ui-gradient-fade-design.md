# Gradient Fade Enhancement - Design Document

**Date:** 2026-03-17  
**Topic:** chat-ui-gradient-fade  

## Summary

Enhance the message list in `lib/chat/chat.ui.dart` with softer, more gradual gradient overlays at the top and bottom edges to create a polished visual experience.

## Current State

The chat UI currently has gradient overlays:
- Top: 24px height
- Bottom: 32px height

These gradients prevent messages from appearing to clip harshly against the container edges.

## Proposed Changes

### Visual Enhancement

Increase gradient heights for a more gradual, premium fade effect:

- **Top gradient:** 24px → **48px**
- **Bottom gradient:** 32px → **64px**

### Technical Implementation

The gradients are implemented using:
- `Stack` with `Positioned` gradient containers overlaying the scroll view
- `LinearGradient` from `scaffoldBackgroundColor` to transparent
- `IgnorePointer` widget to ensure scroll/gestures pass through
- Theme-aware colors that adapt to light/dark mode automatically

Only the `height` parameter values need modification.

## Acceptance Criteria

- [ ] Top gradient height is 48px
- [ ] Bottom gradient height is 64px  
- [ ] Gradients remain theme-aware (light/dark)
- [ ] Scroll interaction remains unaffected
- [ ] Visual fade appears softer and more gradual

## Files Modified

- `lib/chat/chat.ui.dart` - Update gradient height constants
