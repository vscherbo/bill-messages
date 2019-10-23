
-- Drop table

-- DROP TABLE arc_energo.send_problem;

CREATE TABLE arc_energo.send_problem (
    id serial NOT NULL,
    dt_insert timestamp DEFAULT now(),
    mail_srv varchar NOT NULL,
    msg_qid varchar NOT NULL,
    msg_to varchar NULL,
    msg_diag varchar NULL,
    CONSTRAINT send_problem_pk PRIMARY KEY (id)
);
