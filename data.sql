TRUNCATE TABLE Department, Programme, DepartmentProgramme, Branch, Course,
LimitedCourse, Classification, CourseClassification,
CoursePrerequisites, ProgrammeMandatory,
BranchMandatory,
BranchRecommended, Student, StudentBranchRelation, StudentCourseCompleted,
StudentCourseRegistered, CourseWaitList;

INSERT INTO Department (abbreviation, name) VALUES
  ('CSE', 'Computer Science and Engineering'),
  ('MVE', 'Math');

INSERT INTO Programme (name, abbreviation) VALUES
  ('Informationsteknik', 'IT');

INSERT INTO DepartmentProgramme (departmentabbr, programmename) VALUES
  ('CSE', 'Informationsteknik');

INSERT INTO Course (coursecode, departmentabbr, name, credit) VALUES
  ('EDA433', 'CSE', 'Grundläggande datorteknik', 7.5),
  ('TDA545', 'CSE', 'Objektorienterad programvaruutveckling', 7.5),
  ('TMV200', 'MVE', 'Diskret matematik', 7.5),
  ('DAT060', 'CSE', 'Matematisk logik för datavetenskap', 7.5),
  ('EDA122', 'CSE', 'Feltoleranta datorsystem', 7.5),
  ('FFR135', 'CSE', 'Artificiella neurala nätverk', 7.5),
  ('TMA265', 'MVE', 'Numerisk linjär algebra', 7.5),
  ('MVE922', 'CSE', 'Komplexa uträkningar med datasystem', 7.5),
  ('DAT137', 'CSE', 'En begränsad kurs om datorsystem', 7.5),
  ('HP95', 'CSE', 'Harry Potter och hans världar', 7.5);

INSERT INTO LimitedCourse (coursecode, maxnbrstudents) VALUES
  ('TMA265', 50),
  ('FFR135', 100),
  ('DAT137', 1),
  ('HP95', 1);

INSERT INTO CoursePrerequisites (coursecode, courseprerequisitecode) VALUES
  ('DAT060', 'TMA265'),
  ('DAT060', 'EDA433');

INSERT INTO Classification (classification) VALUES
  ('Math'),
  ('Computer Science'),
  ('Research'),
  ('Seminar');

INSERT INTO CourseClassification (coursecode, classification) VALUES
  ('EDA433', 'Computer Science'),
  ('TMV200', 'Math'),
  ('TMV200', 'Research'),
  ('TDA545', 'Computer Science'),
  ('TDA545', 'Math'),
  ('DAT060', 'Computer Science'),
  ('DAT060', 'Math'),
  ('DAT060', 'Research'),
  ('DAT060', 'Seminar');


INSERT INTO ProgrammeMandatory (programmename, coursecode) VALUES
  ('Informationsteknik', 'EDA433'),
  ('Informationsteknik', 'TDA545'),
  ('Informationsteknik', 'TMV200');
;

INSERT INTO Branch (name, programmename) VALUES
  ('Software Engineering', 'Informationsteknik'),
  ('Computer Systems and Networks', 'Informationsteknik');

INSERT INTO BranchMandatory (branchname, programmename, coursecode) VALUES
  ('Software Engineering', 'Informationsteknik', 'DAT060'),
  ('Computer Systems and Networks', 'Informationsteknik', 'EDA122');

INSERT INTO BranchRecommended (branchname, programmename, coursecode) VALUES
  ('Software Engineering', 'Informationsteknik', 'FFR135'),
  ('Software Engineering', 'Informationsteknik', 'MVE922'),
  ('Computer Systems and Networks', 'Informationsteknik', 'TMA265');

INSERT INTO Student (personnumber, name, username, programmename) VALUES
  ('199405269088', 'Daniel Sunnerberg', 'dansunn', 'Informationsteknik'),
  ('199305269088', 'Lars Niklasson', 'larnikl', 'Informationsteknik'),
  ('199001269088', 'Josef Abrahamsson', 'jorabr', 'Informationsteknik'),
  ('197809218581', 'John Doe', 'johdoe', 'Informationsteknik'),
  ('195809218581', 'Abraham Lat', 'arblat', 'Informationsteknik');

INSERT INTO StudentBranchRelation (personnumber, branchname, programmename) VALUES
  ('199305269088', 'Software Engineering', 'Informationsteknik');

INSERT INTO StudentCourseCompleted (studentpersonnumber, coursecode, grade) VALUES
  ('199405269088', 'EDA433', '5'),
  ('199405269088', 'TMV200', 'U'),
  ('199405269088', 'TMA265', '3'),

  ('199305269088', 'EDA433', '5'),
  ('199305269088', 'TDA545', '5'),
  ('199305269088', 'TMV200', '5'),
  ('199305269088', 'DAT060', '5'),
  ('199305269088', 'EDA122', '3'),
  ('199305269088', 'FFR135', '5'),
  ('199305269088', 'MVE922', '5'),
  ('199305269088', 'TMA265', '5'),

  ('199001269088', 'EDA433', '5'),
  ('199001269088', 'TDA545', '5'),
  ('199001269088', 'TMV200', '5'),
  ('199001269088', 'EDA122', 'U'),

  ('197809218581', 'EDA433', '5'),
  ('197809218581', 'TDA545', '5'),
  ('197809218581', 'EDA122', '3');

INSERT INTO StudentCourseRegistered (studentpersonnumber, coursecode) VALUES
  ('199405269088', 'DAT060'),
  ('195809218581', 'TMA265');

INSERT INTO CourseWaitList (coursecode, studentpersonnumber, position) VALUES
  ('TMA265', '199001269088', 1),
  ('FFR135', '197809218581', 1),
  ('FFR135', '199405269088', 2);
