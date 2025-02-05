## install ollama onto a host

### Install ollama- Execute the curl command and this will install ollama and configure it.

    `curl -fsSL https://ollama.com/install.sh | sh`


    **NOTE:** Optionally you can download a gziped TAR file from https://ollama.com/ using
      ` curl -L https://ollama.com/download/ollama-linux-amd64.tgz -o ollama-linux-amd64.tgz`

### Once downloaded you can pull the models you want. For my demo I pulled 2 models
- llama3.2          - This is the LLM I used
- mxbai-embed-large - This is the embedding model I used

### change configure as needed
   In order to allow ollama to be accessed remotely and because of disk space I set some environment variables.
   If you are running ollama as a service you can set this automatically


|Description                               | Setting                                         |
|------------------------------------------|-------------------------------------------------|
| execute ollama on all interfaces         |Environment="OLLAMA_HOST=0.0.0.0:11434"          |
| Keep the model available                 |Environment="OLLAMA_KEEP_ALIVE=-1"               |
| proxy setting used when pulling models   |Environment="https_proxy={proxy host}:80"        |
| proxy setting used when pulling models   |Environment="https_proxy={proxy host}:80"        |
| Model location                           |Environment="OLLAMA_MODELS={location}"           |


### In order to load larger models, my VM is set at 200 GB
