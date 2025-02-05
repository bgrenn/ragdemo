create or replace function gen_ai_chat_documents_db (p_ai_message in varchar2,p_id in number,p_conv_id in number, p_embedding in varchar2) return clob as


    v_gen_ai_endpoint   varchar2(500)      := 'http://{ip address}:11434';
    v_embedding_endpoint   varchar2(500)   := 'http://{ip address}:11434';

    v_vector_credential varchar2(100)      := 'OLLAMA_CRED';
    v_api_credential varchar2(100)         := 'OLLAMA_CRED';
    v_provider          varchar2(100)      := 'Ollama';
    v_text_endpoint     varchar2(100)      := '/api/embeddings';
    v_chat_endpoint     varchar2(100)      := '/api/generate';
    v_model_embed       varchar2(100)      := 'mxbai-embed-large';
    v_model_query       varchar2(100)      := 'llama3.2';

    v_db_provider       varchar2(100)       := 'database';
    v_db_model_embed    varchar2(100)       := 'ALL_MINILM_L12_V2';
    ----
 
    v_output            varchar2(32767);
    v_ai_message_vec    vector;
    v_chunks            varchar2(32767);
    v_response          varchar2(32767);
    v_chathistory_after varchar2(32767);
    v_chathistory_before varchar2(32767);
    v_conv_id           number;
    v_prompt_id         number;

     v_prompt CLOB;
     v_user_question CLOB;
     v_context CLOB  := '';
     v_params CLOB;

     v_id number;


begin


------------------------------------------------------------------------------
-- Set the beginning of the message to the LLM
-- Make sure we use the current conversation when sending conversation history
-------------------------------------------------------------------------------


    v_id := p_id;



--------------------------------------
--vectorize the user_question
----------------------------------------



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
                      v_context   := v_context || i.chunk_txt;
                end loop;
else
   
            ---------------------------------------
            -- Get the embedding using the PCA
            ---------------------------------------

        select dbms_vector.utl_to_embedding(p_ai_message
                             , json('{
                                  "provider":"'||v_provider||
                               '","credential_name":"'||v_vector_credential||
                               '","url":"'||v_gen_ai_endpoint||v_text_endpoint||
                               '","model":"'||v_model_embed||'"}'))
                 into v_ai_message_vec;

             ---------------------------------------
              -- retrieve chunks based on vector distance from input message and append to each other
              ---------------------------------------

           for i in (select l.id, l.file_name, lv.chunk_id, lv.chunk_txt
                         from documents_vector_pca lv, documents l
                        where l.id = lv.id and (v_id = 0 or l.id=v_id)
                     order by vector_distance(embed_vector, v_ai_message_vec, cosine) fetch first 5 rows only)
                loop
                      v_context   := v_context || i.chunk_txt;
                end loop;

end if;

--*******************************
-- Set the user question
---****************************
v_user_question := p_ai_message;


v_prompt := 'Answer the following question using the supplied context ' ||
                'assuming you are a subject matter expert. Question: '
                || v_user_question || ' Context: ' || v_context;





v_conv_id := p_conv_id;
--


--*******************************
-- Find the most current prompt information for this conversation
---****************************


begin
select max(id) into v_prompt_id from prompts where conv_id = v_conv_id;
exception
when others then null;
end;
--


--*******************************
-- Find the chat history for this conversation
---****************************


begin
select chathistory into v_chathistory_before from prompts where id = v_prompt_id;
exception
when others then null;
end;

--*******************************
-- Add the chat history (if any exists)
---****************************


if v_chathistory_before is not null then
     v_prompt := v_prompt || ' Chat_history: '|| v_chathistory_before;
end if;


--*******************************
-- Call the LLM
---****************************



v_params := '{' ||
               '"provider" : "' || v_provider || '",' ||
               '"credential_name" : "' || v_api_credential || '",' ||
               '"url" : "' || v_embedding_endpoint || v_chat_endpoint ||'",' ||
               '"model" : "' || v_model_query || '"' ||
               '}';

  v_output := DBMS_VECTOR_CHAIN.UTL_TO_GENERATE_TEXT(v_prompt, json(v_params));


v_response := v_output;
v_chathistory_after := v_output;


--*******************************
-- update the prompt and chat history
---****************************


-- update prompts
chathistory_pkg.prc_add_prompt(
    prompt_seq.nextval
    , v_conv_id
    , p_ai_message
    , v_response
    , systimestamp
    , v_chathistory_after
    , v_chunks);
-- show me what you got
return v_response;
end;
/

