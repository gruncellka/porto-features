'use strict'

/**
 * Entry point for @gruncellka/porto-features (npm).
 * Exports package version; feature files and fixtures live under porto_features/.
 */
const pkg = require('./package.json')
module.exports = { version: pkg.version }
