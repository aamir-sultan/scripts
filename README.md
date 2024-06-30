# Scripts

This repo contains the scripts that can be useule for the exceution of the different tasks that contains multiple steps. Different Scripts and files will be added over time to this repo for different use cases.

## Use Cases:
* Repo Generator

### Repo Generator:

Repo Generator is a script that uses the API of the Gitlab for creating a repo at the user account. To use the api services one need to provide an access token to the script.

#### Use Steps:
```
chmod +x auto_gen.sh
``` 
* The script is ready for running and creating a repo at the gitlab account.
* Copy the script to the directory where you want to clone the repo.
* Run the following command to create a repo with the name "my\_cool\_repo". Change the name as per your need.
```
./auto_gen.sh -n "my_cool_repo" -t "Access_Token"
```
