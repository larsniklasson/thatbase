DROP TRIGGER IF EXISTS on_registered ON registrations;
DROP TRIGGER IF EXISTS on_unregistered ON registrations;
DROP FUNCTION IF EXISTS on_registered() CASCADE;
DROP FUNCTION IF EXISTS on_unregistered() CASCADE;


CREATE FUNCTION on_registered()
  RETURNS TRIGGER AS $on_registered$
DECLARE
  queuepos INT;
BEGIN

  -- Verify that the student have passed all prerequired courses
  IF ((SELECT COUNT(cpr.courseprerequisitecode) - COUNT(pc.coursecode) AS coursesLeftToRead
       FROM student s
         LEFT JOIN courseprerequisites cpr ON cpr.coursecode = new.coursecode
         LEFT JOIN passedcourses pc
           ON pc.personnumber = s.personnumber AND pc.coursecode = cpr.courseprerequisitecode
       WHERE s.personnumber = new.studentpersonnumber) != 0)

  THEN RAISE EXCEPTION 'Student % have not passed prerequired courses for %', new.studentpersonnumber, new.coursecode;
  END IF;

  -- Have student already passed this course?
  IF ((SELECT COUNT(pc.personnumber)
       FROM passedcourses pc
       WHERE pc.personnumber = new.studentpersonnumber
             AND pc.coursecode = new.coursecode
      ) != 0)
  THEN RAISE EXCEPTION 'Student have already passed this course.';
  END IF;

  -- Is the student already registered?
  IF ((SELECT COUNT(coursecode)
       FROM studentcourseregistered
       WHERE coursecode = new.coursecode
             AND studentpersonnumber = new.studentpersonnumber) > 0)
  THEN
    RAISE EXCEPTION 'Student already registered';
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
    -- Is the course already full
    IF ((SELECT lc.maxnbrstudents - COUNT(scc.coursecode) AS spotsLeft
         FROM course c
           INNER JOIN limitedcourse lc ON lc.coursecode = c.coursecode
           LEFT JOIN studentcourseregistered scc ON c.coursecode = scc.coursecode
         WHERE c.coursecode = new.coursecode
         GROUP BY lc.maxnbrstudents) <= 0)
    THEN

      -- Add to waitlist. placed last.
      queuepos := (SELECT coalesce(max(position) + 1, 1)
                   FROM coursequeuepositions
                   WHERE coursecode = new.coursecode);

      INSERT INTO coursewaitlist (coursecode, studentpersonnumber, position)
      VALUES (new.coursecode, new.studentpersonnumber, queuepos);
      RAISE NOTICE 'Course was full. Student placed in wait list.';

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

  --if waiting, remove and fix the positions (lower down in code)
  IF (old.status = 'waiting')
  THEN
    DELETE FROM coursewaitlist cwl
    WHERE
      cwl.studentpersonnumber = old.studentpersonnumber AND cwl.coursecode = old.coursecode;
  ELSE
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
           FROM coursequeuepositions cwl
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
                              FROM coursequeuepositions cwl
                              WHERE cwl.coursecode = old.coursecode
                              ORDER BY cwl.position ASC
                              LIMIT 1);

        -- Remove person from wait list and register them on the course
        DELETE FROM coursewaitlist cwl
        WHERE cwl.studentpersonnumber = queuePersonNumber AND cwl.coursecode = old.coursecode;
        INSERT INTO studentcourseregistered (studentpersonnumber, coursecode)
        VALUES (queuePersonNumber, old.coursecode);
        RAISE NOTICE 'Registered first person in the waitlist.';


      END IF;

    ELSE --not limited
      RAISE NOTICE 'student removed';

      --queuepositions don't have to be fixed

      RETURN NULL;
    END IF;

  END IF;

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

  RETURN NULL;
END;
$on_unregistered$ LANGUAGE plpgsql;

CREATE TRIGGER on_registered INSTEAD OF INSERT ON registrations
FOR EACH ROW EXECUTE PROCEDURE on_registered();

CREATE TRIGGER on_unregistered INSTEAD OF DELETE ON registrations
FOR EACH ROW EXECUTE PROCEDURE on_unregistered();