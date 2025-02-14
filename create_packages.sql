create or replace package chathistory_pkg is
----------

----------
---------- save conversations
----------

procedure prc_add_conversation(p_username varchar2, p_started_on timestamp, p_app_session number);

----------
---------- save prompt detail as users ask questions
----------

procedure prc_add_prompt(
    p_id number
    , p_conv_id number
    , p_prompt varchar2
    , p_response varchar2
    , p_asked_on timestamp
    , p_chathistory varchar2
    , p_references varchar2);

----------
---------- Save embedded details using a model from PCA
----------

procedure prc_cr_doc_vectors_pca;

----------
---------- Save embedded details using a model from Database
----------


procedure prc_cr_doc_vectors_db;

end;
/


----------
---------- save conversations
----------


create or replace package body chathistory_pkg is
---------
procedure prc_add_conversation(p_username varchar2, p_started_on timestamp, p_app_session number) is
    pragma autonomous_transaction;
    begin
    insert into conversations values(conv_seq.nextval, p_username, p_started_on, p_app_session);
    commit;
    end;

----------
---------- save prompt detail as users ask questions
----------



procedure prc_add_prompt(
    p_id number
    , p_conv_id number
    , p_prompt varchar2
    , p_response varchar2
    , p_asked_on timestamp
    , p_chathistory varchar2
    , p_references varchar2) is
    pragma autonomous_transaction;
    begin
    insert into prompts values(
        p_id
        , p_conv_id
        , p_prompt
        , p_response
        , p_asked_on
        , p_chathistory
        , p_references);
    commit;
    end;

----------
---------- chunk document into pieces
---------- Save embedded details using a model from ollama
----------


procedure prc_cr_doc_vectors_pca is
    v_count integer;
    v_embedding_endpoint   varchar2(500)   := 'http://{ip address}:11434';
    v_api_credential varchar2(100)         := 'OLLAMA_CRED';
    v_provider_embedding   varchar2(100)   := 'Ollama';
    v_text_endpoint     varchar2(100)   := '/api/embeddings';
    v_model_embed       varchar2(100)   := 'mxbai-embed-large';


    begin

----------
---------- Loop through documents where there are no embedded details
----------


    for i in (select l.id
          from documents l
          where l.id not in (select lv.id from documents_vector_pca lv))
       loop

----------
---------- Count current number of embedding (in case another session did the embeddings already)
----------
       select count(id) into v_count from monitor_embedding_pca m where i.id = m.id;

----------
---------- If there are still no embeddings (count = 0)
----------

       if v_count = 0 then
----------
---------- insert row into monitoring table (and commit) to ensure another session doesn't process this document
---------- Then chunk the document and insert into embeddings table
----------

           insert into monitor_embedding_pca values (i.id,'processing');
           commit;
           insert into documents_vector_pca
             select i.id
                  , json_value(c.column_value, '$.chunk_id' returning number) as chunk_id
                  , json_value(c.column_value, '$.chunk_offset' returning number) as chunk_pos
                  , json_value(c.column_value, '$.chunk_length' returning number) as chunk_size
                  , replace(json_value(c.column_value, '$.chunk_data'),chr(10),'') as chunk_txt
                  , dbms_vector_chain.utl_to_embedding(json_value(c.column_value, '$.chunk_data'), json('{
                    "provider": "' || v_provider_embedding || '",
                    "credential_name": "' || v_api_credential || '",
                    "url": "' || v_embedding_endpoint || v_text_endpoint || '",
                    "model": "' || v_model_embed || '",
                    "batch_size":10
                    }')) embed_vector
              from


    ------- doc to text query ---------
                 (select id
                   , dbms_vector_chain.utl_to_text (l.file_content, json('{"plaintext":"true","charset":"utf8"}')) file_text
                   from documents l where id=l.id) t,
    ------- chunking ---------
                  dbms_vector_chain.utl_to_chunks(t.file_text,
                  json('{ "by":"words",
                  "max":"200",
                  "overlap":"0",
                  "split":"sentence",
                  "language":"american",
                  "normalize":"all" }')) c
               where i.id=t.id;
             commit;
       end if;
      end loop;
    end;

----------
---------- chunk document into pieces
---------- Save embedded details using a model from Database
----------




procedure prc_cr_doc_vectors_db is
    v_count integer;
    v_db_provider       varchar2(100)   := 'database';
    v_db_model_embed    varchar2(100)   := 'ALL_MINILM_L12_V2';

    begin

----------
---------- Loop through documents where there are no embedded details
----------

    for i in (select l.id
          from documents l
          where l.id not in (select lv.id from documents_vector_db lv))
       loop

----------
---------- Count current number of embedding (in case another session did the embeddings already)
----------
 
       select count(id) into v_count from monitor_embedding_db m where i.id = m.id;

----------
---------- If there are still no embeddings (count = 0)
----------

       if v_count = 0 then
----------
---------- insert row into monitoring table (and commit) to ensure another session doesn't process this document
---------- Then chunk the document and insert into embeddings table
----------

           insert into monitor_embedding_db values (i.id,'processing');
           commit;
           insert into documents_vector_db
             select i.id
                  , json_value(c.column_value, '$.chunk_id' returning number) as chunk_id
                  , json_value(c.column_value, '$.chunk_offset' returning number) as chunk_pos
                  , json_value(c.column_value, '$.chunk_length' returning number) as chunk_size
                  , replace(json_value(c.column_value, '$.chunk_data'),chr(10),'') as chunk_txt
                  , dbms_vector.utl_to_embedding(json_value(c.column_value, '$.chunk_data')
                                               , json('{
                                                "provider":"database",
                                                "model": "ALL_MINILM_L12_V2"
                                                       }')) embed_vector
              from
    ------- doc to text query ---------
                 (select id
                   , dbms_vector_chain.utl_to_text (l.file_content, json('{"plaintext":"true","charset":"utf8"}')) file_text
                   from documents l where id=l.id) t,
    ------- chunking ---------
                  dbms_vector_chain.utl_to_chunks(t.file_text,
                  json('{ "by":"words",
                  "max":"200",
                  "overlap":"0",
                  "split":"sentence",
                  "language":"american",
                  "normalize":"all" }')) c
               where i.id=t.id;
             commit;
       end if;
      end loop;
    end;
-------------------------
end;
/



  CREATE OR REPLACE EDITIONABLE TRIGGER "TRG_DOCUMENTS_VECTOR" 
after insert on DOCUMENTS
for each row
declare
my_job number;
begin
dbms_job.submit(job => my_job, what => 'chathistory_pkg.prc_cr_doc_vectors_db;');     
dbms_job.submit(job => my_job, what => 'chathistory_pkg.prc_cr_doc_vectors_pca;');  
end;
/


ALTER TRIGGER "TRG_DOCUMENTS_VECTOR" enable;
/












