# Chapter 4: API-to-API calls: Customers API calling the Accounts API

APIs deployed in large organizations are usually leveraging other APIs, to reuse discrete functionality readily available within the organization.

Getting an understanding about remote API invocation and chaining is an important aspect for development teams, similar to access to persisted data, illustrated in the previous chapter.
This chapter focuses on API-to-API calls.

The Customers API exposes 2 endpoints, as per the excerpt from the swagger.yml file listed below.
The first endpoint allows the retrieval of customer data for a specific customer, whereas the second out calls the Accounts API to retrieve
account data for a certain customer.

__swagger.yml excerpt__:
```
  # Customers API Swagger definition excerpt
  paths:
    /customers/{id}:
    ...
    /customers/{id}/accounts:
    ...
```

## Instructions
### __Setup__: 
To set the materials up for this chapters, type in the following (from the **/utl** folder):

```bash
    # reset the training
    :> cd utl
    <reference-training root>/utl:> ./reset-training.sh

    # set up the training
    <reference-training root>/utl:> ./train.sh api-to-api

    # build the Customers API Docker image
    <reference-training root>/utl:> ./build.sh docker customers cibcapi training.customers-1.00.00 b001

    # build the Accounts API Docker image
    <reference-training root>/utl:> ./build.sh docker accounts cibcapi training.accounts-1.00.00 b001
```

Before looking at the Java code for calling the Accounts API, we need to look at the configuration for the remote path.

These values are set in the APIs general configuration file, located in the /main/resources/config folder, and names exactly the same as the API.
in this case, the configuration is set in the customers.yml file

__customers.yml__ file:
```yml
  # path to access within the accounts API
  accounts_path: /v1/accounts?cust_id=%s
  accounts_serviceID: training.accounts-1.00.00
```

Please note that the **service.yml** needs to be updated to include the configuration for registration.
In these training materials, direct registration is used.

```
# Singleton service factory configuration

singletons:
- javax.sql.DataSource:
  - com.zaxxer.hikari.HikariDataSource:
      DriverClassName: oracle.jdbc.pool.OracleDataSource
      jdbcUrl: jdbc:oracle:thin:@localhost:1521:XE
      username: SYSTEM
      password: oracle
      maximumPoolSize: 10
      useServerPrepStmts: true,
      cachePrepStmts: true,
      cacheCallableStmts: true,
      prepStmtCacheSize: 10,
      prepStmtCacheSqlLimit: 2048,
      connectionTimeout: 2000

- com.networknt.registry.URL:
  - com.networknt.registry.URLImpl:
      protocol: https
      host: localhost
      port: 8453
      path: direct
      parameters:
        training.accounts-1.00.00: https://localhost:8463
- com.networknt.registry.Registry:
  - com.networknt.registry.support.DirectRegistry
- com.networknt.balance.LoadBalance:
  - com.networknt.balance.RoundRobinLoadBalance
- com.networknt.cluster.Cluster:
  - com.networknt.cluster.LightCluster
```

The remote API invocation code is embedded in the CustomersIdAccountsGetHandler class.

__CustomersIdAccountsGetHandler.java__:
```java
package com.cibc.api.training.customers.handler;

import java.net.URI;
import java.util.Map;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.atomic.AtomicReference;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.xnio.OptionMap;

import com.networknt.client.Http2Client;
import com.networknt.cluster.Cluster;
import com.networknt.config.Config;
import com.networknt.exception.ClientException;
import com.networknt.security.JwtHelper;
import com.networknt.server.Server;
import com.networknt.service.SingletonServiceFactory;

import io.undertow.UndertowOptions;
import io.undertow.client.ClientConnection;
import io.undertow.client.ClientRequest;
import io.undertow.client.ClientResponse;
import io.undertow.server.HttpHandler;
import io.undertow.server.HttpServerExchange;
import io.undertow.util.Headers;
import io.undertow.util.Methods;

/**
* Class implements the retrieval of account information, for a customer ID.
*
* CIBC Reference Training Materials - API Foundation - 2017
*/
public class CustomersIdAccountsGetHandler implements HttpHandler {
	static String CONFIG_NAME = "customers";
	static String SWAGGER_SECURITY_CONFIG = "swagger-security";
	static Logger logger = LoggerFactory.getLogger(CustomersIdGetHandler.class);
	
	// create cluster instance for registry
	static Cluster cluster = SingletonServiceFactory.getBean(Cluster.class);
	
	// host acquired using service discovery
	static String accountsHost;
	// path set in the API's configuration
	static String accountsPath = (String) Config.getInstance().getJsonMapConfig(CONFIG_NAME).get("accounts_path");   
	
	// serviceID for downstream API 
	static String accountsServiceID = (String) Config.getInstance().getJsonMapConfig(CONFIG_NAME).get("accounts_serviceID");   
				
	// environment set in server.yml
	// downstream API invocation only within the same environment
	static String tag = Server.config.getEnvironment();
	
	static Map<String, Object> securityConfig = (Map<String, Object>) Config.getInstance().getJsonMapConfig(SWAGGER_SECURITY_CONFIG);
	static boolean securityEnabled = (Boolean) securityConfig.get(JwtHelper.ENABLE_VERIFY_JWT);
	static Http2Client client = Http2Client.getInstance();
	static ClientConnection connection;	
	
    public CustomersIdAccountsGetHandler() {
		try {
			// discover the host and establish a connection at API start-up.
			// if downstream API is not up and running, resolution will occur at runtime
	        accountsHost = cluster.serviceToUrl("https", accountsServiceID, tag, null);
	        connection = client.connect(new URI(accountsHost), Http2Client.WORKER, Http2Client.SSL, Http2Client.POOL,
										OptionMap.create(UndertowOptions.ENABLE_HTTP2, true)).get();
	        		
		} catch (Exception e) {
			logger.error("Exeption:", e);
		}
	}

	@Override
    public void handleRequest(HttpServerExchange exchange) throws Exception {
        int statusCode = 200;
		logger.info("Customers");
        // get customer id here.
        Integer customerId = Integer.valueOf(exchange.getQueryParameters().get("id").getFirst());

        String accountString = null;

		// connect if a connection has not already been created
		final CountDownLatch latch = new CountDownLatch(1);
		if (connection == null || !connection.isOpen()) {
			try {
				// discover the host and establish a connection at API runtime
				// if downstream API is not up and running, an exception will occur
		        accountsHost = cluster.serviceToUrl("https", accountsServiceID, tag, null);
		        connection = client.connect(new URI(accountsHost), Http2Client.WORKER, Http2Client.SSL, Http2Client.POOL,
											OptionMap.create(UndertowOptions.ENABLE_HTTP2, true)).get();
			} catch (Exception e) {
				logger.error("Exeption:", e);
				throw new ClientException(e);
			}
		}

		final AtomicReference<ClientResponse> reference = new AtomicReference<>();
		try {
			ClientRequest request = new ClientRequest().setMethod(Methods.GET).setPath(String.format(accountsPath, customerId));
			// this is to ask client module to pass through correlationId and traceabilityId
			// as well as
			// getting access token from oauth2 server automatically and attach
			// authorization headers.
			if (securityEnabled)
			 	client.propagateHeaders(request, exchange);
			
			connection.sendRequest(request, client.createClientCallback(reference, latch));
			latch.await();

			statusCode = reference.get().getResponseCode();

			if (statusCode >= 300) {
				throw new Exception("Failed to call the accounts API: " + statusCode);
			}
			
			// retrieve the response from the accounts API
			accountString = reference.get().getAttachment(Http2Client.RESPONSE_BODY);

		} catch (Exception e) {
			logger.error("Exception:", e);
			throw new ClientException(e);
		}

        // set the content type in the response
        exchange.getResponseHeaders().put(Headers.CONTENT_TYPE, "application/json");

        // serialize the response object and set in the response
        exchange.setStatusCode(statusCode);
        exchange.getResponseSender().send(accountString);
    }
}
```
## Remember to start the Oracle database

Check whether the database is running by executing:
```bash
  :> docker ps
```

If it is stopped, change to the "utl" folder and type:

```bash
    :> ./compose.sh oracle up
```

## Run and Verify the APIs

To run the APIs, change to each API directory and type the following:

```bash
    #Customers API
    :> cd ../customers
    :> java -jar ./target/customers-1.00.00.jar

    # Alternatively, run from Maven
    :> mvn exec:exec

    #Accounts API
    :> cd ../accounts
    :> java -jar ./target/accounts-1.00.00.jar

    # Alternatively, run from Maven
    :> mvn exec:exec
```

### __Optional step__: 
An alternative method to run the APIs is to configure the `docker-compose-cibcapi.yml` file in the **compose** directory to look like this:

```yaml
#
# docker-compose.yml
#
# Docker compose file for API/microservice reference training containing
# services for several APIs/microservices and
# and Oracle database
#
# Naming convention:
#   cibcapi/api-name:x.yy.zz
#   ex.:
#       cibcapi/myaccounts:1.00.00
#
# Key Considerations:
# - all services are on a single external bridge network
#
# Author: cibc.api.reference.training@gmail.com
#
#
# NOTE:  the build path is one layer up from the compose directory which
# contains the compose files... the directories are *relative* to the
# docker-compose yml file.  This impacts the following:
#   -> build (must be ../api-name/ for example)
#   -> volumes (must be ..etc/api-name/ for example)
#
#

version: '2'

#
# Services
#
services:
    #
    # /customers
    #
    customers-service:
        image: cibcapi/training.customers-1.00.00:b001
        ports:
            - "7020:7020"
            - "8453:8453"
        networks:
            - localnet
        volumes:
            - ../etc/customers/config:/config
        # logging:
        #     driver: "gelf"
        #     options:
        #         gelf-address: "udp://localhost:12201"
        #         tag: "customers"
        #         env: "dev"

    #
    # /accounts
    # /accounts/:id
    #
    accounts-service:
        image: cibcapi/training.accounts-1.00.00:b001
        ports:
            - "7030:7030"
            - "8463:8463"
        networks:
            - localnet
        volumes:
            - ../etc/accounts/config:/config
        # logging:
        #     driver: "gelf"
        #     options:
        #         gelf-address: "udp://localhost:12201"
        #         tag: "accounts"
        #         env: "dev"

```

When the `docker-compose-cibcapi.yml` is set up, you can run both APIs from a single command line window by being in the `utl` directory and executing:
```bash
    #Customers and Accounts APIs
    :> ./compose cibcapi up
```


To test the endpoint, execute the following command:
```bash
  # retrieve the accounts associated with the customer with ID 1
  # HTTPs Test
  :> curl -k https://localhost:8453/v1/customers/1/accounts
```

which produces the result:
```json
  { "accounts":
    [
      {
        "customerID":"1",
        "id":"1",
        "balance":100.0,
        "accountType":null
        },
      {
        "customerID":"1",
        "id":"2",
        "balance":200.0,
        "accountType":null
        }
    ]
  }
```

To test the APIs, the following commands can be executed:
```bash
  # HTTPS Testing

  # TEST the Customers API

  # retrieve customer data for customer with ID 1
  :> curl -k https://localhost:8453/v1/customers/1
  # retrieve the accounts associated with the customer with ID 1
  :> curl -k https://localhost:8453/v1/customers/1/accounts

  # TEST the Accounts API

  # retrieve the accounts data for account with ID 1
  :> curl -k https://localhost:8463/v1/accounts/1
  # retrieve the accounts associated with the customer with ID 1
  :> curl -k https://localhost:8463/v1/accounts?cust_id=1  
```
## Continue to the next chapter

The next chapter is [The MyPortfolio Reference Application: Integrating the MyAccounts, Customers, Accounts and Transactions APIs](step-05.md)
