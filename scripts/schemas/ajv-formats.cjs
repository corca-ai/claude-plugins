"use strict";

const { URL } = require("url");

module.exports = function registerLocalFormats(ajv) {
  // Keep schema strictness by registering formats we use in local schemas.
  ajv.addFormat("uri", {
    type: "string",
    validate(value) {
      if (typeof value !== "string") {
        return false;
      }
      try {
        new URL(value);
        return true;
      } catch {
        return false;
      }
    }
  });
};
