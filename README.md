# SwiftUI Truncation Detection

A SwiftUI demo exploring how to detect text truncation without any private APIs. Two invisible "ghost" copies of a Text view are measured under different constraints, and their sizes are compared against the visible text to determine whether it has wrapped, been truncated, or both.

## The Problem

SwiftUI's `Text` view does not expose whether its content was truncated. There is no built-in API to ask "did this text get cut off?"

## The Technique

Two invisible copies ("ghosts") of the same string are rendered alongside the visible text, each with a different layout constraint removed:

```
┌───────────────────────────────────────────────────────────────────────┐
│  Copy                 Constraint removed    What it tells us          │
│  ──────────────       ──────────────────    ──────────────────        │
│  visible              (none — fully          The actual rendered      │
│                        constrained)          size in the container    │
│                                                                       │
│  horizontalGhost      width is unlocked     "How wide would I be      │
│                       (height stays locked)  with no width limit?"    │
│                                              → single-line width      │
│                                                                       │
│  verticalGhost        height is unlocked    "How tall would I be      │
│                       (width stays locked)   with no height limit?"   │
│                                              → fully-wrapped height   │
└───────────────────────────────────────────────────────────────────────┘
```

By comparing those three sizes at runtime you can determine exactly what happened to the text:

| Condition | Meaning |
|---|---|
| `visibleSize.height > horizontalGhostSize.height` | Text has wrapped onto multiple lines |
| `visibleSize.height < verticalGhostSize.height` | Wrapped text is still truncated (lines cut off) |
| `visibleSize.width < horizontalGhostSize.width` | Single-line text is truncated (characters cut off) |

This approach is based on the technique described by Fatbobman [in this article](https://fatbobman.com/en/posts/how-to-detect-text-truncation-in-swiftui/)
and presented at [iOS Conference Singapore](https://www.youtube.com/watch?v=VPfxm8RHKFU).


## Project Structure

| File | Purpose |
|---|---|
| `TruncationDetectionView.swift` | Demo of the raw truncation detection measurements with labelled output. |
