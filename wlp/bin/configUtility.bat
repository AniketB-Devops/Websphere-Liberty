@echo off

setlocal enabledelayedexpansion
set errorlevel=

set CURRENT_DIR="%~dp0"
set CURRENT_DIR=!CURRENT_DIR:"=!
set WLP_INSTALL_DIR=!CURRENT_DIR:~0,-5!

@REM De-quote input environment variables.
if defined JRE_HOME set JRE_HOME=!JRE_HOME:"=!
if defined JAVA_HOME set JAVA_HOME=!JAVA_HOME:"=!
if defined WLP_USER_DIR set WLP_USER_DIR=!WLP_USER_DIR:"=!
if defined WLP_OUTPUT_DIR set WLP_OUTPUT_DIR=!WLP_OUTPUT_DIR:"=!

call:readServerEnv "%WLP_INSTALL_DIR%\java\java.env"
call:readServerEnv "%WLP_INSTALL_DIR%\etc\default.env"
call:readServerEnv "%WLP_INSTALL_DIR%\etc\server.env"

if not defined WLP_DEFAULT_USER_DIR set WLP_DEFAULT_USER_DIR=!WLP_INSTALL_DIR!\usr
if not defined WLP_USER_DIR set WLP_USER_DIR=!WLP_DEFAULT_USER_DIR!

if not defined WLP_DEFAULT_OUTPUT_DIR set WLP_DEFAULT_OUTPUT_DIR=!WLP_USER_DIR!\servers
if not defined WLP_OUTPUT_DIR set WLP_OUTPUT_DIR=!WLP_DEFAULT_OUTPUT_DIR!

@REM find the java command
if NOT defined JAVA_HOME (
  if NOT defined JRE_HOME (
    if NOT defined WLP_DEFAULT_JAVA_HOME (
      @REM Use whatever java is on the path
      set JAVA_CMD_QUOTED="java"
    ) else (
      if "!WLP_DEFAULT_JAVA_HOME:~0,17!" == "@WLP_INSTALL_DIR@" (
        set WLP_DEFAULT_JAVA_HOME=!WLP_INSTALL_DIR!!WLP_DEFAULT_JAVA_HOME:~17!
      )
      set JAVA_HOME="%WLP_DEFAULT_JAVA_HOME%"
      set JAVA_CMD_QUOTED="!WLP_DEFAULT_JAVA_HOME!\bin\java"
    )
  ) else (
    set JAVA_CMD_QUOTED="%JRE_HOME%\bin\java"
  )
) else (
  if exist "%JAVA_HOME%\jre\bin\java.exe" set JAVA_HOME=!JAVA_HOME!\jre
  set JAVA_CMD_QUOTED="!JAVA_HOME!\bin\java"
)

@REM If this is a Java 9 or 17 JDK, add some JDK 9 and 17 workarounds to the JVM_ARGS
if exist "%JAVA_HOME%\jmods\java.base.jmod" set JVM_ARGS=--add-opens java.base/java.lang=ALL-UNNAMED !JVM_ARGS!
if exist "%JAVA_HOME%\jmods\openjceplus.jmod" set JVM_ARGS=--add-exports openjceplus/com.ibm.misc=ALL-UNNAMED !JVM_ARGS!

set JVM_ARGS=-Djava.awt.headless=true !JVM_ARGS!
set TOOL_JAVA_CMD_QUOTED=!JAVA_CMD_QUOTED! !JVM_ARGS! -jar "!WLP_INSTALL_DIR!\bin\tools/ws-configUtility.jar"

@REM Do not create a SCC
if defined IBM_JAVA_OPTIONS (
  set IBM_JAVA_OPTIONS=!IBM_JAVA_OPTIONS! -Xshareclasses:none
)

if defined OPENJ9_JAVA_OPTIONS (
  set OPENJ9_JAVA_OPTIONS=!OPENJ9_JAVA_OPTIONS! -Xshareclasses:none
)

@REM Execute the tool script or JAR.
if exist "!WLP_INSTALL_DIR!\lib\tools-internal/configUtility.bat" goto:script
!TOOL_JAVA_CMD_QUOTED! %*
set RC=%errorlevel%
call:javaCmdResult
goto:exit

:script
set JAVA_RC=
call "!WLP_INSTALL_DIR!\lib\tools-internal/configUtility" %*
if defined JAVA_RC (
  set RC=!JAVA_RC!
  call:javaCmdResult
)
goto:exit

@REM
@REM Read and set variables from the quoted file %1.  Empty lines and lines
@REM beginning with the hash character ('#') are ignored.  All other lines must
@REM be be of the form: VAR=VALUE
@REM
:readServerEnv
  if not exist %1 goto:eof
  for /f "usebackq eol=# delims== tokens=1,*" %%i in (%1) do set %%i=%%j
goto:eof

@REM
@REM Check the result of a Java command.
@REM
:javaCmdResult
  if %RC% == 0 goto:eof

  if !JAVA_CMD_QUOTED! == "java" (
    @REM The command does not contain "\", so errorlevel 9009 will be reported
    @REM if the command does not exist.
    if %RC% neq 9009 goto:eof
  ) else (
    @REM The command contains "\", so errorlevel 3 will be reported.  We can't
    @REM distinguish that from our own exit codes, so check for the existence
    @REM of java.exe.
    if exist !JAVA_CMD_QUOTED!.exe goto:eof
  )

  @REM Windows prints a generic "The system cannot find the path specified.",
  @REM so echo the java command.
  echo !JAVA_CMD_QUOTED!
goto:eof

:exit
%COMSPEC% /c exit %RC%
