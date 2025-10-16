# Framework Download Artifact

Download and extract artifact from a workflow run.

## Usage

```yaml
- uses: openDAQ/openDAQ/.github/actions/framework-download-artifact@main
  with:
    # GitHub workflow run ID
    # Required
    run-id: ''

    # Name of the artifact to download (supports glob patterns)
    # Required
    artifact-name: ''

    # Specific file name to extract from the artifact (supports glob patterns)
    # Required
    artifact-filename: ''

    # Output directory for extracted artifact (default: runner temp)
    # Optional
    output-dir: ''

    # GitHub token (required for cross-repo access)
    # Optional
    token: ''

    # Number of retry attempts on failure
    # Optional, default: 3
    retry-attempts: '3'

    # Enables verbose logging output
    # Optional, default: false
    verbose: false
```

## Outputs

```yaml
outputs:
  artifact:          # Path to the downloaded and extracted artifact
  artifact-dir:      # Path to the downloaded and extracted artifact directory
  artifact-filename: # Path to the downloaded and extracted artifact
  artifact-filesize: # Size of the downloaded artifact in bytes
  artifact-checksum: # Checksum of the downloaded artifact
```

## Examples

### Download latest build artifact

```yaml
- uses: openDAQ/openDAQ/.github/actions/framework-download-artifact@main
  id: download
  with:
    run-id: ${{ github.event.workflow_run.id }}
    artifact-name: 'opendaq-*-ubuntu22.04-x86_64'
    artifact-filename: 'opendaq-v3.30.0-ubuntu22.04-x86_64.deb'
```

### Download with custom output directory

```yaml
- uses: openDAQ/openDAQ/.github/actions/framework-download-artifact@main
  id: download
  with:
    run-id: '12345678'
    artifact-name: 'opendaq-*-macos14-arm64'
    artifact-filename: 'opendaq-v3.30.0-macos14-arm64.tar.gz'
    output-dir: './artifacts'
```

### Download from another repository

```yaml
- uses: openDAQ/openDAQ/.github/actions/framework-download-artifact@main
  id: download
  with:
    run-id: '87654321'
    artifact-name: 'opendaq-*-win64'
    artifact-filename: 'opendaq-v3.29.0-rc-win64.exe'
    token: ${{ secrets.PAT_TOKEN }}
    retry-attempts: '5'
```

### Use downloaded artifact

```yaml
- uses: openDAQ/openDAQ/.github/actions/framework-download-artifact@main
  id: download
  with:
    run-id: ${{ github.event.workflow_run.id }}
    artifact-name: 'opendaq-*-debian12-x86_64'
    artifact-filename: 'opendaq-v3.30.0-a1b2c3d-debian12-x86_64.deb'

- name: Install package
  run: |
    sudo dpkg -i ${{ steps.download.outputs.artifact }}
    echo "Installed $(dpkg -l | grep opendaq)"
```

## See Also
- [README.md](./../README.md) - Actions overview
