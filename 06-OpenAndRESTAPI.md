# Kitura SOS Workshop

<p align="center">
<img src="https://www.ibm.com/cloud-computing/bluemix/sites/default/files/assets/page/catalog-swift.svg" width="120" alt="Kitura Bird">
</p>

<p align="center">
<a href= "http://swift-at-ibm-slack.mybluemix.net/">
    <img src="http://swift-at-ibm-slack.mybluemix.net/badge.svg"  alt="Slack">
</a>
</p>

## Workshop Table of Contents:

1. [Getting Started](./01-GettingStarted.md)
2. [Setting up the Server](./02-ServerSetUp.md)
3. [Setting up the Dashboard](./03-DashboardSetUp.md)
4. [Setting up the iOS Client](./04-iOSSetUp.md)
5. [Handling Status Reports and Disasters](./05-StatusReportsAndDisasters.md)
6. **[Setting up OpenAPI and REST API functionality](./06-OpenAndRESTAPI.md)**
7. [Build your app into a Docker image and deploy it on Kubernetes](./07-DockerAndKubernetes.md)
8. [Enable monitoring through Prometheus/Grafana](./08-PrometheusAndGrafana.md)

# Setting up OpenAPI and REST API functionality

## Try out OpenAPI in Kitura

With your Kitura server still running, open [http://localhost:8080/openapi/ui](http://localhost:8080/openapi/ui) and view SwaggerUI, a popular API development tool. SwaggerUI shows all the REST endpoints defined on your server.

You will see one route defined: the GET `/health` route. Click on the route to expand it, then click "Try it out!" to query the API from inside SwaggerUI.

You should see a Response Body in JSON format, like:

```
{
  "status": "UP",
  "details": [],
  "timestamp": "2019-09-07T14:38:07+0000"
}
```

and a Response Code of 200.

Congratulations, you have used SwaggerUI to query a REST API!

## Add Support for handling a `GET` request on `/users`

REST APIs typically consist of an HTTP request using a verb such as `POST`, `PUT`, `GET` or `DELETE` along with a URL and an optional data payload. The server then handles the request and responds with an optional data payload.

A request to load all of the stored data typically consists of a `GET` request with no data, which the server then handles and responds with an array of all the data in the store.

1. In `Application.swift`, add a `getAllHandler()` function to the `App` class that responds with an array of all the connected people as an array:
  ```swift
	func getAllHandler(completion: ([Person]?, RequestError?) -> Void) {
		return completion(self.disasterService.connectedPeople, nil)
	}
  ```

2. Register a handler for a `GET` request on `/users` that calls your new function.  Add the following at the end of the `postInit()`:  
   ```swift
	router.get("/users", handler: getAllHandler)
   ```

3. Restart your server and refresh SwaggerUI again and view your new GET route. Clicking "Try it out!" will return the empty array (`[]`), because there are no current connections to the server. Experiment with connecting to the server and using your GET method to see all the connections. REST APIs are easy!

## Add Support for handling a `GET` request on `/users/{id}`

For this request, we want to return all the info on a single specific user by using their unique id.

1. In `Application.swift`, add a `getOneHandler()` function to the `App` class that finds the person matching the given `id`. If the person isn't found, we return HTTP error code `404` (Not Found), otherwise we return the person:
  ```swift
	func getOneHandler(id: String, completion:(Person?, RequestError?) -> Void ) {
		guard let person = self.disasterService.connectedPeople.first(where: { $0.id == id}) else {
			return completion(nil, .notFound)
		}
		completion(person, nil)
	}
  ```

2. Register a handler for a `GET` request on `/users` that calls your new function.  Add the following at the end of the `postInit()`:  
   ```swift
	router.get("/users", handler: getOneHandler)
   ```

3. Restart your server and refresh SwaggerUI again and view your new GET route.

## Add Support for handling a `GET` request on `/stats`

For this request, we want to return several statistics about the server. We will display:

* The start time of the server
* The current time
* The percentage of connected users reported as safe
* The percentage of connected users reported as unsafe
* The percentage of connected users reported as unreported

1. In `Models.swift` add the following new structure definition. This is the data we will be returning as JSON.
    ```swift
    struct ServerStats: Codable {
        var safePercentage: Double
        var unsafePercentage: Double
        var unreportedPercentage: Double
        var startTime: String
        var currentTime: String
    }
    ```

2. Back in `Application.swift`, add a new property to the `App` class:
    ````swift
    var startDate = ""
    ````

3. Then, at the start of the `postInit()` function, add this code to initialize the property:
    ````swift
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T 'HH:mm:ss"
    self.startDate = dateFormatter.string(from: Date())
    ````

4. Add this new `getStats()` function in your `App` class:

    ```swift
    func getStats() -> ServerStats {
        let connectedPeople = self.disasterService.connectedPeople

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T 'HH:mm:ss"
        let currentDate = dateFormatter.string(from: Date())

        var result = ServerStats(safePercentage: 0.0,
                                                unsafePercentage: 0.0,
                                                unreportedPercentage: 0.0,
                                                startTime: self.startDate,
                                                currentTime: currentDate)

        let connectedCount = connectedPeople.count
        if connectedCount > 0 {
            var safeCount = 0
            var unsafeCount = 0
            var unreportedCount = 0

            for person in connectedPeople {
                if person.status.status == "Safe" {
                    safeCount += 1
                } else if person.status.status == "Unsafe" {
                    unsafeCount += 1
                } else {
                    unreportedCount += 1
                }
            }

            let connected = Double(connectedCount)
            result.safePercentage = (Double(safeCount) / connected) * 100
            result.unsafePercentage = (Double(unsafeCount) / connected) * 100
            result.unreportedPercentage = (Double(unreportedCount) / connected) * 100
        }
        return result
    }
    ```

5. Implement a `getStatsHandler()` function that responds with all the data. Add the following as a function in the `App` class:
    ```swift
    func getStatsHandler(completion: (ServerStats?, RequestError?) -> Void ) {
        return completion(getStats(), nil)
    }
    ```

6. Register a new handler for a `GET` request on `/stats` that returns the statistics.  Add the following at the end of the `postInit()` function:  
   ```swift
	router.get("/stats", handler: getStatsHandler)
   ```

7. Restart your server and refresh SwaggerUI again and view your new GET route. Try it out and see the statistics about your server!

# Next Steps

Continue to the [next page](./07-DockerAndKubernetes.md) to learn how to use Docker and Kubernetes.
