## Google Cloud SQL for PostgreSQL

Google Cloud SQL for PostgreSQL is a fully-managed database service that makes it easy to set up, maintain, manage, and administer PostgreSQL relational databases on Google Cloud Platform.

### Design Decisions

This Terraform setup for managing Google Cloud SQL for PostgreSQL includes the following design decisions:

- **Instance Configuration**: Custom instance tiers and disk types are supported. Disk resizing is disabled by default to give more control over cost management.
- **Database Configuration**: UTF-8 encoding and standard collation for PostgreSQL databases.
- **Security**: SSL requirements for IP configuration are turned off to simplify connectivity. However, using private IP addresses ensures security within the VPC.
- **Backup Management**: Automated backups are enabled with retention settings specified by the user.
- **Insights Configuration**: Query Insights enabled, with an increased query string length.
- **Maintenance Windows**: Set to Tuesdays at 2 AM by default.
- **Monitoring and Alerts**: Set up for critical metrics like CPU utilization, disk capacity, and memory usage with customizable thresholds.

### Runbook

#### Unable to Connect to PostgreSQL Database

When you are having trouble connecting to your PostgreSQL database instance, it could be due to various reasons, such as network issues or insufficient permissions.

1. Check the connectivity using Google Cloud SDK:

```sh
gcloud sql instances describe [INSTANCE_NAME] --project [PROJECT_ID]
```

Check for `privateIpAddress` and ensure it matches the IP you are using to connect. 

2. Ping the instance to ensure it's reachable:

```sh
ping [privateIpAddress]
```

You should see responses if the instance is reachable; otherwise, investigate network settings.

3. Ensure the PostgreSQL service is running and accepting connections:

```sh
gcloud sql instances list --filter="name:[INSTANCE_NAME]" --format="table[box](name, region, databaseVersion, state)"
```

The `state` should be `RUNNABLE`.

#### Unable to Authenticate to the Database

If you can’t authenticate to your PostgreSQL database, it could be due to incorrect credentials or revoked access.

1. List the users for the database instance:

```sh
gcloud sql users list --instance=[INSTANCE_NAME] --project=[PROJECT_ID]
```

Confirm that your user is listed.

2. Reset the password for the user if necessary:

```sh
gcloud sql users set-password [USERNAME] '%' --instance=[INSTANCE_NAME] --password=[NEW_PASSWORD] --project=[PROJECT_ID]
```

This command will reset the user's password. Ensure it matches the one you are using in your connection string.

3. Test the connection with `psql`:

```sh
psql "host=[privateIpAddress] port=5432 dbname=default user=[USERNAME] password=[NEW_PASSWORD]"
```

#### High CPU Utilization

Monitoring shows high CPU utilization which could point to various performance issues.

1. Check the running queries to identify resource-intensive operations:

```sql
SELECT pid, usename, application_name, client_addr, backend_start, query_start, state_change, wait_event, state, backend_xid, query 
FROM pg_stat_activity 
WHERE state = 'active' 
ORDER BY query_start;
```

Identify long-running or resource-intensive queries and optimize them.

2. Examine system resource consumption:

```sql
SELECT * FROM pg_stat_activity;
```

3. Create indexes to speed up frequently run queries.

```sql
CREATE INDEX idx_name ON table_name(column_name);
```

#### Disk Space Issues

Identify high disk usage and take action to clean up or resize space.

1. Check the disk usage on your Cloud SQL instance:

```sh
gcloud sql instances describe [INSTANCE_NAME] --project [PROJECT_ID]
```

Look for `diskSizeGb` and `dataDiskType`.

2. Use PostgreSQL commands to find large tables and optimize them:

```sql
SELECT table_schema || '.' || table_name AS relation,
pg_size_pretty(pg_relation_size(table_schema || '.' || table_name)) AS size
FROM information_schema.tables
ORDER BY pg_relation_size(table_schema || '.' || table_name) DESC
LIMIT 10;
```

Identify large tables and possibly perform `VACUUM`.

```sql
VACUUM FULL [table_name];
```

3. If necessary, resize the disk from Google Cloud Console or with the gcloud command:

```sh
gcloud sql instances patch [INSTANCE_NAME] --storage-auto-increase 
```

Enable this to ensure your instance can scale automatically and avoid downtime due to reaching storage limits.

