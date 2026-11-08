# Server v1.6.587 candidate

Prepared source only; no Server image or release has been published.
No Server587 build, publication, deployment or native
acceptance result is claimed. All matching component publications below have
passed their exact anonymous-byte and cryptographic gates. The normal Server
build/security/publication pipeline and matching runtime acceptance remain.

## Verified component inputs

Engine `v0.183.389`, immutable release 438285712, passed twelve anonymous asset
readbacks and thirteen cryptographic subjects. Producer
`339ad3f8d86725bdc70f5d90694401107170138a`, same-tested-tree tag commit
`3d50bff82934306240bc4fa06b48f40724d8e63b`, tree
`cf674da2284f3f821d80465123b4d29b31df38fa`; cattle.jar SHA256
`6d1bfdc4bac47253246fb909547d12c15714b1bd153c1d2358911a140c37477b`.
The readonly/restricted schema hashes retain the qualified published baseline.

Web Console `1.6.230` / optional Bridge `0.2.32`, immutable release 438291732,
passed thirteen anonymous assets and fourteen cryptographic subjects. Producer
`033154722c2e0e8e496532d3c9ae913df4bab027`, tag merge
`a910708d92416f8fcbe33cd61f5b9c7bea4f3180`, tested tree
`e88db2b8be4094f401ac948ac1f42f2f2155ebc4`. Web archive SHA256
`6bb2f45e6a53dd53c44285a67b68a248fbf2043994067ed7310cc919b361a4d0`, lock
`a4394748f1de7a773fd91849e0787a1ed1a2c7af186556fb3a8721c49ca5d681`, runtime SBOM
`77a0e070dc54db54f4afa59b5db26bb249e36c429d608ec788d40aac95056c72`.
Bridge ZIP SHA256 `aa31a13136aa72678a6b8810a616068255709f74c1aa211fdd058896ad2d3adf`;
it remains a separately installed client, outside the Server component set.

Compose `v0.14.44`, immutable release 438281262, passed twenty anonymous assets
and twenty-one cryptographic subjects. Its tag points to producer
`10a9279c79542ff7b221715baade93e5e644da90`; normal merge
`eee7173d74d56eb6859ee92205cf5b93a5ac6b0d` has the same tested tree
`7967d1c424b5c5470a6393b80c141cd707f528cf`. Archive SHA256
`8fb49a7da9888c3167f7228934bb7e89250ce0cf0e5b986000b0c85ae3683a2e`;
binary SHA256 `cdcc4ecbf600b39727f4ce5def76e68328662ea9a50ed23a968f3db3c4dc512d`.
The existing OpenPGP code-absence scope is requalified for these exact bytes;
no module-wide fixed claim, new consumer or exemption is added.

Ordinary Stack finish/rollback/cancel use native handlers and human-reviewed typed plans.
Rollback restores currently eligible children; already-finished/active and newly
added services remain. It does not delete additions or recreate removed services.
Cancel is a parent checkpoint and does not claim child upgrade completion.
Component qualification does not establish Server or complete frontend acceptance.

Host API `0.38.9`, Node Agent `0.13.35`, bootstrap Agent `1.2.34`, Catalog `0.20.17` and other
component pins, roles/Key ceilings, twelve tools, default-off settings, storage,
networking, multistage/flatten assembly and security/crypto gates remain unchanged.
Preserve the prior image, three named volumes, backup and operator configuration.
