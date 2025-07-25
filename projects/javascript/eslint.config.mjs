// eslint.config.mjs
import js from '@eslint/js';
import security from 'eslint-plugin-security';
import securityNode from 'eslint-plugin-security-node';
import noSecrets from 'eslint-plugin-no-secrets';
import promise from 'eslint-plugin-promise';
import ts from '@typescript-eslint/eslint-plugin';

export default [
  // Base configuration
  {
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: {
        node: true,
        browser: true,
      },
    },
  },

  // Core ESLint rules
  js.configs.recommended,

  // Security plugins
  {
    plugins: {
      security,
      'security-node': securityNode,
      'no-secrets': noSecrets,
      promise,
    },
    rules: {
      // ===========================================
      // 1. CRITICAL SECURITY RISKS (ERROR)
      // ===========================================

      // Code injection
      'no-eval': 'error',
      'no-implied-eval': 'error',
      'security/detect-eval-with-expression': 'error',
      'security/detect-new-buffer': 'error',
      'security/detect-non-literal-fs-filename': 'error',
      'security/detect-non-literal-regexp': 'error',
      'security/detect-non-literal-require': 'error',
      'security/detect-child-process': 'error',
      'security/detect-object-injection': 'error',

      // Data leaks
      'no-secrets/no-secrets': ['error', { tolerance: 4.0 }],

      // Timing attacks
      'security/detect-possible-timing-attacks': 'error',

      // ===========================================
      // 2. DANGEROUS PRACTICES (WARN)
      // ===========================================
      'security/detect-disable-mustache-escape': 'warn',
      'security/detect-buffer-noassert': 'warn',
      'security/detect-pseudoRandomBytes': 'warn',

      // ===========================================
      // 3. CODE QUALITY (ERROR)
      // ===========================================
      'promise/always-return': 'error',
      'promise/no-return-wrap': 'error',
      'promise/param-names': 'error',
      'promise/catch-or-return': 'error',

      // Additional security rules
      'no-octal': 'error',
      'no-delete-var': 'error',
      'no-obj-calls': 'error',
      'no-redeclare': 'error',
      'no-undef': 'error',
      'no-unexpected-multiline': 'error',
      'no-unreachable': 'error',
      'no-unsafe-negation': 'error',
      'valid-typeof': 'error',
    },
  },

  // TypeScript configuration
  {
    files: ['**/*.ts', '**/*.tsx'],
    ...ts.configs['eslint-recommended'],
    ...ts.configs['recommended'],
    rules: {
      '@typescript-eslint/no-unsafe-assignment': 'error',
      '@typescript-eslint/no-unsafe-call': 'error',
      '@typescript-eslint/no-unsafe-member-access': 'error',
      '@typescript-eslint/no-unsafe-argument': 'error',
      '@typescript-eslint/no-unsafe-return': 'error',
      '@typescript-eslint/no-explicit-any': 'error',
      '@typescript-eslint/no-var-requires': 'error',
    },
  },

  // Ignored files
  {
    ignores: [
      '**/node_modules/**',
      '**/dist/**',
      '**/*.min.js',
      '**/coverage/**',
    ],
  },
];