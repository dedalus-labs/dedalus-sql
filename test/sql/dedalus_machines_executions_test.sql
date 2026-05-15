SET datestyle = 'ISO';
SET dedalus.api_key = 'My API Key';

SELECT *
FROM dedalus_machines_executions.create(machine_id := 'dm-3');

SELECT *
FROM dedalus_machines_executions.retrieve(
  machine_id := 'dm-3', execution_id := 'execution_id'
);

SELECT *
FROM dedalus_machines_executions.list(machine_id := 'dm-3')
LIMIT 42;

SELECT *
FROM dedalus_machines_executions.delete(
  machine_id := 'dm-3', execution_id := 'execution_id'
);

SELECT *
FROM dedalus_machines_executions.events(
  machine_id := 'dm-3', execution_id := 'execution_id'
)
LIMIT 42;

SELECT *
FROM dedalus_machines_executions.output(
  machine_id := 'dm-3', execution_id := 'execution_id'
);