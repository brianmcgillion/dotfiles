# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Brian McGillion
{
  lib,
  python3Packages,
  fetchPypi,
}:

# Needed for binary ninja SVD plugin
python3Packages.buildPythonPackage rec {
  pname = "svd2py";
  version = "1.0.2";
  format = "wheel";

  src = fetchPypi {
    inherit pname version;
    format = "wheel";
    dist = "py3";
    python = "py3";
    hash = "sha256-VPs0ByjQsiyzc7v6ItEZ3Dy5xOsVgQw0jNw8bQwfJXY=";
  };

  dependencies = with python3Packages; [
    click
    pyyaml
  ];

  pythonImportsCheck = [ "svd2py" ];

  meta = {
    description = "Convert CMSIS SVD files to Python data structures";
    homepage = "https://github.com/gembcior/svd2py";
    license = lib.licenses.mit;
  };
}
