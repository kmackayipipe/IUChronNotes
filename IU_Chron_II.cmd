@ECHO OFF


:BEGIN
   CLS
   @ECHO.
   @ECHO.
   @ECHO *******************************************************************************
   @ECHO * PROGRAM:  Internet Update Chron Job II (IU_Chron_II.CMD)                    *
   @ECHO * RELEASE:  3.51  Build 01APR14a                                              *
   @ECHO * DATE:     1 April 2014                                                      *
   @ECHO * AUTHOR:   Lisa A. Compton                                                   *
   @ECHO * COMPANY:  (c)2011, 2012, 2013, 2014 Internet Pipeline, Inc.                 *
   @ECHO *******************************************************************************

   REM   *******************************************************************************
   REM   * IU_Chron_II.CMD is an automated Internet update server updater designed to  *
   REM   * migrate current content from Production, QA and UAT SaaS environments into  *
   REM   * the Internet Update environment for Velocity Disconnected clients.          *
   REM   *                                                                             *
   REM   * IU_Chron_II.CMD polls the source SaaS environments for added, updated and   *
   REM   * deleted content changes to be migrated to the Internet Update environment   *
   REM   * and applies the changes found in SaaS (PROD/QA/UAT) to the corresponding    *
   REM   * target Internet Update folders.                                             *
   REM   *                                                                             *
   REM   * Changes in SaaS-based content are determined by comparing the SaaS content  *
   REM   * against the state of baseline content located on the Internet Update        *
   REM   * server.  Files found to exist in SaaS and in the corresponding baseline     *
   REM   * project folder are compared.  If the SaaS-based file is found to be dif-    *
   REM   * ferent from the baseline file, then the SaaS-based file is copied to the    *
   REM   * active corresponding Internet update project folder.  If a SaaS-based file  *
   REM   * is found not to exist in the baseline project, then the SaaS-based file is  *
   REM   * treated as a new project file and added to the active corresponding Inter-  *
   REM   * net update project folder.  If a file is found to exist in the baseline     *
   REM   * project, but not in the corresponding SaaS-based project, then the file is  *
   REM   * deemed no longer required and flagged for deletion in the project's active  *
   REM   * corresponding Internet update project folder.                               *
   REM   *                                                                             *
   REM   * IU_Chron_II.CMD is intended to be a regularly-scheduled chron job designed  *
   REM   * to run nightly on the Internet Update server.                               *
   REM   *******************************************************************************

   REM   *******************************************************************************
   REM   * The following logic was added to accommodate the missing %USERNAME% envi-   *
   REM   * ronment variable when IU_Chron_II is run as a scheduled task using Windows  *
   REM   * Task Scheduler.  If the %USERNAME% environment variable is not set, this    *
   REM   * logic will assign the variable a value of Task_Scheduler and null the sen-  *
   REM   * der e-mail address for all e-mail notifications so they are not rejected by *
   REM   * the SMTP gateway.                                                           *
   REM   *******************************************************************************
   IF "%USERNAME%" == "" (
      SET SENDER=
      SET USERNAME=Task_Scheduler
   ) ELSE (
      SET SENDER=%USERNAME%@ipipeline.com
   )

   IF EXIST IU_Chron.LOG (
      ERASE /F IU_Chron.LOG
   )

   REM   *******************************************************************************
   REM   * The following NET USE commands were added to provide access to the produc-  *
   REM   * tion file shares using alternate credentials of a service account in the    *
   REM   * IPIPELINEPROD domain.                                                       *
   REM   *******************************************************************************

:: NET USE /PERSISTENT:NO
:: IF NOT EXIST "\\Pwigows250v.ipipelineprod.com\e$\inetpub\wwwroot\*.*" (
::    NET USE "\\Pwigows250v.ipipelineprod.com\e$\inetpub\wwwroot" /USER:IPIPELINEPROD\pappsvc257 S3rvice!
:: )
:: IF NOT EXIST "\\Pwigoa250v.ipipelineprod.com\e$\Inetpub\wwwroot\*.*" (
::    NET USE "\\Pwigoa250v.ipipelineprod.com\e$\Inetpub\wwwroot" /USER:IPIPELINEPROD\pappsvc257 S3rvice!
:: )

   SETLOCAL ENABLEDELAYEDEXPANSION

   GOTO :QD1


:QD1
   @ECHO *******************************************************************************>> IU_Chron.LOG
   @ECHO * Processing QD1 environment...                                               *>> IU_Chron.LOG
   @ECHO *******************************************************************************>> IU_Chron.LOG
   @ECHO.>> IU_Chron.LOG
   @ECHO.>> IU_Chron.LOG

   FOR /F "eol=; skip=4 tokens=1,2 delims=	" %%a IN (GAID.DAT) DO (
      IF "%%b" == "" (
         GOTO :END
      )

      @ECHO *******************************************************************************>> IU_Chron.LOG
      @ECHO * Processing CossEnterpriseSuite Files for %%b/%%a>> IU_Chron.LOG
      @ECHO * DATE: !DATE!                                                        *>> IU_Chron.LOG
      @ECHO * TIME: !TIME!                                                           *>> IU_Chron.LOG
      @ECHO *******************************************************************************>> IU_Chron.LOG

      IF EXIST "\\QD1IGOWEB00.dv.ipipenet.com\e$\Inetpub\wwwroot\CossEnterpriseSuite\Custom\IPIPELINE\IPipeline\%%a\%%a-v.????????.?.LOG" (
         IF EXIST "E:\IUContentFiles\QD1\%%b\CossEnterpriseSuite\Custom\IPIPELINE\IPipeline\%%a\%%a-v.????????.?.LOG" (
            FC /B "\\QD1IGOWEB00.dv.ipipenet.com\e$\Inetpub\wwwroot\CossEnterpriseSuite\Custom\IPIPELINE\IPipeline\%%a\%%a-v.????????.?.LOG" "E:\IUContentFiles\QD1\%%b\CossEnterpriseSuite\Custom\IPIPELINE\IPipeline\%%a\%%a-v.????????.?.LOG" | FIND /C /I "FC: no differences encountered" > NUL
            IF ERRORLEVEL 1 (
               SET UPDATE=TRUE
            ) ELSE (
               IF EXIST "\\QD1IGOWEB00.dv.ipipenet.com\e$\inetpub\wwwroot\CossEnterpriseSuite\Custom\IPIPELINE\IPipeline\%%a\A_AUTORATE.TRC" (
                  IF EXIST "\\QD1IGOWEB00.dv.ipipenet.com\e$\inetpub\wwwroot\CossEnterpriseSuite\Custom\IPIPELINE\IPipeline\%%a\*.ruleapp" (
                     COPY /V /Y "\\QD1IGOWEB00.dv.ipipenet.com\e$\inetpub\wwwroot\CossEnterpriseSuite\Custom\IPIPELINE\IPipeline\%%a\*.ruleapp" "E:\IUContentFiles\QD1\%%b\CossEnterpriseSuite\Custom\IPIPELINE\IPipeline\%%a" > NUL
                     TYPE NUL > "E:\IUContentFiles\QD1\%%b\CossEnterpriseSuite\Custom\IPIPELINE\IPipeline\%%a\A_AUTORATE.TRC"
                     @ECHO InRule rule application file^(s^) updated! >> IU_Chron.LOG
                  )
               )
               @ECHO Content update not required! >> IU_Chron.LOG
               SET UPDATE=FALSE
            )
         ) ELSE (
            IF NOT EXIST "E:\IUContentFiles\QD1\%%b\CossEnterpriseSuite\Custom\IPIPELINE\IPipeline\%%a\*.*" (
               MKDIR "E:\IUContentFiles\QD1\%%b\CossEnterpriseSuite\Custom\IPIPELINE\IPipeline\%%a"
            )
            SET UPDATE=TRUE
         )
      ) ELSE (
         @ECHO No content found! >> IU_Chron.LOG
         SET UPDATE=FALSE
      )

      IF "!UPDATE!" == "TRUE" (
         SUBST W: "E:\IUBaseLineFiles\QD1\%%b\CossEnterpriseSuite\Custom\IPIPELINE\IPipeline\%%a"
         SUBST X: "E:\IUContentFiles\QD1\%%b\CossEnterpriseSuite\Custom\IPIPELINE\IPipeline\%%a"
         SUBST Y: "\\QD1IGOWEB00.dv.ipipenet.com\e$\Inetpub\wwwroot\CossEnterpriseSuite\Custom\IPIPELINE\IPipeline\%%a"
         CALL :MODULE_UPDATE
         SUBST W: /D
         SUBST X: /D
         SUBST Y: /D
      )


      @ECHO.>> IU_Chron.LOG
      @ECHO.>> IU_Chron.LOG
      @ECHO *******************************************************************************>> IU_Chron.LOG
      @ECHO * Processing WebServiceForms Files for %%b/%%a>> IU_Chron.LOG
      @ECHO * DATE: !DATE!                                                        *>> IU_Chron.LOG
      @ECHO * TIME: !TIME!                                                           *>> IU_Chron.LOG
      @ECHO *******************************************************************************>> IU_Chron.LOG

      IF EXIST "\\QD1IGOAPP00.dv.ipipenet.com\e$\Inetpub\wwwroot\CossWebServiceForms\Organizations\IPIPELINE\iPipeline\%%a\%%a-v.????????.?.LOG" (
         IF EXIST "E:\IUContentFiles\QD1\%%b\CossWebServiceForms\Organizations\IPIPELINE\IPipeline\%%a\%%a-v.????????.?.LOG" (
            FC /B "\\QD1IGOAPP00.dv.ipipenet.com\e$\Inetpub\wwwroot\CossWebServiceForms\Organizations\IPIPELINE\iPipeline\%%a\%%a-v.????????.?.LOG" "E:\IUContentFiles\QD1\%%b\CossWebServiceForms\Organizations\IPIPELINE\IPipeline\%%a\%%a-v.????????.?.LOG" | FIND /C /I "FC: no differences encountered" > NUL
            IF ERRORLEVEL 1 (
               SET UPDATE=TRUE
            ) ELSE (
               @ECHO Content update not required! >> IU_Chron.LOG
               SET UPDATE=FALSE
            )
         ) ELSE (
            IF NOT EXIST "E:\IUContentFiles\QD1\%%b\CossWebServiceForms\Organizations\IPIPELINE\IPipeline\%%a\*.*" (
               MKDIR "E:\IUContentFiles\QD1\%%b\CossWebServiceForms\Organizations\IPIPELINE\IPipeline\%%a"
            )
            SET UPDATE=TRUE
         )
      ) ELSE (
         @ECHO No content found! >> IU_Chron.LOG
         SET UPDATE=FALSE
      )

      IF "!UPDATE!" == "TRUE" (
         SUBST W: "E:\IUBaseLineFiles\QD1\%%b\CossWebServiceForms\Organizations\IPIPELINE\IPipeline\%%a"
         SUBST X: "E:\IUContentFiles\QD1\%%b\CossWebServiceForms\Organizations\IPIPELINE\IPipeline\%%a"
         SUBST Y: "\\QD1IGOAPP00.dv.ipipenet.com\e$\Inetpub\wwwroot\CossWebServiceForms\Organizations\IPIPELINE\iPipeline\%%a"
         CALL :MODULE_UPDATE
         SUBST W: /D
         SUBST X: /D
         SUBST Y: /D
      )


      @ECHO.>> IU_Chron.LOG
      @ECHO.>> IU_Chron.LOG
      @ECHO *******************************************************************************>> IU_Chron.LOG
      @ECHO * Processing WebServiceIllustrations Files for %%b/%%a>> IU_Chron.LOG
      @ECHO * DATE: !DATE!                                                        *>> IU_Chron.LOG
      @ECHO * TIME: !TIME!                                                           *>> IU_Chron.LOG
      @ECHO *******************************************************************************>> IU_Chron.LOG

      IF EXIST "\\QD1IGOAPP00.dv.ipipenet.com\e$\Inetpub\wwwroot\CossWebServiceIllustrations\Organizations\%%a\%%a\%%a-v.????????.?.LOG" (
         IF EXIST "E:\IUContentFiles\QD1\%%b\CossWebServiceIllustrations\Organizations\%%a\%%a\%%a-v.????????.?.LOG" (
            FC /B "\\QD1IGOAPP00.dv.ipipenet.com\e$\Inetpub\wwwroot\CossWebServiceIllustrations\Organizations\%%a\%%a\%%a-v.????????.?.LOG" "E:\IUContentFiles\QD1\%%b\CossWebServiceIllustrations\Organizations\%%a\%%a\%%a-v.????????.?.LOG" | FIND /C /I "FC: no differences encountered" > NUL
            IF ERRORLEVEL 1 (
               SET UPDATE=TRUE
            ) ELSE (
               @ECHO Content update not required! >> IU_Chron.LOG
               SET UPDATE=FALSE
            )
         ) ELSE (
            IF NOT EXIST "E:\IUContentFiles\QD1\%%b\CossWebServiceIllustrations\Organizations\%%a\%%a\*.*" (
               MKDIR "E:\IUContentFiles\QD1\%%b\CossWebServiceIllustrations\Organizations\%%a\%%a"
            )
            SET UPDATE=TRUE
         )
      ) ELSE (
         @ECHO No content found! >> IU_Chron.LOG
         SET UPDATE=FALSE
      )

      IF "!UPDATE!" == "TRUE" (
         SUBST W: "E:\IUBaseLineFiles\QD1\%%b\CossWebServiceIllustrations\Organizations\%%a\%%a"
         SUBST X: "E:\IUContentFiles\QD1\%%b\CossWebServiceIllustrations\Organizations\%%a\%%a"
         SUBST Y: "\\QD1IGOAPP00.dv.ipipenet.com\e$\Inetpub\wwwroot\CossWebServiceIllustrations\Organizations\%%a\%%a"
         CALL :MODULE_UPDATE
         SUBST W: /D
         SUBST X: /D
         SUBST Y: /D
      )
      
      @ECHO.>> IU_Chron.LOG
      @ECHO.>> IU_Chron.LOG
      @ECHO.>> IU_Chron.LOG
      @ECHO.>> IU_Chron.LOG
      @ECHO.>> IU_Chron.LOG
   )

   @ECHO Starting IU Create Encoded File logic >> IU_Chron.LOG
   e:\IUEncodedFiles\IUCreateEncodedFile.exe qd1 >> IU_Chron.LOG

   GOTO :MODULE_NOTIFY


:MODULE_UPDATE
   FOR /R "W:\" %%c IN (*.*) DO (
      IF EXIST "Y:%%~pnxc" (
         "C:\Program Files\GnuWin32\bin\diff.exe" --brief "W:%%~pnxc" "Y:%%~pnxc"
         IF ERRORLEVEL 1 (
            XCOPY "Y:%%~pnxc" "X:%%~pc" /V /R /Y
            @ECHO Updated %%~pnxc >> IU_Chron.LOG
            IF EXIST "X:%%~pc{DELETE}%%~nxc" (
               ERASE /F "X:%%~pc{DELETE}%%~nxc"
            )
         )
         IF ERRORLEVEL 0 (
            IF EXIST "X:%%~pc{DELETE}%%~nxc" (
               ERASE /F "X:%%~pc{DELETE}%%~nxc"
               XCOPY "Y:%%~pnxc" "X:%%~pc" /V /R /Y
               @ECHO Restored %%~pnxc >> IU_Chron.LOG
            )
         )
      ) ELSE (
         IF EXIST "X:%%~pnxc" (
            ERASE /F "X:%%~pnxc"
         )
		IF NOT EXIST "X:%%~pc{DELETE}%%~nxc" (
			@ECHO Deleted %%~pnxc >> IU_Chron.LOG
		   TYPE NUL > "X:%%~pc{DELETE}%%~nxc"
		)
      )
   )

   FOR /R "Y:\" %%c IN (*.*) DO (
      SET TEMP_TEST=%%~pc
      IF /I "!TEMP_TEST:~-6!" == "\TEMP\" (
         @ECHO Ignored Temporary File %%~pnxc >> IU_Chron.LOG
      ) ELSE (
         IF NOT EXIST "W:%%~pnxc" (
            IF EXIST "X:%%~pc{DELETE}%%~nxc" (
               ERASE /F "X:%%~pc{DELETE}%%~nxc"
            )
            XCOPY "Y:%%~pnxc" "X:%%~pc" /V /R /Y
            @ECHO Added %%~pnxc >> IU_Chron.LOG
         )
      )
   )

   FOR /R "X:\" %%c IN (*.*) DO (
      IF NOT EXIST "Y:%%~pnxc" (
         SET DELETE_TEST=%%~nxc
         IF NOT "!DELETE_TEST:~0,8!" == "{DELETE}" (
            ERASE /F "X:%%~pnxc"
            TYPE NUL > "X:%%~pc{DELETE}%%~nxc"
            @ECHO Deleted %%~pnxc >> IU_Chron.LOG
         )
      )
   )

   GOTO :EOF


:MODULE_NOTIFY
   BLAT -f "Internet Update Chron Job II <%SENDER%>" -optionfile IU_ChronMessageOptionFile.txt -subject "%DATE% IU Chron II Update Summary (QD1)"

   GOTO :END


:END
   ENDLOCAL

   FOR %%a IN (DELETE_TEST SENDER TEMP_TEST UPDATE) DO (
      SET %%a=
   )
