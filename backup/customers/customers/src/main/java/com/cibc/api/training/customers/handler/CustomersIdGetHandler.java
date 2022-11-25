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