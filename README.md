Notes on the IU_Chron_II.cmd files
===================================
###contact Keith MacKay (kmackay@ipipeline.com) with questions

1. If the current username is not '', then set the email address to send to {username}@ipipeline.com

2. Get all of the relevant lines of information from the GAID.DAT file (not the first 4, or anything that starts with a semicolon) and iterate over each of them
[Example GAID.DAT file](./GAID.DAT)
![GAID.DAT screenshot](./gaid_dat.png)

3. Iterate over each of these lines for the two values pulled from GAID.DAT. In the code, the variable '%%a' is the value of the Company's Name, and '%%b' would be the GAID of the same company

4. If there is an existing file that matches the path "\\QD1IGOWEB00.dv.ipipenet.com\e$\Inetpub\wwwroot\CossEnterpriseSuite\Custom\IPIPELINE\IPipeline\%%a\%%a-v.********.*.LOG" and a file at "E:\IUContentFiles\QD1\%%b\CossEnterpriseSuite\Custom\IPIPELINE\IPipeline\%%a\%%a-v.????????.?.LOG", then step 5, otherwise, step ...

5. Do a binary file compare of the two files ("\\QD1IGOWEB00.dv.ipipenet.com\e$\Inetpub\wwwroot\CossEnterpriseSuite\Custom\IPIPELINE\IPipeline\%%a\%%a-v.********.*.LOG" and "E:\IUContentFiles\QD1\%%b\CossEnterpriseSuite\Custom\IPIPELINE\IPipeline\%%a\%%a-v.????????.?.LOG"). 
If the two files are the same, and