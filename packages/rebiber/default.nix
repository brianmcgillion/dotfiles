# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{
  lib,
  python3Packages,
  fetchFromGitHub,
}:

let
  pname = "rebiber";
  # Upstream HEAD declares 1.2.0 in pyproject.toml; no release tag exists
  # for it, so use the untagged-commit version convention.
  version = "1.2.0-unstable-2025-05-22";
in
python3Packages.buildPythonPackage {
  inherit pname version;
  pyproject = true;

  src = fetchFromGitHub {
    owner = "yuchenlin";
    repo = "rebiber";
    rev = "f5e7a2b4b4bac7c8b111c1b75080c1bcb5c8b08d";
    hash = "sha256-SzVyY9L/tFImJP0GOVMNcvlccyyQvL4UURoqwpT0qL0=";
  };

  strictDeps = true;

  build-system = [
    python3Packages.hatchling
  ];

  dependencies = [
    python3Packages.bibtexparser
    python3Packages.tqdm
  ];

  pythonImportsCheck = [ "rebiber" ];

  meta = {
    description = "Tool for normalizing bibtex entries with official publication info";
    homepage = "https://github.com/yuchenlin/rebiber";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
