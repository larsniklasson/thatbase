drop table if exists Department, Programme, DepartmentProgramme, Branch, Course,
 LimitedCourse, Classification, CourseClassification,
 CoursePrerequisites , ProgrammeMandatory,
 BranchMandatory,
 BranchRecommended, Student, StudentBranchRelation,StudentCourseCompleted,
StudentCourseRegistered, CourseWaitList CASCADE;

--not sure about naming conventions. Also some table names and attribute names
-- aren't very good

create table Department (
	abbreviation text primary key check (abbreviation != ''),
	name text unique not null check (name != '')
);

create table Programme (
	name text primary key check (name != ''),
	abbreviation text not null check (abbreviation != '')
);

create table DepartmentProgramme (
	departmentAbbr text references Department(abbreviation),
	programmeName text references Programme(name),
	primary key (departmentAbbr, programmeName)
);


create table Branch (
	name text check (name != ''),
	programmeName text,
	primary key (name, programmeName),
	foreign key (programmeName) references Programme(name)
);

create table Course (
	courseCode text primary key check (courseCode != ''),
	departmentAbbr text references Department(abbreviation) not null,
	name text not null check (name != ''),
	credit double precision not null check (credit >= 0)
);

create table LimitedCourse (
	courseCode text primary key references Course(courseCode),
	maxNbrStudents int not null check (maxNbrStudents >= 0)
);

create table Classification (
	classification text primary key check (classification != '')
);

create table CourseClassification (
	courseCode text references Course(courseCode),
	classification text references Classification(classification),
	primary key (courseCode, classification)
);

create table CoursePrerequisites (
	courseCode text references Course(courseCode),
	coursePrerequisiteCode text references Course(courseCode),
	primary key (courseCode,coursePrerequisiteCode)
);

create table ProgrammeMandatory (
	programmeName text references Programme(name),
	courseCode text references Course(courseCode),
	primary key(programmeName, courseCode)
);

create table BranchMandatory (
	branchName text,
	programmeName text,
	courseCode text references Course(courseCode),
	primary key(branchName, courseCode, programmeName),
	foreign key (branchName, programmeName) references Branch(name, programmeName)
);

create table BranchRecommended (
	branchName text,
	programmeName text,
	courseCode text references Course(courseCode),
	primary key(branchName, courseCode, programmeName),
	foreign key (branchName, programmeName) references Branch(name, programmeName)
);

create table Student (
	personNumber text primary key check (personNumber ~ '^\d{12}$'), --YYYYMMDDXXXX
	name text not null check (name != ''),  --first name and surname maybe
	username text unique not null check (username != ''),
	programmeName text references Programme(name),
	unique (personNumber, programmeName)

);

create table StudentBranchRelation (
	personNumber text primary key,
	branchName text not null,
	programmeName text not null,
	foreign key (personNumber,programmeName) references Student(personNumber, programmeName),
	foreign key (branchName, programmeName) references Branch(name, programmeName)
);

create table StudentCourseCompleted (
	studentPersonNumber text references Student(personNumber),
	courseCode text references Course(courseCode),
	grade text not null check (grade ~ '^(U|3|4|5)$'),  --grades U,3,4,5
	primary key(studentPersonNumber, courseCode)
);

create table StudentCourseRegistered (
	studentPersonNumber text references Student(personNumber),
	courseCode text references Course(courseCode),
	primary key(studentPersonNumber, courseCode)
);

create table CourseWaitList (
	courseCode text references LimitedCourse(courseCode),
	studentPersonNumber text references Student(personNumber),
	position int check (position > 0), --serial
	primary key (courseCode, studentPersonNumber),
	unique(courseCode, position)
);


DROP VIEW IF EXISTS StudentsFollowing, FinishedCourses, Registrations, PassedCourses, UnreadMandatory, PathToGraduation,
CourseQueuePositions;

CREATE VIEW StudentsFollowing AS
  SELECT
    s.*,
    sbr.branchname
  FROM Student s
    NATURAL LEFT JOIN StudentBranchRelation sbr;

CREATE VIEW FinishedCourses AS
  SELECT
    s.personnumber,
    s.name AS studentName,
    c.coursecode,
    c.name AS courseName,
    c.credit,
    scc.grade
  FROM StudentCourseCompleted scc
    INNER JOIN Student s ON s.personnumber = scc.studentpersonnumber
    INNER JOIN Course c ON c.coursecode = scc.coursecode;

CREATE VIEW Registrations AS
  SELECT
    scr.studentpersonnumber,
    scr.coursecode,
    'registered' AS status
  FROM StudentCourseRegistered scr
  UNION
  SELECT
    cwl.studentpersonnumber,
    cwl.coursecode,
    'waiting' AS status
  FROM CourseWaitList cwl;

CREATE VIEW PassedCourses AS
  SELECT *
  FROM FinishedCourses fc
  WHERE fc.grade != 'U';

CREATE VIEW UnreadMandatory AS
  SELECT
    s.personnumber,
    pm.coursecode
  FROM student s
    INNER JOIN programmemandatory pm ON s.programmename = pm.programmename
  UNION
  SELECT
    s.personnumber,
    bm.coursecode
  FROM student s
    JOIN studentbranchrelation sbr ON s.personnumber = sbr.personnumber AND s.programmename = sbr.programmename
    INNER JOIN branchmandatory bm ON bm.programmename = sbr.programmename AND bm.branchname = sbr.branchname
  EXCEPT
  SELECT
    personnumber,
    coursecode
  FROM passedcourses;

CREATE VIEW PathToGraduation AS
  SELECT
    s.name,
    s.personnumber,
    coalesce(creditCount, 0)              AS creditCount,
    -- 0 if null
    unreadMandatoryCount,
    coalesce(mathCoursesCreditSum, 0)     AS mathCoursesCreditSum,
    coalesce(researchCoursesCreditSum, 0) AS researchCoursesCreditSum,
    coalesce(seminarCourseCount, 0)       AS seminarCourseCount,

    CASE WHEN sbr.branchname IS NOT NULL AND mathCoursesCreditSum >= 20 AND researchCoursesCreditSum >= 10 AND
              seminarCourseCount >= 1 AND recommendedCourseCreditSum >= 10
      THEN
        'Yes'
    ELSE
      'No'
    END                                   AS canGraduate

  FROM student s

    -- Count total number of credits
    LEFT JOIN (
                SELECT
                  fc.personnumber,
                  SUM(fc.credit) AS creditCount
                FROM finishedcourses fc
                WHERE fc.grade != 'U'
                GROUP BY fc.personnumber
              ) cc ON cc.personnumber = s.personnumber

    -- Count unread mandatory courses
    LEFT JOIN (
                SELECT
                  s.personnumber,
                  COUNT(um.personnumber) AS unreadMandatoryCount
                FROM student s
                  LEFT JOIN unreadmandatory um ON um.personnumber = s.personnumber
                GROUP BY s.personnumber

              ) umc ON umc.personnumber = s.personnumber

    -- Count total number of credits for math courses
    LEFT JOIN (
                SELECT
                  fc.personnumber,
                  SUM(fc.credit) AS mathCoursesCreditSum
                FROM finishedcourses fc
                  INNER JOIN courseclassification cc
                    ON cc.coursecode = fc.coursecode AND fc.grade != 'U' AND cc.classification = 'Math'
                GROUP BY fc.personnumber
              ) mcc ON mcc.personnumber = s.personnumber

    -- Count total number of credits for research courses
    LEFT JOIN (
                SELECT
                  fc.personnumber,
                  SUM(fc.credit) AS researchCoursesCreditSum
                FROM finishedcourses fc
                  INNER JOIN courseclassification cc
                    ON cc.coursecode = fc.coursecode AND fc.grade != 'U' AND cc.classification = 'Research'
                GROUP BY fc.personnumber
              ) rcc ON rcc.personnumber = s.personnumber

    -- Count total number of seminar courses
    LEFT JOIN (
                SELECT
                  fc.personnumber,
                  COUNT(fc.personnumber) AS seminarCourseCount
                FROM finishedcourses fc
                  INNER JOIN courseclassification cc
                    ON cc.coursecode = fc.coursecode AND cc.classification = 'Seminar' -- Exkl. U
                GROUP BY fc.personnumber
              ) scc ON scc.personnumber = s.personnumber

    -- Count total number of credits for recommended courses
    LEFT JOIN (

                SELECT
                  s.personnumber,
                  SUM(c.credit) AS recommendedCourseCreditSum
                FROM student s
                  INNER JOIN studentbranchrelation sbr ON sbr.personnumber = s.personnumber
                  INNER JOIN branchrecommended br
                    ON br.branchname = sbr.branchname AND br.programmename = sbr.programmename
                  INNER JOIN studentcoursecompleted scc
                    ON scc.studentpersonnumber = s.personnumber AND scc.grade != 'U' AND scc.coursecode = br.coursecode
                  INNER JOIN course c ON c.coursecode = scc.coursecode
                GROUP BY s.personnumber
              ) src ON src.personnumber = s.personnumber

    LEFT JOIN studentbranchrelation sbr ON sbr.personnumber = s.personnumber;


CREATE VIEW CourseQueuePositions AS
  SELECT *
  FROM coursewaitlist cwl
  ORDER BY coursecode, position;

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
