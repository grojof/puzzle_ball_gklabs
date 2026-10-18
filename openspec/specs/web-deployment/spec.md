# web-deployment Specification

## Purpose
Defines how the web game is built, packaged and served from a self-hosted server: the container image, its web
server's behavior, and what may never be built into the public bundle.

## Requirements

### Requirement: Reproducible image built from the repository
The repository SHALL contain everything needed to build a container image of the web game from a clean checkout of
`main`, with the Flutter SDK version the project uses and base images pinned by digest, without pulling any
prebuilt image of the game from a registry.

#### Scenario: Building on the server
- **WHEN** the deployment server builds the repository's Dockerfile from a clean clone of `main`
- **THEN** it produces an image that serves the production web build, with no image of the game pulled from any
  registry

### Requirement: Served as a single-page app
The image SHALL serve the web build without root privileges on port 8080, route every unknown path to the app's
entry page, and make browsers revalidate every file so a redeploy takes effect on the next load.

#### Scenario: Reloading a deep link
- **WHEN** a browser requests a path of the app that is not a file, such as a game route
- **THEN** the server answers with the app's entry page

#### Scenario: After a redeploy
- **WHEN** the image is rebuilt and redeployed
- **THEN** a returning browser loads the new bundle, since every response asks it to revalidate

### Requirement: Safe responses
Every response SHALL carry headers that disable content sniffing, limit the referrer, forbid framing by other sites
and restrict browser features, SHALL be compressed when text, and SHALL NOT reveal the server's version.

#### Scenario: Any response
- **WHEN** a browser requests the entry page or any asset
- **THEN** the response carries the security headers and no server version

### Requirement: No secrets in the bundle
The web build SHALL NOT include source maps or values passed at build time that are secret, since everything built
into it is public.

#### Scenario: Inspecting the published files
- **WHEN** someone downloads the published files
- **THEN** they find no source maps and no secrets
