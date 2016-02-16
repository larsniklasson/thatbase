DROP VIEW IF EXISTS StudentsFollowing, FinishedCourses, Registrations, PassedCourses, UnreadMandatory;

CREATE VIEW StudentsFollowing AS
  SELECT
    s.*,
    sbr.branchname
  FROM Student s
    LEFT JOIN StudentBranchRelation sbr ON sbr.personnumber = s.personnumber

CREATE VIEW FinishedCourses AS
  SELECT
    s.personnumber,
    s.name AS studentName,
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
  FROM studentcoursecompleted scc
  WHERE scc.grade != 'U';

CREATE VIEW UnreadMandatory AS
  SELECT
    s.personnumber,
    s.name AS studentName,
    pm.coursecode
  FROM student s
    LEFT JOIN programmemandatory pm ON pm.programmename = s.programmename
    LEFT JOIN studentcoursecompleted scc ON scc.studentpersonnumber = s.personnumber AND scc.coursecode = pm.coursecode
  WHERE scc.grade IS NULL OR scc.grade = 'U'
  UNION ALL
  SELECT
    s.personnumber,
    s.name AS studentName,
    scc.coursecode
  FROM student s
    LEFT JOIN studentbranchrelation sbr ON sbr.personnumber = s.personnumber
    LEFT JOIN branchmandatory bm ON bm.branchname = sbr.branchname AND bm.programmename = sbr.programmename
    LEFT JOIN studentcoursecompleted scc ON scc.studentpersonnumber = s.personnumber AND scc.coursecode = bm.coursecode
  WHERE (scc.grade IS NULL OR scc.grade = 'U') AND bm.coursecode IS NOT NULL;
