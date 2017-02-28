# deployer
Capistrano based deployer tool. This uses health check api to remove and add to load balancer/HAproxy and supervisor to run app as service.

1. Make sure to add `POST /health/up` api, to send `200 OK` as health check response.
2. Make sure to add `POST /health/down` api, to send `503 Service Unavailable` response.
3. Deployer's deploy job will mark down your machine wait for configured wait time for traffic to stop.
4. Once traffic is stopped it stops supervisor service for app.
5. After default port `8080` does not have any application running, it starts supervisor (Alternatively you can do `supervisorctl restart app`)
6. There is a provision for dry_run flag if you want to post deployment sanity before adding traffic.
7. Traffic is added and traffic check is done.
8. Once traffic is up, it proceeds for next machine deployment.

Note: This job uses classic capistrano deploy task for code management.
There is a provision for adding env files as `build:setEnvFiles` task