-- Have student passed all required courses?
-- Should give error
INSERT INTO registrations (studentpersonnumber, coursecode) VALUES
  ('195809218581', 'DAT060');

INSERT INTO StudentCourseCompleted (studentpersonnumber, coursecode, grade) VALUES
  ('195809218581', 'EDA433', '5'),
  ('195809218581', 'TMA265', '3');

-- Should now be OK
INSERT INTO registrations (studentpersonnumber, coursecode) VALUES
  ('195809218581', 'DAT060');

-- Have student already passed course?
-- Should give error
INSERT INTO registrations (studentpersonnumber, coursecode) VALUES
  ('195809218581', 'EDA433');

-- Student already in wait list?
-- Should give error
INSERT INTO registrations (studentpersonnumber, coursecode) VALUES
  ('199001269088', 'TMA265');

-- Is the course full?
-- Should NOT give error
INSERT INTO registrations (studentpersonnumber, coursecode) VALUES
  ('199001269088', 'DAT137');
-- Should place person in queue
INSERT INTO registrations (studentpersonnumber, coursecode) VALUES
  ('195809218581', 'DAT137');
