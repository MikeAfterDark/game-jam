#!/bin/bash

butler push ../build/lovejs gusakm/jamegam50:web
butler push ../build/win32 gusakm/jamegam50:win32
butler push ../build/win64 gusakm/jamegam50:win64
butler push ../build/macos gusakm/jamegam50:macos
butler push ../build/appimage gusakm/jamegam50:linux
