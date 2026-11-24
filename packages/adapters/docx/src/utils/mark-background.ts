import type { DocumentElement } from 'html-to-document-core';
import type { ElementStylesheet } from '../element-converters/types';

/**
 * The metadata key on an element whose background is the one a `<mark>`
 * ancestor sets, so the style mapper can write it as a highlight, as it does
 * for the `<mark>` itself.
 */
export const markBackgroundMetadataKey = 'backgroundFromMark';

/** The background the element sets itself, rather than inherits, if any. */
const getOwnBackground = (
  element: DocumentElement,
  stylesheet: ElementStylesheet
): string | undefined => {
  const backgroundColor = stylesheet.getComputedStyles(
    element,
    {}
  ).backgroundColor;
  return backgroundColor == null ? undefined : String(backgroundColor);
};

const flagDescendant = (
  element: DocumentElement,
  stylesheet: ElementStylesheet,
  backgroundColor: string
): DocumentElement => {
  // Its own background, not the mark's, is the one behind it and its
  // descendants.
  if (getOwnBackground(element, stylesheet) !== undefined) return element;

  return {
    ...element,
    // Backgrounds don't cascade to inline elements, so it's given the mark's.
    styles: { ...element.styles, backgroundColor },
    metadata: { ...element.metadata, [markBackgroundMetadataKey]: true },
    ...(element.content && {
      content: element.content.map((child) =>
        flagDescendant(child, stylesheet, backgroundColor)
      ),
    }),
  };
};

/**
 * If the element is a `<mark>` that sets its own background, returns a copy
 * whose descendants have that background and are flagged with
 * {@link markBackgroundMetadataKey}, down to any that set their own
 * background. Otherwise returns the element as it is.
 */
export function flagMarkBackground(
  element: DocumentElement,
  stylesheet: ElementStylesheet
): DocumentElement {
  if (element.metadata?.tagName !== 'mark' || !element.content?.length) {
    return element;
  }

  const backgroundColor = getOwnBackground(element, stylesheet);
  if (backgroundColor === undefined) return element;

  return {
    ...element,
    content: element.content.map((child) =>
      flagDescendant(child, stylesheet, backgroundColor)
    ),
  };
}
