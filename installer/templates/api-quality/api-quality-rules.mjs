// Custom Redocly rules for API authoring quality.
// Template from civiltekk-opencode-claude-skills (#320).
//
// Redocly CLI 2.x plugin format: default export is a factory returning rule
// modules; each rule is a function returning { severity, <VisitorType>(node, ctx) }.
// This plugin restores `schema-description` and `operation-tags` checks (removed
// as builtins in 2.x) and adds the request-body-example check.
//
// Referenced from redocly.yaml as:
//   api-quality/schema-description: error
//   api-quality/operation-has-tags: warn
//   api-quality/request-body-example: warn   # promote to error once specs comply
export default function apiQuality() {
  return [
    {
      id: 'api-quality',
      rules: {
        oas3: {
          'schema-description': () => ({
            severity: 'error',
            Schema(node, { report, location }) {
              if (!node || typeof node !== 'object') return;
              if (node.description === undefined || node.description === '') {
                report({
                  message: 'Schema should include a description.',
                  location: location.key(),
                });
              }
            },
          }),
          'operation-has-tags': () => ({
            severity: 'warn',
            Operation(node, { report, location }) {
              if (!Array.isArray(node.tags) || node.tags.length === 0) {
                report({
                  message: 'Operation should declare at least one tag.',
                  location: location.key(),
                });
              }
            },
          }),
          'request-body-example': () => ({
            severity: 'warn',
            Operation(node, { report, location, key }) {
              const method = String(key || '').toLowerCase();
              if (method !== 'post' && method !== 'put') return;
              const rb = node.requestBody;
              if (!rb || typeof rb !== 'object') return;
              for (const mediaType of Object.values(rb.content || {})) {
                if (mediaType.example !== undefined || mediaType.examples !== undefined) return;
                const schema = mediaType.schema || {};
                if (schema.example !== undefined || schema.examples !== undefined) return;
              }
              report({
                message: `${method.toUpperCase()} request body should include an example or examples.`,
                location: location.key(),
              });
            },
          }),
        },
      },
    },
  ];
}
