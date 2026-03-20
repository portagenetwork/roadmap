import { defineConfig } from "eslint/config";
import globals from "globals";
import path from "node:path";
import { fileURLToPath } from "node:url";
import js from "@eslint/js";
import { FlatCompat } from "@eslint/eslintrc";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const compat = new FlatCompat({
    baseDirectory: __dirname,
    recommendedConfig: js.configs.recommended,
    allConfig: js.configs.all
});

export default defineConfig([{
    extends: compat.extends("airbnb-base"),

    languageOptions: {
        globals: {
            ...globals.browser,
            ...globals.jquery,
            ...globals.jasmine,
            timeago: true,
            fixture: true,
            spyOnEvent: true,
        },

        ecmaVersion: 2018,
        sourceType: "module",
    },

    rules: {
        "import/no-unresolved": "off",
        indent: ["error", 2],
        "linebreak-style": ["error", "unix"],
        quotes: ["error", "single"],
        semi: ["error", "always"],

        "prefer-destructuring": ["error", {
            array: false,
            object: false,
        }, {
            enforceForRenamedProperties: false,
        }],
    },
}]);