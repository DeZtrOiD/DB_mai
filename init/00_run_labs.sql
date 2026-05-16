
CREATE SCHEMA IF NOT EXISTS lab_1;
-- CREATE SCHEMA IF NOT EXISTS lab_2;
-- CREATE SCHEMA IF NOT EXISTS lab_3;
CREATE SCHEMA IF NOT EXISTS lab_4;

\i /lab_1/01_lab_1_ddl.sql

-- \i /lab_2/02_lab_2_ddl.sql
-- \i /lab_2/03_lab_2_init.sql

-- \i /lab_3/04_lab_3_ddl.sql
-- \i /lab_3/05_triggers.sql
-- \i /lab_3/06_func.sql
-- \i /lab_3/07_lab_3_init.sql


CREATE EXTENSION IF NOT EXISTS pg_trgm;

\i /lab_4/08_lab_4_ddl.sql
\i /lab_4/09_lab_4_init.sql
\i /lab_4/10_lab_4_triggers.sql
\i /lab_4/10_lab_4_func.sql
\i /lab_4/10_lab_4_view.sql

