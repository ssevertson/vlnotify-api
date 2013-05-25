VLNotify-API
============

API server for VLNotify service

Configuration
-------------

`config/config.json` includes a number of placeholder values, including API keys and passwords. Either edit this file
to specify your own values, or specify these values as:
1. Environment variables: use the variable's JSON path, separated by the '_' character. For example,
  `resourceful_auth_password='your password'`
2. Command-line arguments: use the variable's JSON path, separated by the '.' character. For example,
  '--resourcefl.auth.password='your password'
