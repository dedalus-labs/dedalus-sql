SET datestyle = 'ISO';
SET dedalus.api_key = 'My API Key';

SELECT *
FROM dedalus_machines.create();

SELECT *
FROM dedalus_machines.retrieve(
  machine_id := 'dm-ecc2efdd-ddfa-31a9-c6f1-b833d337aa7c'
);

SELECT *
FROM dedalus_machines.update(
  machine_id := 'dm-ecc2efdd-ddfa-31a9-c6f1-b833d337aa7c'
);

SELECT *
FROM dedalus_machines.list()
LIMIT 42;

SELECT *
FROM dedalus_machines.delete(
  machine_id := 'dm-ecc2efdd-ddfa-31a9-c6f1-b833d337aa7c'
);

SELECT *
FROM dedalus_machines.sleep(
  machine_id := 'dm-ecc2efdd-ddfa-31a9-c6f1-b833d337aa7c'
);

SELECT *
FROM dedalus_machines.wake(
  machine_id := 'dm-ecc2efdd-ddfa-31a9-c6f1-b833d337aa7c'
);