## install APEX into your PDB

I've included a word document with screen shots

###The basic steps are below

1. Download the software. I used [this blog post](https://saidulhaque.com/knowledgebase/article-72#/).
2. Create tablespaces to in the PDB to store the APEX objects

~~~
Create tablespace tbs_apexpdb datafile ;
Create tablespace tablespace_apex datafile ;
Create tablespace tablespace_files datafile ;
Create temporary tablespace tablespace_temp  tempfile ;
~~~

3. Execute the install script in the PDB passing the tablespace.

`@apexins.sql tbs_apexpdb  TBS_APEXPDB temp /i/`

4. Unlock the Administrator account using `@apxchpwd.sql`

5. Configure restful service using `@apex_rest_config.sql

6. Unlock the APEX_LISTENER, APEX_REST_PUBLIC_USER and APEX_PUBLIC_USER accounts and set a password.

7. Downloaded the ORD file onto my DB host (it can run anywhere).

8. Execute `ords install` to configure ORDS. You will be asked for connection information for the database.
   Note: You will be starting this server in this directory so I recommend you run this in a new directory.

9. Create a "ords serve" script in the directory and startup ords with nohup.

10. Ensure firwall ports are open for the port you are running ords on.
