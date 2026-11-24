---
'html-to-document-adapter-docx': minor
'html-to-document-core': patch
---

Write the background of a `<mark>` as a Word highlight when its colour is one of Word's 16 highlight colours and fully opaque, such as the default `yellow`. The text inside the mark is highlighted too, even in nested inline elements such as `<strong>` or links, unless an element sets its own background. Other backgrounds are still written as shading.

`colorConversion` now parses any CSS colour, such as `hsl()`, `lab()` or `oklch()`.
