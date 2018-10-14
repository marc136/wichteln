/**
 * JSON Schema definitions shared among multiple files
 * http://json-schema.org/latest/json-schema-validation.html#rfc.toc
 *
 */

const string = { type: 'string' }
const date = { ...string, pattern: '^\\d{4}-\\d{2}-\\d{2}$' }

module.exports = { string, date }
