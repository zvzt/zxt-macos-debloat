# Security

ZXT changes launchd override state and can optionally change Spotlight indexing. Review the source and use `zxt apply --dry-run` before applying changes if you want to inspect the selected targets first.

## Reporting a problem

For bugs or potentially unsafe service selections, open a GitHub issue with:

- macOS version
- Mac model / architecture
- selected ZXT profile
- output of `zxt doctor`
- the service or command involved

Do not post passwords, tokens, private keys, or other secrets in issues.
