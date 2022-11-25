# Chapter 6: Hands-on Exercise

The purpose of this chapter is to apply the material presented in the reference training and get hands-on experience writing API specification and code. 

Before you start with this exercise ensure that you installed all required tooling as specified in **[Prerequisites](../README.md)** section in readme file of the Reference REST API training

## Requirements:

Create a new API specification using Swagger and write API code implementation leveraging API Foundation that will support getting customer preferences.

For simplicity assume three types of preferences:
- contact
- statement
- alert 

Once you create and test API, add code and required configuration to call the new API from MyAccount API and add preferences to MyAccount API response

![Hands-On Scenario Overview](images/ScenarioHandsOn.png "Hands-On Scenario Overview")

## Swagger Definition Clues:

### Preferences API

- Use Swagger version 2.0 to document API specification

- Set API version to 1.0.0 (Major 1, Minor 0, Patch 0)
- The API Foundation framework is based on Networknt open source that is registered under Apache 2.0 license 
(http://www.apache.org/licenses/LICENSE-2.0.html) 
- Assume http protocol
- API is hosted on api.cibc.com
- Set cibc.api.reference.training@gmail.com as a contact email
- Use v1 as a base path 
- Assume that both request and response are in json format
- The API should provide two end points:
    - get all Contact Preferences for a Customer
    - get a specific Contact Preference for a Customer (note that according to OpenAPI 2.0 specification all parameters in path must be mandatory)
- For this practice assume two responses:
    - 200 success - with provided customer preferences
    - 404 not found - preferences for the specified Customer ID and/or Type not found
        - response elements for unsuccessful response: statusCode (int), code (string), message (string), description (string)
- Security considerations:
    - allow read access
    - protocol: OAuth2, implicit flow
    - authorization end point: http://localhost:8080/oauth2/code
- validate swagger definition using Swagger editor (executed in Web browser)
    - if the description of the errors in Swagger editor doesn't provide you sufficient information to identify the problem, execute validate utility in utl folder


## Code Generation Clues:

- before executing codegen utility from utl folder, setup config.json file for preferences swagger

- use 7050 as http port number (MyAccount 7010, Customers 7020, Accounts 7030, Transact 7040)
- use 8483 as https port number (MyAccount 8443, Customers 8453, Accounts 8463, Transact 8473)
- codegen utility uses swagger.json file; export swagger.yaml into json via Swagger editor (Download option) or use bundle.sh (from swagger-utils) to generate swagger.json from swagger.yaml

## Code Implementation Clues:

### Writing Code for Preferences API

- add configuration for Database connection (javax.sql.DataSource) to service.yaml 

- don't forget to update pom.xml file as described in reference training material to include database driver information
- business logic is in Handler classes (implementations of HttpHandler class)
- first setup logger object
- instantiate DataSource object to manage access with the database and ObjectMapper to hold response payload
- get all preferences (all types) for a specific customer

### Updating Code for MyAccount API

- assume MyAccount returns all preferences (contact, statement, alert) for a customer 

- update MyAccount service.yaml to include call to Preferences API
- in MyAccount API instantiate host, path and serviceID for Preferences API
- create preferences.yaml in Preferences API configuration folder and set key/values for path and serviceID
- implement code to call Preferences API and get all prefereces
- if Preferences API is not available set status to ERR20004

## Database Model Clues:

- Use Oracle 11g Express Docker image

- Table Name: Customer Preferences
- Fields: 
    - id: number, length 5
    - preference type: varchar, length 256
    - reference: varchar, length 256
- Insert values for ids 1 to 5 
