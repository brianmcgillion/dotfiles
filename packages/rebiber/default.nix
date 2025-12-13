# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2025 Brian McGillion
{
  lib,
  python3Packages,
  fetchFromGitHub,
}:

let
  pname = "rebiber";
  version = "1.3.0";
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
    description = "A tool for normalizing bibtex with official info.";
    homepage = "https://github.com/yuchenlin/rebiber";
    changelog = "https://github.com/yuchenlin/rebiber/releases/tag/v${version}";
    license = lib.licenses.mit;
    #maintainers = with lib.maintainers; [ yuchenlin ];
    platforms = lib.platforms.linux;
  };
}
