-- Must have passed 10 credits from recomended
-- 10 credits from research
-- 1 seminar course

SELECT
  s.name,
  coalesce(creditCount, 0)              AS creditCount,
  -- 0 if null
  unreadMandatoryCount,
  coalesce(mathCoursesCreditSum, 0)     AS mathCoursesCreditSum,
  coalesce(researchCoursesCreditSum, 0) AS researchCoursesCreditSum,
  coalesce(seminarCourseCount, 0)       AS seminarCourseCount,

  CASE WHEN sbr.branchname IS NOT NULL AND mathCoursesCreditSum >= 20 AND researchCoursesCreditSum >= 10 AND
            seminarCourseCount >= 1 AND recommendedCourseCreditSum >= 10
    THEN
      '1'
  ELSE
    '0'
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