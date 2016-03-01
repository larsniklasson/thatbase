DROP TRIGGER IF EXISTS on_registered ON registrations;
DROP TRIGGER IF EXISTS on_unregistered ON registrations;
DROP FUNCTION IF EXISTS on_registered() CASCADE;
DROP FUNCTION IF EXISTS on_unregistered() CASCADE;


CREATE FUNCTION on_registered()
  RETURNS TRIGGER AS $on_registered$
BEGIN

  -- Verify that the student have passed all prerequired courses
  IF ((SELECT COUNT(cpr.courseprerequisitecode) - COUNT(scc.coursecode) AS coursesLeftToRead
       FROM student s
         LEFT JOIN courseprerequisites cpr ON cpr.coursecode = new.coursecode
         LEFT JOIN studentcoursecompleted scc
           ON scc.studentpersonnumber = s.personnumber AND scc.coursecode = cpr.courseprerequisitecode AND
              scc.grade != 'U'
       WHERE s.personnumber = new.studentpersonnumber) != 0)

  THEN RAISE EXCEPTION 'Student have not passed prerequired courses %, %', new.studentpersonnumber, new.coursecode;
  END IF;

  -- Have student already passed this course?
  IF ((SELECT COUNT(scc.studentpersonnumber)
       FROM studentcoursecompleted scc
       WHERE scc.studentpersonnumber = new.studentpersonnumber
             AND scc.coursecode = new.coursecode
             AND scc.grade != 'U') != 0)
  THEN RAISE EXCEPTION 'Student have already passed this course.';
  END IF;

  -- Is it a limited course?
  IF ((SELECT COUNT(coursecode)
       FROM limitedcourse lc
       WHERE lc.coursecode = new.coursecode) = 1)
  THEN

    -- Is the student already in the waitlist?
    IF ((SELECT COUNT(cwl.studentpersonnumber)
         FROM coursewaitlist cwl
         WHERE cwl.coursecode = new.coursecode AND cwl.studentpersonnumber = new.studentpersonnumber) != 0)
    THEN
      RAISE EXCEPTION 'Student already in wait list';
    END IF;

    -- Is the student already registered?
    IF ((SELECT COUNT(coursecode)
         FROM studentcourseregistered
         WHERE coursecode = new.coursecode
               AND studentpersonnumber = new.studentpersonnumber) != 0)
    THEN
      RAISE EXCEPTION 'Student already registered';
    END IF;

    -- Is the course already full
    IF ((SELECT lc.maxnbrstudents - COUNT(scc.coursecode) AS spotsLeft
         FROM course c
           INNER JOIN limitedcourse lc ON lc.coursecode = c.coursecode
           LEFT JOIN studentcourseregistered scc ON c.coursecode = scc.coursecode
         WHERE c.coursecode = new.coursecode
         GROUP BY lc.maxnbrstudents) <= 0)
    THEN
      -- Add to wait list
      INSERT INTO coursewaitlist (coursecode, studentpersonnumber) VALUES (new.coursecode, new.studentpersonnumber);
      RAISE NOTICE 'Course was full. Student placed in wait list.';

      --set position last

      UPDATE coursewaitlist
      SET position = (SELECT coalesce(max(position) + 1, 1)
                      FROM coursewaitlist
                      WHERE coursecode = new.coursecode)
      WHERE new.studentpersonnumber = studentpersonnumber AND coursecode = new.coursecode;

      -- Don't insert the student, they are now put in waiting list instead
      RETURN NULL;
    END IF;

  END IF;

  INSERT INTO studentcourseregistered (studentpersonnumber, coursecode)
  VALUES (NEW.studentpersonnumber, new.coursecode);
  RETURN NULL;
END;
$on_registered$ LANGUAGE plpgsql;

CREATE FUNCTION on_unregistered()
  RETURNS TRIGGER AS $on_unregistered$
DECLARE
  queuePersonNumber TEXT;

  newPosition       INT;
  rec               TEXT;
BEGIN

  DELETE FROM studentcourseregistered scr
  WHERE
    scr.studentpersonnumber = old.studentpersonnumber AND scr.coursecode = old.coursecode;

  -- Is it a limited course?
  IF ((SELECT COUNT(coursecode)
       FROM limitedcourse lc
       WHERE lc.coursecode = old.coursecode) = 1)
  THEN

    -- there is a student in the wait list AND there is an open spot in the course after the student has been unregistered
    IF ((SELECT COUNT(cwl.coursecode)
         FROM coursewaitlist cwl
         WHERE cwl.coursecode = old.coursecode) > 0 AND (SELECT lc.maxnbrstudents - COUNT(scc.coursecode) AS spotsLeft
                                                         FROM course c
                                                           INNER JOIN limitedcourse lc ON lc.coursecode = c.coursecode
                                                           LEFT JOIN studentcourseregistered scc
                                                             ON c.coursecode = scc.coursecode
                                                         WHERE c.coursecode = old.coursecode
                                                         GROUP BY lc.maxnbrstudents) > 0)
    THEN

      -- Find next person in wait list
      queuePersonNumber := (SELECT cwl.studentpersonnumber
                            FROM coursewaitlist cwl
                            WHERE cwl.coursecode = old.coursecode
                            ORDER BY cwl.position ASC
                            LIMIT 1);

      -- Remove person from wait list and register them on the course
      DELETE FROM coursewaitlist cwl
      WHERE cwl.studentpersonnumber = queuePersonNumber AND cwl.coursecode = old.coursecode;
      INSERT INTO studentcourseregistered (studentpersonnumber, coursecode) VALUES (queuePersonNumber, old.coursecode);
      RAISE NOTICE 'Registered first person in the waitlist.';

      --FIX queuepositions


      newPosition := 1;
      FOR rec IN (SELECT cwl.studentpersonnumber
                  FROM coursewaitlist cwl
                  WHERE cwl.coursecode = old.coursecode
                  ORDER BY position) LOOP

        UPDATE coursewaitlist
        SET position = newPosition
        WHERE studentpersonnumber = rec AND coursecode = old.coursecode;

        newPosition := newPosition + 1;
      END LOOP;


    END IF;

  END IF;


  RETURN NULL;
END;
$on_unregistered$ LANGUAGE plpgsql;

CREATE TRIGGER on_registered INSTEAD OF INSERT ON registrations
FOR EACH ROW EXECUTE PROCEDURE on_registered();

CREATE TRIGGER on_unregistered INSTEAD OF DELETE ON registrations
FOR EACH ROW EXECUTE PROCEDURE on_unregistered();