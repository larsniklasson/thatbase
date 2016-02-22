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
