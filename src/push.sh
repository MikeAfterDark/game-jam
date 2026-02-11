#!/bin/bash

name="gusakm"
project="brackey"
type=""

butler push ../build/lovejs ${name}/${project}:web${type}
butler push ../build/win32 ${name}/${project}:win32${type}
butler push ../build/win64 ${name}/${project}:win64${type}
butler push ../build/macos ${name}/${project}:macos${type}
butler push ../build/appimage ${name}/${project}:linux${type}
