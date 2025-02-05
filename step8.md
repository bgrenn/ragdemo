## Load model

Start with [this blog post](https://blogs.oracle.com/machinelearning/post/use-our-prebuilt-onnx-model-now-available-for-embedding-generation-in-oracle-database-23ai)

** ensure that the user is granted  create mining model **

- create directory where the model is located;


~~~
BEGIN
   DBMS_VECTOR.LOAD_ONNX_MODEL(
        directory => '{directory}',
        file_name => 'all_MiniLM_L12_v2.onnx',
        model_name => 'ALL_MINILM_L12_V2');
END;
/
~~~



