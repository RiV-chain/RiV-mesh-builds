#!/bin/sh

# This script generates an MSI file for Mesh for a given architecture. It
# needs to run on Windows within MSYS2 and Go 1.19 or later must be installed on
# the system and within the PATH. This is ran currently by Appveyor or GitHub Actions (see
# appveyor.yml in the repository root) for both x86 and x64.
#
# Author: Neil Alexander <neilalexander@users.noreply.github.com>, Vadym Vikulin <vadym.vikulin@rivchain.org>

# Get arch from command line if given
