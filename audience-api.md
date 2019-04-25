# Introduction

The LiveIntent Developer API allows programmatic interaction with the LiveIntent
platform, offering developers the ability to streamline or automate certain tasks.


## Requirements
In order to use the LiveIntent Developer API you must obtain a **username** and
**password** from your contact at LiveIntent.

# Authentication
All requests to the API must contain a valid access token. To obtain an access
token, call the `/login` endpoint with your provided credentials.

```bash
# example '/login' request
curl -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{
  "username": "user@example.com",
  "password": "secret"
}' 'https://merlin.liveintent.com/login'
```

If authentication succeeds, the API will respond with a `token` as well as a `refreshToken`.

```bash
# example response
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImJhZTE2MTk1N2JhZjExZThiYjE0MDI0MmFjMTIwMDA3IiwidXNlcm5hbWUiOiJ1c2VyQGV4YW1wbGUuY29tIiwiYWNjZXNzVG9rZW4iOiJhMGNiNGY5MWIxNTdhYWE1ZTk5NzYzYmEwZjI2ZWIzM2UwMmFjYWY0IiwiaWF0IjoxNTMwMjg1NzI5LCJleHAiOjE1MzAzNzIxMjl9.qeZaTbqiUABoXI0NkosIO1ZuPDclpnzOD7pYDUfZW2U",
  "username": "user@example.com",
  "userId": "bae161957baf11e8bb140242ac120007",
  "refreshToken": "dc0487e9c4ed00b0caa92270a94b2f435d1c61b6"
}
```

With this token, you may now make authenticated requests to the API.

```bash
# example authenticated request
curl -X POST \
    --header 'Content-Type: text/plain' \
    --header 'Accept: application/json' \
    --header 'Authorization: bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImJhZTE2MTk1N2JhZjExZThiYjE0MDI0MmFjMTIwMDA3IiwidXNlcm5hbWUiOiJ1c2VyQGV4YW1wbGUuY29tIiwiYWNjZXNzVG9rZW4iOiJhMGNiNGY5MWIxNTdhYWE1ZTk5NzYzYmEwZjI2ZWIzM2UwMmFjYWY0IiwiaWF0IjoxNTMwMjg1NzI5LCJleHAiOjE1MzAzNzIxMjl9.qeZaTbqiUABoXI0NkosIO1ZuPDclpnzOD7pYDUfZW2U' -d '7b01668973a75763f13048fb80bfeff1d9eb10f8
6b8be3a1067f7c54c27d7a47caf3c34e28e96b0a' \
    'https://merlin.liveintent.com/realtime/audience/123456789?type=sha1'
```

# Audiences
LiveAudiences consist of hashed identifiers that can be used to target or
suppress customers from your ad campaigns.

## Creating an Audience
Use this endpoint to create a new audience.

**POST** `/audience`

| Field       | Description                                                                                                  |
| ----------- | -----------                                                                                                  |
| advertiser  | **type:hash** <br><br> **required** <br><br> The id of the advertiser that the audience belongs to.          |
| externalId  | **type:string(256)** <br><br> An optional id, which can used for referencing the audience in another system. |
| name        | **type:string(128)** <br><br> **required** <br><br> The name of the audience.                                |
| ttl         | **type:int** <br><br> The time-to-live, in seconds, of the audience.                                         |

## Adding Hashes to an Audience
To upload CRM data to an audience you must first obtain a signed URL.

#### Step 1: Obtain Presigned URL
```bash
curl -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' --header 'Authorization: bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImM4YzBhOWIwMjlkMzExZTY4YzE1MjIwMDBhOTc0NjUxIiwidXNlcm5hbWUiOiJhbWlsbGVyQGxpdmVpbnRlbnQuY29tIiwiYWNjZXNzVG9rZW4iOiJkYjdhYmY4NjE2ODgxZmMzY2RkOWI4N2RlODFmYjViZjU3OWUxNjQ0IiwiaWF0IjoxNTU2MTMwNDgzLCJleHAiOjE1UTYyMTY4ODN9.nneZtvwMr60rl_pARBB2PgDT1TsiSF41JsNh0XsncqQ' -d '{
    "filename": "{filename}",
    "action": "add",
    "type": "md5",
}' 'https://merlin.liveintent.com/audience/upload/{audienceId}'
```
