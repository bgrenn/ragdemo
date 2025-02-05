create or replace function Document_search (p_ai_message in varchar2,p_id in number,p_embedding in varchar2) return clob as
   v_embedding_endpoint   varchar2(500)   := 'http://{ip address}:11434';


    v_vector_credential varchar2(100)   := 'OLLAMA_CLOUD';

    v_provider          varchar2(100)      := 'Ollama';
    v_text_endpoint     varchar2(100)      := '/api/embeddings';
    v_model_embed       varchar2(100)      := 'mxbai-embed-large';
    v_db_provider       varchar2(100)      := 'database';
    v_db_model_embed    varchar2(100)      := 'ALL_MINILM_L12_V2';
    v_ai_message_vec    vector              := null;

	v_id           number;
    ----
    ----
    v_chunk_number      number:=0;
    v_chunk_1           number;
    v_chunk_2           number;
    v_chunk_3           number;  
    v_chunk_4           number;
    v_chunk_5           number;
    v_id_1           number;
    v_id_2           number;
    v_id_3           number;  
    v_id_4           number;
    v_id_5           number;
    ----
    ----

    v_messages          varchar2(32767);

Begin


v_id := p_id;


---------------------------------
-- if DB then use the model in the DB
---------------------------------------
if (p_embedding = 'DB') then
   
            ---------------------------------------
            -- Get the embedding using the database
            ---------------------------------------

            select dbms_vector.utl_to_embedding(p_ai_message
                                               , json('{"provider":"' || v_db_provider ||'","model":  "' || v_db_model_embed || '"}')
                                               )
               into v_ai_message_vec;

              ---------------------------------------
              -- retrieve chunks based on vector distance from input message and append to each other
              ---------------------------------------


            for i in (select l.id, l.file_name, lv.chunk_id, lv.chunk_txt
                                from documents_vector_db lv, documents l
                              where l.id = lv.id and (v_id = 0 or l.id=v_id)
                            order by vector_distance(embed_vector, v_ai_message_vec, cosine) fetch first 5 rows only)
                 loop
                   v_chunk_number := v_chunk_number + 1;
	          v_messages := v_messages|| chr(10);
	          v_messages := v_messages|| 'File Name            :' || i.file_name || chr(10);
	          v_messages := v_messages|| 'Chunk Number         :' || to_char(i.chunk_id) || chr(10);
	          v_messages := v_messages|| 'Chunk Text            :' || chr(10);
                  v_messages := v_messages||i.chunk_txt||' ' || chr(10);
	         v_messages := v_messages|| chr(10);

                end loop;

else
        select dbms_vector.utl_to_embedding(p_ai_message
              , json('{
               "provider":"'||v_provider||
               '","credential_name":"'||v_vector_credential||
              '","url":"'||v_embedding_endpoint||v_text_endpoint||
               '","model":"'||v_model_embed||'"}'))
                       into v_ai_message_vec;

--
---**********************************************************
-- retrieve chunks based on vector distance from input message and append to each other
---**********************************************************
if v_ai_message_vec is not null then
               	v_messages := v_messages|| chr(10);
               	v_messages := v_messages|| 'Embedding complete for document ' || v_id || chr(10);
               	v_messages := v_messages|| chr(10);
end if;


               for i in (select l.id, l.file_name, lv.chunk_id, lv.chunk_txt
                         from documents_vector_pca lv, documents l
                         where l.id = lv.id and (v_id = 0 or l.id=v_id)
                         order by vector_distance(embed_vector, v_ai_message_vec, cosine) fetch first 5 rows only)
               loop
                   v_chunk_number := v_chunk_number + 1;
               	v_messages := v_messages|| chr(10);
               	v_messages := v_messages|| 'File Name            :' || i.file_name || chr(10);
               	v_messages := v_messages|| 'Chunk Number         :' || to_char(i.chunk_id) || chr(10);
               	v_messages := v_messages|| 'Chunk Text            :' || chr(10);
                v_messages := v_messages||i.chunk_txt||' ' || chr(10);
               	v_messages := v_messages|| chr(10);

               end loop;
end if;


return v_messages;

end;
/

