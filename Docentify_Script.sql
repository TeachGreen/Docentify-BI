DROP DATABASE IF EXISTS Docentify;
CREATE DATABASE IF NOT EXISTS Docentify DEFAULT CHARACTER SET utf8;
USE Docentify;

-- Tabela de Usuários
DROP TABLE IF EXISTS Users;
CREATE TABLE IF NOT EXISTS Users
(
    id             INT          NOT NULL AUTO_INCREMENT,
    name           VARCHAR(150) NOT NULL,
    birthDate      DATE         NOT NULL,
    email          VARCHAR(100) NOT NULL,
    telephone      VARCHAR(45)  NULL,
    gender         CHAR(2)      NULL,
    document       VARCHAR(45)  NOT NULL,
    creationDate   DATETIME     NULL DEFAULT CURRENT_TIMESTAMP,
    updateDate     DATETIME     NULL DEFAULT CURRENT_TIMESTAMP,
    ultima_interacao DATETIME NULL DEFAULT NULL, 
    PRIMARY KEY (id),
    UNIQUE INDEX (email ASC),
    UNIQUE INDEX (document ASC)
);

-- Tabela de Instituições
DROP TABLE IF EXISTS Institutions;
CREATE TABLE IF NOT EXISTS Institutions
(
    id            INT          NOT NULL AUTO_INCREMENT,
    name          VARCHAR(150) NOT NULL,
    email         VARCHAR(100) NOT NULL,
    telephone     VARCHAR(45)  NULL,
    address       VARCHAR(350) NULL,
    document      VARCHAR(45)  NOT NULL,
    creationDate  DATETIME     NULL DEFAULT CURRENT_TIMESTAMP,
    updateDate    DATETIME     NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE INDEX (email ASC),
    UNIQUE INDEX (name ASC),
    UNIQUE INDEX (document ASC)
);

-- Tabela de Cursos
DROP TABLE IF EXISTS Courses;
CREATE TABLE IF NOT EXISTS Courses
(
    id               INT         NOT NULL AUTO_INCREMENT,
    name             VARCHAR(100) NOT NULL,
    description      TEXT        NULL,
    institutionId    INT         NOT NULL,
    isRequired       BIT NULL DEFAULT 0,
    requiredTimeLimit INT NULL DEFAULT 30,
    creationDate     DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
    updateDate       DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    FOREIGN KEY (institutionId) REFERENCES Institutions (id) ON DELETE CASCADE
);

-- Tabela de Etapas (Steps) dentro dos cursos
DROP TABLE IF EXISTS Steps;
CREATE TABLE IF NOT EXISTS Steps
(
    id          INT NOT NULL AUTO_INCREMENT,
    `order`     INT NOT NULL,
    title       VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    type        INT NOT NULL,
    content     TEXT NOT NULL,
    courseId    INT NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (courseId) REFERENCES Courses (id) ON DELETE CASCADE
);

-- Tabela de Atividades dentro das etapas dos cursos
DROP TABLE IF EXISTS Activities;
CREATE TABLE IF NOT EXISTS Activities
(
    id              INT NOT NULL AUTO_INCREMENT,
    allowedAttempts INT NOT NULL DEFAULT 3,
    stepId          INT NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (stepId) REFERENCES Steps (id) ON DELETE CASCADE
);

-- Tabela de Matrículas
DROP TABLE IF EXISTS Enrollments;
CREATE TABLE IF NOT EXISTS Enrollments
(
    id              INT NOT NULL AUTO_INCREMENT,
    enrollmentDate  DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
    isActive        BIT NULL DEFAULT 1,
    userId          INT NOT NULL,
    courseId        INT NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (userId) REFERENCES Users (id) ON DELETE CASCADE,
    FOREIGN KEY (courseId) REFERENCES Courses (id) ON DELETE CASCADE
);

-- Tabela de Progresso do Usuário nos Cursos
DROP TABLE IF EXISTS UserProgress;
CREATE TABLE IF NOT EXISTS UserProgress
(
    enrollmentId  INT NOT NULL,
    stepId        INT NOT NULL,
    progressDate  DATETIME NOT NULL,
    PRIMARY KEY (enrollmentId, stepId),
    FOREIGN KEY (enrollmentId) REFERENCES Enrollments (id) ON DELETE CASCADE,
    FOREIGN KEY (stepId) REFERENCES Steps (id) ON DELETE CASCADE
);

-- Tabela de Favoritos (Cursos Favoritados pelos Usuários)
DROP TABLE IF EXISTS FavoritedCourses;
CREATE TABLE IF NOT EXISTS FavoritedCourses
(
    courseId      INT NOT NULL,
    userId        INT NOT NULL,
    favoriteDate  DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (courseId, userId),
    FOREIGN KEY (courseId) REFERENCES Courses (id) ON DELETE CASCADE,
    FOREIGN KEY (userId) REFERENCES Users (id) ON DELETE CASCADE
);

-- Tabela de Tentativas de Atividades
DROP TABLE IF EXISTS ActivityAttempts;
CREATE TABLE IF NOT EXISTS ActivityAttempts
(
    id          INT NOT NULL AUTO_INCREMENT,
    score       INT NOT NULL,
    date        DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
    userId      INT NOT NULL,
    activityId  INT NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (userId) REFERENCES Users (id) ON DELETE CASCADE,
    FOREIGN KEY (activityId) REFERENCES Activities (id) ON DELETE CASCADE
);

-- Atualiza `ultima_interacao` quando um usuário avança no curso
DELIMITER //
CREATE TRIGGER atualiza_ultima_interacao
AFTER INSERT ON UserProgress
FOR EACH ROW
BEGIN
    UPDATE Users 
    SET ultima_interacao = NOW()
    WHERE id = (SELECT userId FROM Enrollments WHERE id = NEW.enrollmentId LIMIT 1);
END;
//
DELIMITER ;

-- `ultima_interacao` quando o usuário interage com o chatbot
DROP TABLE IF EXISTS ChatbotInteractions;
CREATE TABLE IF NOT EXISTS ChatbotInteractions
(
    id               INT NOT NULL AUTO_INCREMENT,
    userId           INT NOT NULL,
    question         TEXT NOT NULL,
    response         TEXT NOT NULL,
    interactionDate  DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    FOREIGN KEY (userId) REFERENCES Users(id) ON DELETE CASCADE
);

DELIMITER //
CREATE TRIGGER atualiza_ultima_interacao_chatbot
AFTER INSERT ON ChatbotInteractions
FOR EACH ROW
BEGIN
    UPDATE Users 
    SET ultima_interacao = NOW()
    WHERE id = NEW.userId;
END;
//
DELIMITER ;

-- Tabela de Feedbacks do Chatbot
DROP TABLE IF EXISTS ChatbotFeedbacks;
CREATE TABLE IF NOT EXISTS ChatbotFeedbacks
(
    id              INT NOT NULL AUTO_INCREMENT,
    interactionId   INT NOT NULL,
    userId          INT NOT NULL,
    rating          TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comments        TEXT NULL,
    feedbackDate    DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    FOREIGN KEY (interactionId) REFERENCES ChatbotInteractions(id) ON DELETE CASCADE,
    FOREIGN KEY (userId) REFERENCES Users(id) ON DELETE CASCADE
);
-- usuários
INSERT INTO Users (name, birthDate, email, telephone, gender, document)
VALUES
    ('João da Silva', '1985-07-20', 'joao.silva@example.com', '11912345678', 'M', '12345678901'),
    ('Maria Oliveira', '1990-11-15', 'maria.oliveira@example.com', '11987654321', 'F', '23456789012'),
    ('Pedro Santos', '1988-03-25', 'pedro.santos@example.com', '11965432198', 'M', '34567890123'),
    ('Ana Paula', '1975-05-10', 'ana.paula@example.com', '11987654329', 'F', '98765432100'),
    ('Carlos Pereira', '1982-09-12', 'carlos.pereira@example.com', '11923456789', 'M', '45678901234'),
    ('Fernanda Lima', '1995-01-25', 'fernanda.lima@example.com', '11954321876', 'F', '56789012345'),
    ('Roberto Nunes', '1992-04-18', 'roberto.nunes@example.com', '11987651234', 'M', '67890123456'),
    ('Juliana Alves', '1987-12-03', 'juliana.alves@example.com', '11965439876', 'F', '78901234567'),
    ('Eduardo Ramos', '1978-11-22', 'eduardo.ramos@example.com', '11934567890', 'M', '89012345678'),
    ('Camila Rodrigues', '1993-08-30', 'camila.rodrigues@example.com', '11923459876', 'F', '90123456789');

-- instituições
INSERT INTO Institutions (name, email, telephone, document, address)
VALUES
    ('Universidade Federal', 'contato@ufederal.edu.br', '1134567890', '231', 'Rua A, 100'),
    ('Instituto de Educação Superior', 'contato@iesup.com.br', '1187654321', '123', 'Rua B, 200'),
    ('Faculdade Privada', 'contato@facprivada.com.br', '1143216789', '321', 'Rua C, 300');

-- cursos
INSERT INTO Courses (name, description, isRequired, requiredTimeLimit, institutionId)
VALUES
    ('Pedagogia Moderna', 'Abordagens contemporâneas para ensino', 1, 30, 1),
    ('Tecnologia Educacional', 'Uso de tecnologia em sala de aula', 0, 60, 1),
    ('Metodologias Ativas', 'Metodologias inovadoras no ensino', 1, 45, 2),
    ('Didática do Ensino Superior', 'Técnicas e práticas pedagógicas', 0, 40, 3),
    ('Psicopedagogia', 'Fundamentos da psicopedagogia no ensino', 1, 50, 1),
    ('Ensino Híbrido', 'Integração de ensino presencial e online', 0, 30, 2),
    ('Educação Inclusiva', 'Adaptações para ensino inclusivo', 1, 60, 3),
    ('Neuroeducação', 'Ciência cognitiva aplicada ao ensino', 0, 45, 2),
    ('Gamificação na Educação', 'Uso de gamificação para aprendizado', 0, 30, 3),
    ('Letramento Digital', 'Ensino de tecnologia para professores', 1, 50, 1);

-- matrículas de usuários em cursos
INSERT INTO Enrollments (enrollmentDate, userId, courseId)
VALUES

    ('2025-01-05', 1, 1),
    ('2025-01-06', 2, 1),
    ('2025-01-07', 3, 1),
    ('2025-01-08', 4, 2),
    ('2025-01-09', 5, 2),
    ('2025-01-10', 6, 3),
    ('2025-01-11', 7, 3),
    ('2025-01-12', 8, 3),
    ('2025-01-13', 9, 4),
    ('2025-01-14', 10, 4),
    ('2025-01-15', 2, 6),
    ('2025-01-16', 3, 7),
    ('2025-01-17', 4, 7),
    ('2025-01-18', 5, 7),
    ('2025-01-19', 6, 9),
    ('2025-01-20', 7, 9);

-- etapas para cursos
INSERT INTO Steps (`order`, title, description, type, content, courseId)
VALUES
    (1, 'Introdução à Pedagogia', 'Conceitos fundamentais', 1, 'Material introdutório', 1),
    (2, 'Fundamentos Tecnológicos', 'Ferramentas para ensino digital', 2, 'Vídeo explicativo', 2),
    (3, 'Metodologias Ativas', 'Práticas interativas', 3, 'Atividade prática', 3),
    (4, 'Didática no Ensino Superior', 'Técnicas para professores', 1, 'Documento PDF', 4),
    (5, 'Psicopedagogia na Prática', 'Estudos de caso', 2, 'Casos reais', 5),
    (6, 'Ensino Híbrido e sua Aplicação', 'Como equilibrar o ensino presencial e digital', 3, 'Simulação interativa', 6),
    (7, 'Educação Inclusiva', 'Acessibilidade no ensino', 1, 'Guia detalhado', 7),
    (8, 'Neuroeducação Aplicada', 'Como o cérebro aprende', 2, 'Animação ilustrativa', 8),
    (9, 'Gamificação na Educação', 'Engajamento estudantil', 3, 'Exemplo prático', 9),
    (10, 'Letramento Digital', 'Habilidades digitais para educadores', 1, 'Manual técnico', 10);

-- progresso dos usuários nos cursos
INSERT INTO UserProgress (enrollmentId, stepId, progressDate)
VALUES
    (1, 1, '2025-01-06'),
    (2, 2, '2025-01-07'),
    (3, 3, '2025-01-08'),
    (4, 4, '2025-01-09'),
    (5, 5, '2025-01-10'),
    (6, 6, '2025-01-11'),
    (7, 7, '2025-01-12'),
    (8, 8, '2025-01-13'),
    (9, 9, '2025-01-14'),
    (10, 10, '2025-01-15');

-- cursos favoritos dos usuários
INSERT INTO FavoritedCourses (courseId, userId, favoriteDate)
VALUES
    (1, 1, '2025-01-06'),
    (2, 2, '2025-01-07'),
    (3, 3, '2025-01-08'),
    (4, 4, '2025-01-09'),
    (5, 5, '2025-01-10'),
    (6, 6, '2025-01-11'),
    (7, 7, '2025-01-12'),
    (8, 8, '2025-01-13'),
    (9, 9, '2025-01-14'),
    (10, 10, '2025-01-15');

-- atividades para os cursos
INSERT INTO Activities (allowedAttempts, stepId)
VALUES
    (3, 1),
    (3, 2),
    (3, 3),
    (3, 4),
    (3, 5),
    (3, 6),
    (3, 7),
    (3, 8),
    (3, 9),
    (3, 10);

-- tentativas de atividades dos usuários
INSERT INTO ActivityAttempts (score, date, userId, activityId)
VALUES
    (80, '2025-01-07', 1, 1),
    (85, '2025-01-08', 2, 2),
    (90, '2025-01-09', 3, 3),
    (70, '2025-01-10', 4, 4),
    (95, '2025-01-11', 5, 5),
    (88, '2025-01-12', 6, 6),
    (92, '2025-01-13', 7, 7),
    (87, '2025-01-14', 8, 8),
    (81, '2025-01-15', 9, 9),
    (79, '2025-01-16', 10, 10);

-- interações no chatbot
INSERT INTO ChatbotInteractions (userId, question, response)
VALUES
    (1, 'Como acessar meus cursos?', 'Você pode acessar seus cursos na aba "Meus Cursos".'),
    (2, 'Como gerar o certificado?', 'Seu certificado será gerado automaticamente após a conclusão.');

-- feedback do chatbot
INSERT INTO ChatbotFeedbacks (interactionId, userId, rating, comments)
VALUES
    (1, 1, 5, 'Ótima resposta!'),
    (2, 2, 4, 'Foi útil, mas poderia ter mais detalhes.');

