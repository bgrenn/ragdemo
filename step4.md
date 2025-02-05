## Execute scripts to create user and grant privileges

~~~
Create user {user name} identified by {password};
Grant DBA to {user name};
grant create job to {user name};
grant create mining model to {user name};
~~~


## Execute scripts to create credentials


### Cloud credential used for Embedding calls with dbms_vector_chain

exec  DBMS_CLOUD.CREATE_CREDENTIAL( -
    CREDENTIAL_NAME => 'OLLAMA_CLOUD', -
    USER_OCID => 'dummy_OCID', -
    TENANCY_OCID => 'dummy_tenancy', -
    PRIVATE_KEY => 'dummy_KEY', -
    FINGERPRINT => 'dummy_fingerprint');

###  credential used for Embedding calls DBMS_VECTOR_CHAIN

  declare
  jo json_object_t;
begin
  jo := json_object_t();
  jo.put('access_token', 'A1Aa0abA1AB1a1Abc123ab1A123ab123AbcA12a');
  dbms_vector.create_credential(
    credential_name   => 'OLLAMA_CRED',
    params            => json(jo.to_string));
end;
/

## Open up the ports on the DB side for for the user. You can specify specific ports if you want to limit it

EXEC DBMS_NETWORK_ACL_ADMIN.CREATE_ACL (acl => 'ACL_FILE_RAGDEMO.xml', description => 'ACL_FILE_1', principal => '{user name}', is_grant => TRUE, privilege => 'connect', start_date => null, end_date => null); 
EXEC DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE(acl => 'ACL_FILE_RAGDEMO.xml',principal => '{user name}',is_grant  => true,privilege => 'connect');
EXEC DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL ( acl => 'ACL_FILE_RAGDEMO.xml', host => '*', lower_port => NULL, upper_port => NULL);
