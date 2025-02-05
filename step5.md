## Create the objects in the database

### The following scripts need to executed to create the objects


| Script Name                       | Description                                   |
|-----------------------------------|-----------------------------------------------|
|create_tables.sql                  | Creates the tables for the demo               |
|create_packages.sql                | Creates the packages used to chunk and embed  |
|gen_ai_chat_documents_db.sql       | Create function to interact with the LLM      |
|document_search.sql                | Creates function to return chunks             |

You need to execute these scripts.
You may have to recreate the trigger on the docuements table