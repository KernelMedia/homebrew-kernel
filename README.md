# homebrew-kernel

Homebrew tap for [Kernel Media Server](https://kernelmedia.tv).

```bash
brew tap KernelMedia/kernel
brew install server
brew install remotenode   # only needed on a separate transcoding machine
```

Then open `http://localhost:9014` to run the setup wizard. `remotenode`
listens on port 9015 by default (config at
`$(brew --prefix)/etc/kernel-remotenode/config.yml`) so it doesn't collide
with `server` if you install both on the same Mac; pair it from the Kernel
admin UI under Settings > Remote Transcoders.

Both formulas track the free/community channel's darwin-amd64/darwin-arm64
build, served from a stable, non-expiring API route
(`api.kernelmedia.tv/downloads/public/free/...`) rather than the presigned
URLs the website's download page uses (those expire after 5 minutes, which
doesn't work for a formula's pinned `url`/`sha256`).
