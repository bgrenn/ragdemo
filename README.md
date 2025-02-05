# ragdemo
This repository contains the pieces necessary to build a RAG demo using Exadata and Ollama

## The high level steps required to do this are outlined below

1. Create an Oracle database to store the RAG application. '
   The database needs to be at least DB23ai release 23.6 .
   
2. Install the latest APEX release into the PDB you are going to be using for the demo.
   You also need to configure an ORDS server for APEX.

3. Install Ollama on a host, and ensure that ollama can be accessed remotely.
   You can also pull the models
    
4.Create the schema for the application and ensure this user has the correct permissions

5. Add the objects for this schema

6. Log into APEX and configure a new workspace for this schema.

7. Log into the workspace in APEX and create a new application using the export file

8. Load the model into the database so you can show both a DB model for embedding, and embedding from ollama

   
