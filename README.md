# ql-box

Secure solution to store and manage passwords from linux shell. 
Composed of a NodeJS API and a CLI written in Bash.

## Security

The server and the user each have a private/public keys pair. Each has the public key of the other.
The data who transit between the user and the API are fully encrypted with aes-128-cbc algorithm. The symmetric key 
required to decrypt is sent along to the encrypted data. Thus, the symmetric key is also encrypted with the 
corresponding asymmetric key.

When the server send data to the user, the symmetric key is encrypted with the user public key. Then, the user can
decrypt the symmetric key with his private key and use the decrypted symmetric key to decrypt the data.

In the other way (user to server), the symmetric key is encrypted with the server public key. Then, the server can 
decrypt the symmetric key with his private key and use the decrypted symmetric key to decrypt the data.

## How to run the API

### Environment variables

For development or production environment, the following variables are required by the API and the docker services:
```
DB_ROOT_PASSWORD=mydbrootpassword
DB_USER=ql_box
DB_PASSWORD=mydbuserpassword
DB_DATABASE=ql_box
DB_KEY=mydbscretkey                   # used to encrypt the password of the stored accounts in the db
```

For development environment only, these are also required by the API:
```
...
USER_KEY=/path/to/user/public/key     # used to decrypt data from the client
PRIVATE_KEY=/path/to/server/key       # used to encrypt data to the client
```

A common way is to create a `.env` file with the variables written in it.

### The init.sql file

You need to edit `dockerfiles/db/init.sql`. This file contains queries who will initialize the database at the creation 
of the docker service. It will create `users` table, then `accounts` table, then add a new user. So, in the last query 
of the file, replace the value of the `username` and the `password` field by your ones. Be care, the password value 
should be **bcrypt hashed**.

Also, these credentials will be used during the authentication (basic Auth) to the ql-box API.

### Development

1. Make sure the environment variables required are set or create a `.env` file into the root project directory.

2. Create or copy/paste the previous `.env` file (with the same variables/values) into `dockerfiles/dev`.

3. Go into `dockerfiles/dev`. The docker-compose file here will create a mariadb service and a database adminer. 
You can create and start these docker services with `docker-compose up -d`.

4. Go back to the root project directory and start the API with `npm start`. The API will listen on port `3000`.

### Production

1. Make sure to create a `.env` file with the required variables in `dockerfiles/prod`.

2. On the host, make sure to create the directory `/var/ql-box/.pem`. This directory must contain the user public key 
`user.pem` and the server private key `private.pem`.

2. Go into `dockerfiles/prod`. The docker-compose file here will create the ql-box service and the database service 
ready to use. You can create and start these docker services with `docker-compose up -d`. The ql-box service 
will listen on port `3000`.

## CLI

Copy or move `cli.sh` in your binaries directory e.g. `cp cli.sh ~/bin/qlbox.sh && chmod 755 ~/bin/qlbox.sh`.

### Usage
```
$> qlbox.sh -h
USAGE: script.sh <username> <api uri> <api public key> <user private key>
```
All parameters are optional.
