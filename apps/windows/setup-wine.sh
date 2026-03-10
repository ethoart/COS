#!/bin/bash
export WINEPREFIX="$HOME/.wine-cos"
export WINEARCH=win64

echo "🍷 Setting up Wine for C OS..."

# Core components
winetricks -q vcrun2019 2>/dev/null || true
winetricks -q vcrun2022 2>/dev/null || true
winetricks -q dotnet48 2>/dev/null || true
winetricks -q corefonts 2>/dev/null || true
winetricks -q d3dx11_43 2>/dev/null || true

# DXVK for DirectX acceleration
winetricks -q dxvk 2>/dev/null || true

echo "✅ Wine components installed"
