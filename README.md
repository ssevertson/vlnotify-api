VLNotify-API
============

API server for VLNotify service

Configuration
-------------

`config/config.json` includes a number of placeholder values, including API keys and passwords. To specify your own values:

1. Edit the file directly (not preferred, as you may inadvertantly commit these back to GitHub)

2. Environment variables: use the variable's JSON path, separated by the '_' character. For example,
  `resourceful_auth_password='your password'`

3. Command-line arguments: use the variable's JSON path, separated by the '.' character. For example,
  '--resourcefl.auth.password='your password'
