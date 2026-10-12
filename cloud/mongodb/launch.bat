@echo off
title MongoDB
set "MONGO_DATA_PATH=%LOCALAPPDATA%\Targem\StarConflict\cloud\mongodb\data"

if not exist "%MONGO_DATA_PATH%" mkdir "%MONGO_DATA_PATH%"

mongod.exe -f ./config.cfg --dbpath "%MONGO_DATA_PATH%"
