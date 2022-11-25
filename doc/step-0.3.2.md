# Chapter 3.2: Adding a Database Query

In the previous chapter we have created a simple API that returned an empty string.
While this verified that the API worked, the API at this point does not do
anything useful other than allowing us to test an endpoint and validating the integration.

In this chapter, a database query will be added to the API.

To do this, the following steps will be taken:
- Add a query to the API
- Build the API
- Run and verify the API

### __Optional step__: 
You may continue where you have left off from the previous step, or you can
execute his tutorial with the required modules for chapter 3.2 (a clean version of the reference training
application from the *end* of chapter 3.1).  To execute this, type the following (from the __*/utl*__ folder). :

```bash
    # reset the training
    :> cd utl
    <reference-training root>/utl:> ./reset-training.sh

    # set up the Swagger definitions
    <reference-training root>/utl:> ./train.sh swagger

    # Generate the Customers API implementation code:
    <reference-training root>/utl:> ./generate.sh light-rest-4j ~/work/cibc-api/branches/reference-rest-api/swagger/customers ~/work/cibc-api/branches/reference-rest-api/customers
```

## Add a Query to the API

The source tree for the API is composed of a number of files pertaining to both the model, as well as handlers, however we will add a database query to the handler file that responds to
a request of retrieving customer data by id, named **CustomerIdGetHandler.java**,  located in the following folder:

```
    <root-reference-application>/customers/src/main/java/com/cibc/api/training/customers/handler
```

The current contents of the file is illustrated below:

```java
package com.cibc.api.training.customers.handler;

import io.undertow.server.HttpHandler;
import io.undertow.server.HttpServerExchange;
import io.undertow.util.HttpString;
import java.util.HashMap;
import java.util.Map;

public class CustomersIdGetHandler implements HttpHandler {
    @Override
    public void handleRequest(HttpServerExchange exchange) throws Exception {

            exchange.endExchange();

    }
}
```

Note that the package name, **com.cibc.api.training.customers.handler**, is identical
to that in the config.json file generated and edited in previous steps.

We will make several changes to this file **CustomerIdGetHandler.java** to this handler to allow it to
get information from a database.
- Add data structures representing the data
- Add a data source for the data
- Open a database connection
- Prepare and issue the query
- Close resources

```java
/**Step 1:  Add imports:
*/
  package com.cibc.api.training.customers.handler; 
  // Undertow specific imports:
  // A handler for an HTTP request. The request handler must eventually either call another handler or end the exchange.
  import io.undertow.server.HttpHandler;

  // An HTTP server request/response exchange. An instance of this class is constructed as soon as the request headers are fully parsed
  import io.undertow.server.HttpServerExchange;

  // An HTTP Header representation class
  import io.undertow.util.Headers;

  // java.sql package provides the API for accessing and processing data stored in a data source
  import java.sql.Connection;
  import java.sql.PreparedStatement;
  import java.sql.ResultSet;
  import javax.sql.DataSource;

  // Java map utility classes
  import java.util.Map;
  import java.util.HashMap;

  // Jackson's ObjectMapper can parse a JSON from a string, stream or file, and create an object graph representing the parsed JSON
  import com.fasterxml.jackson.databind.ObjectMapper;

  // API Foundation components:
  // Config component, allows config individualized by component
  import com.networknt.config.Config;
  // Status, allows config of statuses returned by the API
  import com.networknt.status.Status;
  // Security component, allows JWT token verification
  import com.networknt.security.JwtHelper;
  // Singleton factory representation
  import com.networknt.service.SingletonServiceFactory;

  // Slf4J logging imports
  import org.slf4j.Logger;
  import org.slf4j.LoggerFactory;

  // Representation of the Customer object definition, corresponding to the Swagger definition
  import com.cibc.api.training.customers.model.Customer;


/**Step 2**: Provide proper Javadoc for the class
*/

/**
* Class implements the retrieval of customer information, as queried by customer ID.
*
* CIBC Reference Training Materials - API Foundation - 2017
*/

/**Step 3**:  Add a data source and a Jackson object mapper for the data to CustomersIdGetHandler:
*/
public class CustomersIdGetHandler implements HttpHandler {
  // set up the logger
  static final Logger logger = LoggerFactory.getLogger(CustomersIdGetHandler.class);

  // check whether security is enabled
  static Map<String, Object> securityConfig = (Map)Config.getInstance().getJsonMapConfig(JwtHelper.SECURITY_CONFIG);
  static boolean securityEnabled = (Boolean)securityConfig.get(JwtHelper.ENABLE_VERIFY_JWT);

  // Access a configured DataSource; retrieve database connections from this DataSource
  private static final DataSource ds = (DataSource) SingletonServiceFactory.getBean(DataSource.class);

  // Get a Jackson JSON Object Mapper, usable for object serialization
  private static final ObjectMapper mapper = Config.getInstance().getMapper();

/**Step 4**: Override the handleRequest() method
*/

@Override
public void handleRequest(HttpServerExchange exchange) throws Exception {
    if (exchange.isInIoThread()) {
        exchange.dispatch(this);
        return;
    }

    Status status = null;
    int statusCode = 200;
    String resp = null;

/**Step 5**: Extract the id from the request
*/

  // get customer id here.
  Integer customerId = Integer.valueOf(exchange.getQueryParameters().get("id").getFirst());
  Customer customer = null;
            
/**Step 6**: Retrieve a connection from the connection pool and prepare the statement.
Note that the Java 8 syntax is used and resource must be properly closed ! 
*/
/**Step 7**: Retrieve the data and set it in a response map, or issue an error status in case the id has not been found
*/

        try (final Connection connection = ds.getConnection()) {

            try (PreparedStatement statement = connection.prepareStatement(
                    "SELECT * FROM customer WHERE id = ?",
                    ResultSet.TYPE_FORWARD_ONLY, ResultSet.CONCUR_READ_ONLY)) {

                statement.setInt(1, customerId);

                try(ResultSet resultSet = statement.executeQuery()) {

                    // extract the customer data
                    if (resultSet.next()) {
                        // customer data successfully retrieved
                        customer = new Customer();
                        customer.setId(Helper.isNull(resultSet.getString("ID")));
                        customer.setFirstName(Helper.isNull(resultSet.getString("FIRST_NAME")));
                        customer.setLastName(Helper.isNull(resultSet.getString("LAST_NAME")));
                        customer.setMiddleInitial(Helper.isNull(resultSet.getString("MIDDLE_INITIAL")));

                        // serialize the response
                        Map<String, Customer> map = new HashMap<String, Customer>();
                        map.put("customers", customer);

                        resp = mapper.writeValueAsString(map);
                    } else {
                        // customer data not found
                        status = new Status("ERR12013", customerId);
                        statusCode = status.getStatusCode();

                        // serialize the error response
                        resp = mapper.writeValueAsString(status);
                    }
                }
            }
        } catch (Exception e) {
          // log the exception
          logger.error("Exception encountered in the customers API: ", e);

          // This is a runtime exception
          status = new Status("ERR10010");
          statusCode = status.getStatusCode();

          // serialize the error response
          resp = mapper.writeValueAsString(status);
      }

/**Step 8**: set the retrieved data in the response and finalize by this the handleRequest() method
*/

      // set the content type in the response
      exchange.getResponseHeaders().put(Headers.CONTENT_TYPE, "application/json");

      // serialize the response object and set in the response
      exchange.setStatusCode(statusCode);
      exchange.getResponseSender().send(resp);
    }
}
```

**Step 9**: Note that a **Helper** class is used to manipulate some of the returned data.

Please create the **Helper.java** class in the same *handler* package:

```java
    package com.cibc.api.training.customers.handler;

    import java.util.Deque;
    import io.undertow.server.HttpServerExchange;

    public class Helper {

      private Helper() {
            throw new AssertionError();
        }

        static int getCustomerId(HttpServerExchange exchange) {
            Deque<String> values = exchange.getQueryParameters().get("customerID");
            if (values == null) {
                return 0;
            }

            String textValue = values.peekFirst();
            if (textValue == null) {
                return 0;
            }

            try {
                int parsedValue = Integer.parseInt(textValue);
                return parsedValue;
            } catch (NumberFormatException e) {
                return 0;
            }
        }

      static String getFirstName(HttpServerExchange exchange) {
            Deque<String> values = exchange.getQueryParameters().get("first-name");
            if (values == null) {
                return null;
            }

            String textValue = values.peekFirst();
            if (textValue == null) {
                return null;
            }

            return textValue;
        }

        static String getLastName(HttpServerExchange exchange) {
            Deque<String> values = exchange.getQueryParameters().get("last-name");
            if (values == null) {
                return null;
            }

            String textValue = values.peekFirst();
            if (textValue == null) {
                return null;
            }

            return textValue;
        }


      static String isNull(String s) {
        if (s == null)
          return "";
        else return s;
      }

    }

```

Note that in subsequent steps this code will be updated to not only get the
customer data but also interact with the other APIs to get account and transaction
information.

## Optional step (10-11): Inject the Oracle Driver into the API and Update the Maven build file
**Step 10**:  Inject the Oracle Driver into the API

Now that we have created the code in the service, we now must inject the
Oracle driver into the service.  This is done by creating a file named
**service.yml** which is located in the generated API resource configuration
directory (<root-reference-application>/customers/src/main/resources/config) and adding the
following content:

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

```

**Step 11**: Update the Maven build file.

The Maven build file needs to be updated with a number of dependent libraries for database access.

Please see the required changes to be made to the Maven pom.xml file:

```yml
    # properties

    <version.hikaricp>3.1.0</version.hikaricp>

    # for an Oracle database (Default when file is generated)
    <version.oracle>11.2.0.3</version.oracle>

    # for a MySQL database
    <version.mysql>6.0.5</version.mysql>

    # for a Postgres database
    <version.postgres>42.1.1</version.postgres>

    ...

    # Dependencies
    <dependency>
     <groupId>com.zaxxer</groupId>
     <artifactId>HikariCP</artifactId>
     <version>${version.hikaricp}</version>
    </dependency>

    # for an Oracle database (Default)
    <dependency>
       <groupId>com.oracle</groupId>
       <artifactId>ojdbc6</artifactId>
       <version>${version.oracle}</version>
    </dependency>
    # for an MySQL database
    <dependency>
       <groupId>mysql</groupId>
       <artifactId>mysql-connector-java</artifactId>
       <version>${version.mysql}</version>
    </dependency>
    # for an Postgres database
    <dependency>
       <groupId>org.postgresql</groupId>
       <artifactId>postgresql</artifactId>
       <version>${version.postgres}</version>
    </dependency>
    ...

```


> ** Step 10-11 alternative: generate automatically database artifacts **
Please note that steps 10 and 11 can be bypassed by automatically generating the database artifacts using the light-codegen generator.
To this end, please enable code generation for the database of your choice in the config.json file.

Ex.: Enable Oracle DB creation artifacts for the API implementation and H2 artifacts for testing, using the supportOracle, respectively supportH2ForTest flags:

```yml
{
	"name": "customers",
    	"version": "1.00.00",
    	"groupId": "training",
    	"artifactId": "customers",
    	"rootPackage": "com.cibc.api.training.customers",
    	"handlerPackage":"com.cibc.api.training.customers.handler",
    	"modelPackage":"com.cibc.api.training.customers.model",
    	"overwriteHandler": true,
    	"overwriteHandlerTest": true,
    	"overwriteModel": true,
    	"httpPort": 7020,
    	"enableHttp": false,
    	"httpsPort": 8453,
    	"enableHttps": true,
    	"enableRegistry": false,
    	"supportDb": true,
    	  "dbInfo": {
    	    "name": "oracle",
    	    "driverClassName": "oracle.jdbc.pool.OracleDataSource",
    	    "jdbcUrl": "jdbc:oracle:thin:@localhost:1521:XE",
    	    "username": "SYSTEM",
    	    "password": "oracle"
    	  },
        "supportH2ForTest": true,
        "supportClient": true   
}
```

## Build the API

Build the API by switching to the **/customers** folder and running:

```bash
    :> cd customers
    :> mvn clean install

    # Alternatively, you can build with a script provided in the /utl folder
    :> cd <training-root folder>/utl
    <reference-training root>/utl:> ./build.sh mvn customers
```
## Remember to start the Oracle database with an external configuration

Check whether the database is running by executing:
```bash
  :> docker ps
```

If it is stopped, change to the __reference application top-level folder__ and type:

```bash
    # Start the database with a generic name assigned to the container
    :> docker run -v $PWD/etc/oracledb/config:/docker-entrypoint-initdb.d -it -p 1521:1521 wnameless/oracle-xe-11g:16.04
```

## Run and Verify the API

To run the API, change directory to the API directory, and type the following:

```bash
    :> java -jar ./target/customers-1.00.00.jar

    # Alternatively, run from Maven
    :> mvn exec:exec
```

A "curl" command (identical to that in previous steps) will be executed.  Open
a terminal window and type the following:

```bash
    :> curl -k https://localhost:8453/v1/customers/1
```

A successful response will appear on your terminal containing the text:

```json
{
  "customers":{
    "firstName":"Martin",
    "lastName":"Fowler",
    "id":"1",
    "middleInitial":"M"
  }
}
```

## Continue to the next chapter

The next chapter is [Creating Docker Compose Files (API, respectively Database)](step-0.3.3.md).
