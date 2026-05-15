SET datestyle = 'ISO';
SET dedalus.api_key = 'My API Key';

SELECT *
FROM dedalus_machines.create(memory_mib := 0, storage_gib := 0, vcpu := 0);

SELECT *
FROM dedalus_machines.retrieve(machine_id := 'dm-3');

SELECT *
FROM dedalus_machines.update(machine_id := 'dm-3');

SELECT *
FROM dedalus_machines.list()
LIMIT 42;

SELECT *
FROM dedalus_machines.delete(machine_id := 'dm-3');

SELECT *
FROM dedalus_machines.sleep(machine_id := 'dm-3');

SELECT *
FROM dedalus_machines.wake(machine_id := 'dm-3');

SELECT *
FROM dedalus_machines.watch(machine_id := 'dm-3');