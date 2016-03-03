SELECT *
FROM registrations r
INNER JOIN course c ON r.coursecode = c.coursecode
LEFT JOIN coursequeuepositions cqp ON cqp.coursecode = r.coursecode AND cqp.studentpersonnumber = r.studentpersonnumber;