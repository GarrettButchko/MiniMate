/** @type {import("eslint").Linter.FlatConfig[]} */
export default [
  {
    ignores: ["node_modules/**"],
  },
  {
    files: ["functions/**/*.js"],
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "module",
      globals: {
        require: "readonly",
        module: "readonly",
        exports: "readonly",
      },
    },
    rules: {
      indent: ["error", 2],
      "object-curly-spacing": ["error", "never"],
      quotes: ["error", "double"],
      "comma-dangle": ["error", "always-multiline"],
      "no-unused-vars": ["warn", { "argsIgnorePattern": "^_" }],
    },
  },
];
