# Desktop release packages

## Linux `.deb`

Install Flutter, GTK development headers, `dpkg-deb`, and Python 3, then run:

```sh
python3 tools/package_linux_deb.py
```

The script builds the Linux release and writes a Debian package to `dist/`.
Install it with `sudo apt install ./dist/bolt_<version>_<architecture>.deb`.

## Windows

The GitHub Actions workflow builds the Windows release on a Windows runner and
uploads `bolt-windows-x64.zip`. The ZIP contains `bolt.exe` and its required
runtime files; keep them together when extracting and launching the app.

Run the workflow manually from the Actions tab to download build artifacts.
Pushing a tag beginning with `v` also creates a GitHub Release and attaches the
Linux `.deb` and Windows ZIP automatically.
