SELECT
  s.name,
  s.personnumber,
  -- Total number of credits
  (SELECT SUM(c.credit)
   FROM studentcoursecompleted scc
     INNER JOIN course c ON c.coursecode = scc.coursecode
   WHERE scc.studentpersonnumber = s.personnumber
   AND scc.grade != 'U'
   GROUP BY s.personnumber) AS creditSum,

  -- Total number of math credits
  (SELECT SUM(c.credit) as foo
   FROM studentcoursecompleted scc
     INNER JOIN course c ON c.coursecode = scc.coursecode
     INNER JOIN courseclassification cc ON cc.coursecode = c.coursecode AND cc.classification = 'Math'
   WHERE scc.studentpersonnumber = s.personnumber
     AND scc.grade != 'U'
   GROUP BY s.personnumber) AS mathCreditSum,

  COUNT(um.personnumber)    AS unreadMandatorySum,
  CASE WHEN COUNT(um.personnumber) = 0 AND sbr.branchname IS NOT NULL
    THEN '1'
  ELSE '0'
  END                       AS canGraduate
FROM student s
  LEFT JOIN unreadmandatory um ON um.personnumber = s.personnumber
  LEFT JOIN studentcoursecompleted scc ON scc.studentpersonnumber = s.personnumber
  LEFT JOIN studentbranchrelation sbr ON sbr.personnumber = s.personnumber
GROUP BY s.personnumber, sbr.branchname;

