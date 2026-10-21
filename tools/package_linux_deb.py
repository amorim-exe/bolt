import re
import shutil
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    version_text = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    match = re.search(r"^version:\s*([0-9][^+\s]*)(?:\+\S+)?\s*$", version_text, re.M)
    if match is None:
        raise RuntimeError("Could not determine the package version from pubspec.yaml")
    version = match.group(1)
    architecture = subprocess.check_output(
        ["dpkg", "--print-architecture"], text=True
    ).strip()

    subprocess.run(["flutter", "build", "linux", "--release"], cwd=ROOT, check=True)
    bundle = ROOT / "build" / "linux" / "x64" / "release" / "bundle"
    executable = bundle / "bolt"
    bundle_icon = (
        bundle / "share" / "icons" / "hicolor" / "512x512" / "apps" / "bolt.png"
    )
    if not executable.is_file() or not bundle_icon.is_file():
        raise RuntimeError("The Linux release bundle or application icon is missing")

    output_dir = ROOT / "dist"
    output_dir.mkdir(exist_ok=True)
    output = output_dir / f"bolt_{version}_{architecture}.deb"
    with tempfile.TemporaryDirectory(prefix="bolt-deb-") as temporary:
        package_root = Path(temporary) / "package"
        application_dir = package_root / "usr" / "lib" / "bolt"
        application_dir.parent.mkdir(parents=True)
        shutil.copytree(bundle, application_dir)

        icon_dir = (
            package_root / "usr" / "share" / "icons" / "hicolor" / "512x512" / "apps"
        )
        icon_dir.mkdir(parents=True)
        shutil.copy2(bundle_icon, icon_dir / "bolt.png")

        desktop_dir = package_root / "usr" / "share" / "applications"
        desktop_dir.mkdir(parents=True)
        shutil.copy2(ROOT / "packaging" / "linux" / "bolt.desktop", desktop_dir)

        control_dir = package_root / "DEBIAN"
        control_dir.mkdir()
        (control_dir / "control").write_text(
            "\n".join(
                [
                    "Package: bolt",
                    f"Version: {version}",
                    f"Architecture: {architecture}",
                    "Maintainer: Bolt Project",
                    "Section: devel",
                    "Priority: optional",
                    "Depends: libc6, libgtk-3-0, libstdc++6",
                    "Description: Modern desktop client for REST APIs",
                    " Bolt is a lightweight native REST API client.",
                    "",
                ]
            ),
            encoding="utf-8",
        )

        temporary_output = Path(temporary) / output.name
        subprocess.run(
            [
                "dpkg-deb",
                "--build",
                "--root-owner-group",
                str(package_root),
                str(temporary_output),
            ],
            check=True,
        )
        shutil.move(temporary_output, output)

    print(f"Created {output}")


if __name__ == "__main__":
    main()
