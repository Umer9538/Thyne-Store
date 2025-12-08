#!/bin/bash

# Start Thyne Jewels Backend Server

echo "🚀 Starting Thyne Jewels Backend..."

# Start MongoDB if not running
if ! pgrep -x "mongod" > /dev/null; then
    echo "📦 Starting MongoDB..."
    mongod --dbpath /usr/local/var/mongodb --fork --logpath /usr/local/var/log/mongodb/mongo.log 2>/dev/null
    sleep 2
    echo "✅ MongoDB started"
else
    echo "✅ MongoDB already running"
fi

# Navigate to backend directory
cd /Users/mac/StudioProjects/thyne_jewls/backend

# Kill any existing server processes
pkill -f "./server" 2>/dev/null
sleep 1

# Start the server with CORS enabled
echo "🌐 Starting backend server on port 8080..."
PORT=8080 CORS_ALLOWED_ORIGINS="*" ./server
