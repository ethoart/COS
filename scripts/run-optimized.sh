#!/bin/bash
# Run any app with maximum performance
APP=$1
shift
echo "⚡ Launching $APP with C OS optimizations..."
gamemoderun "$APP" "$@"
