SET datestyle = 'ISO';
SET dedalus.api_key = 'My API Key';

SELECT *
FROM dedalus_usage.retrieve();

SELECT *
FROM dedalus_usage.machine_compute();

SELECT *
FROM dedalus_usage.machine_storage();