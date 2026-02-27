/// Regex pattern for matching HTTP/HTTPS URLs in text content.
final urlPattern = RegExp(
  r'https?://[^\s<>"{}|\\^`\[\]]+',
  caseSensitive: false,
);
