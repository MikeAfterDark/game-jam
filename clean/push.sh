#!/bin/bash

# butler push ../build/lovejs gusakm/jamegam50:web
butler push ../build/win32 gusakm/jamegam50:win32-winnitron
butler push ../build/win64 gusakm/jamegam50:win64-winnitron
butler push ../build/macos gusakm/jamegam50:macos-winnitron
butler push ../build/appimage gusakm/jamegam50:linux-winnitron
