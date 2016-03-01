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

-- DAT137 has no students at this point and maxNbrStudents is 1.
-- Is the course full?
-- Should NOT give error
INSERT INTO registrations (studentpersonnumber, coursecode) VALUES
  ('199001269088', 'DAT137');
-- Should place person in queue
INSERT INTO registrations (studentpersonnumber, coursecode) VALUES
  ('195809218581', 'DAT137');

-- The student should now be in wait list, should not be empty
SELECT *
FROM registrations
WHERE studentpersonnumber = '195809218581' AND coursecode = 'DAT137';

-- Registration for normal course
insert into registrations(studentpersonnumber, coursecode) VALUES ('195809218581', 'MVE922');

SELECT *
FROM registrations
WHERE studentpersonnumber = '195809218581' AND coursecode = 'MVE922';


-- delete a registered person and there is one person in the queue.
delete from registrations where studentpersonnumber='199001269088' and coursecode= 'DAT137';
-- Person in waitlist should now be registered
SELECT *
FROM registrations
WHERE coursecode = 'DAT137';


-- unregister person from a course that is not a limited course.
DELETE from registrations where studentpersonnumber='195809218581' and coursecode= 'MVE922';

-- should be empty
SELECT *
FROM registrations
WHERE coursecode = 'MVE922' and studentpersonnumber='195809218581';


-- HP95 is an empty course with maxnbr 1. We register 2 students directly without using registrations view.
INSERT into studentcourseregistered VALUES ('195809218581', 'HP95'), ('199001269088', 'HP95');

-- try register another student through registrations view. Person should be placed in waitlist.
INSERT into registrations (studentpersonnumber, coursecode) values ('199405269088', 'HP95');
INSERT into registrations (studentpersonnumber, coursecode) values ('197809218581', 'HP95');

-- unregister one person. Waitlist should not be modified.
DELETE from registrations where studentpersonnumber='195809218581' and coursecode= 'HP95';

-- should be three persons, one registered and two in waitlist
select * from registrations where coursecode= 'HP95';

-- unregister another one. now person 199405269088 in queue should be registered
DELETE from registrations where studentpersonnumber='199001269088' and coursecode= 'HP95';
-- Unregister twice, which should be tested according to task 5
DELETE from registrations where studentpersonnumber='199001269088' and coursecode= 'HP95';
-- Should be empty
select * from registrations where coursecode= 'HP95' AND studentpersonnumber = '199001269088';

-- Register again, should be last in wait list
INSERT into registrations (studentpersonnumber, coursecode) values ('199001269088', 'HP95');

-- 199001269088 should have position 2
select * from coursequeuepositions where coursecode= 'HP95';