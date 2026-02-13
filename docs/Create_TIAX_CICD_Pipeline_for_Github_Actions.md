# Creating a CI/CD Pipeline for TIAX Library tetsing and release using GitHub Actions

This documentation provides a step-by-step guide to create a CI/CD pipeline for a library used in automation programming. The library can be used in TIA Portal or Simatic AX. The pipeline is defined using GitHub Actions.

## Prerequisites

- A GitHub repository containing your TIAX library code.
- GitHub Actions enabled for your repository.
- Secrets configured in your GitHub repository:
  - `AXTOKEN`: Token for Apax login. It must be created in the [tokens settings page](https://console.simatic-ax.siemens.io/settings/tokens) of an active account.
  - `CICDTOKEN`: GitHub token for publishing packages. It must be linked to an account with the appropiate permissions to publish and release packages in the selected locations.
- A self-hosted runner configured for your repository. For detailed instructions on setting up a self-hosted runner, refer to the [Setting Up a GitHub Self-Hosted Runner for TIAX test and release on Windows VM](Create_TIAX_CICD_Self-Hosted_Runner.md) documentation.

## Pipeline Overview

The pipeline consists of the following jobs:
1. **Compile**: Checks out the code, logs into Apax, installs dependencies, builds the project, and saves build artifacts.
2. **Test**: Checks out the code, installs dependencies, builds the project, runs tests, and saves test results.
3. **Semantic Version**: Reads the version from the `VERSION` file and outputs it for use in the release jobs.
4. **Package Release**: Downloads build artifacts, sets the version, packages the release, and publishes to GitHub Packages.
5. **TIA Library Release**: Downloads build artifacts, creates a TIA library, creates a release package, and creates a GitHub release.

## Pipeline Configuration

Create a file named `main.yml` in the `.github/workflows` directory of your repository with the following content:

### 1. Compile Job

This job checks out the code, logs into Apax, installs dependencies, builds the project, and saves build artifacts.

```yaml
jobs:
  compile:
    runs-on: TIAX19
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Login to Apax
        run: apax login -p "${{ secrets.AXTOKEN }}"

      - name: Install dependencies
        run: apax install

      - name: Build
        run: apax build

      - name: Save build artifacts
        uses: actions/upload-artifact@v4
        with:
          name: ax_tia_build_artifacts
          path: ./bin/1500
```

### 2. Test Job

This job checks out the code, installs dependencies, builds the project, runs tests, and saves test results.

```yaml
  test:
    runs-on: TIAX19
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Login to Apax
        run: apax login -p "${{ secrets.AXTOKEN }}"

      - name: Install dependencies
        run: apax install

      - name: Build
        run: apax build

      - name: Run tests
        run: apax test

      - name: Save test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: bin/axunit-artifacts/test-results/TestResult.xml
```

### 3. Semantic Version Job

This job reads the version from the `VERSION` file and outputs it for use in the release jobs.

```yaml
 semantic-version:
    needs: [compile, test]
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.get_version.outputs.version }}
    steps:
      - uses: actions/checkout@v4

      - name: Read Version
        id: get_version
        run: |
          echo "version=$(cat VERSION)" >> $GITHUB_OUTPUT

      - name: Display Version
        run: echo "Using version ${{ steps.get_version.outputs.version }}"
```

### 4. SIMATIC AX Package Release Job

This job downloads build artifacts, sets the version, packages the release, and publishes to GitHub Packages.

If you need a walkthrough guide on how to publish packages in AX, see our [public documentation on github](https://github.com/simatic-ax/standardizer-tutorial-lib/blob/main/doc/publishing-lib.md)

```yaml
   package-release:
    needs: [semantic-version, compile, test]
    runs-on: TIAX19
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Download build artifacts
        uses: actions/download-artifact@v4
        with:
          name: ax_tia_build_artifacts
          path: ./bin/1500

      - name: Login to Apax
        run: apax login -p "${{ secrets.AXTOKEN }}"

      - name: Set Versioning
        run: |
          apax version "${{ needs.semantic-version.outputs.version }}"

      - name: Pack Apax Package
        run: apax pack

      - name: Publish to GitHub Packages
        run: |
          $package = Get-ChildItem -Path *.tgz | Select-Object -First 1          
          apax config set token "${{ secrets.CICDTOKEN }}" --registry "https://npm.pkg.github.com"
          apax publish --package "$package" --tag "v${{ needs.semantic-version.outputs.version }}" --registry "https://npm.pkg.github.com"
```

### 5. TIA Library Release Job

This job downloads build artifacts, creates a TIA library, creates a release package, and creates a GitHub release with the Library for TIA Portal 19.

```yaml
  tia-library-release:
    needs: [semantic-version, compile, test]
    runs-on: TIAX19
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Download build artifacts
        uses: actions/download-artifact@v4
        with:
          name: ax_tia_build_artifacts
          path: ./bin/1500
          
      - name: Login to Apax
        run: apax login -p "${{ secrets.AXTOKEN }}"

      - name: Install dependencies
        run: apax install
        
      - name: Create TIA Library
        run: |
          $libFile = Get-ChildItem -Path ./bin/1500 -Filter *.lib | Select-Object -First 1
          apax ax2tia -i $libFile.FullName -o ".\\bin\\handover-folder"
          & "$env:TIA_LIB_IMPORTER_PATH_19" -i ".\\bin\\handover-folder" -o ".\\lstream-tiax" -u

      - name: Create Release Package
        run: |
          Compress-Archive -Path ".\\lstream-tiax" -DestinationPath "${{ github.event.repository.name }}_tia_release-v${{ needs.semantic-version.outputs.version }}.zip"

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v1        
        with:
          files: |
            ${{ github.event.repository.name }}_tia_release-v${{ needs.semantic-version.outputs.version }}.zip
          tag_name: v${{ needs.semantic-version.outputs.version }}
          generate_release_notes: true
          draft: false
          prerelease: false
        env:
          GITHUB_TOKEN: ${{ secrets.CICDTOKEN }}
```