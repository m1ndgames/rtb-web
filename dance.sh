#!/bin/sh
DANCER_ENVIRONMENT="production" plackup --host 127.0.0.1 -p 1234 bin/app.psgi
