EXTENSION = dedalus
EXTVERSION = 0.0.1

DATA = sql/build/$(EXTENSION)--$(EXTVERSION).sql
DOCS = README.md
PG_CONFIG = pg_config

TESTS        = $(wildcard test/sql/*.sql)
REGRESS      = $(patsubst test/sql/%.sql,%,$(TESTS))
REGRESS_OPTS = --inputdir=test --outputdir=regress --schedule=test/parallel_schedule

PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

all: $(DATA)

$(DATA): $(filter-out $(DATA).sql, $(wildcard sql/*.sql))
	mkdir -p sql/build
	cat $^ > $@

dist:
	git archive --format zip --prefix=$(EXTENSION)-$(EXTVERSION)/ -o $(EXTENSION)-$(EXTVERSION).zip HEAD