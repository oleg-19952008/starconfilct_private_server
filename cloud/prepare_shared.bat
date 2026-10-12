@echo off

rem build xml's
DedicatedServer.exe -logFileName prepare_shared.log -nullCon -prepareSharedData -ds datasources_defs_build.txt
