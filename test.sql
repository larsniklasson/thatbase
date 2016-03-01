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