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

-- Usuários
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

-- Instituições
INSERT INTO Institutions (name, email, telephone, document, address)
VALUES
    ('FACENS', 'contato@ufederal.edu.br', '1134567890', '231', 'Rua A, 100'),
    ('UNIP', 'contato@iesup.com.br', '1187654321', '123', 'Rua B, 200'),
    ('FATEC', 'contato@facprivada.com.br', '1143216789', '321', 'Rua C, 300');

-- Cursos
INSERT INTO Courses (name, description, isRequired, requiredTimeLimit, institutionId)
VALUES
    ('Análise de Sistemas', 'Curso de desenvolvimento e análise de sistemas', 1, 60, 1),
    ('Redes de Computadores', 'Estudo das redes e suas infraestruturas', 1, 50, 1),
    ('Marketing Digital', 'Curso de estratégias de marketing na internet', 0, 45, 2),
    ('Desenvolvimento Web', 'Tecnologias para desenvolvimento de sites e aplicativos', 1, 60, 2),
    ('Ciência de Dados', 'Curso de análise e interpretação de dados', 1, 90, 3),
    ('Gestão de Projetos', 'Planejamento e execução de projetos de TI', 1, 40, 3),
    ('Administração de Sistemas', 'Curso de administração de servidores e sistemas', 0, 30, 1),
    ('Engenharia de Software', 'Engenharia para desenvolvimento de software', 1, 70, 2),
    ('Inteligência Artificial', 'Estudo sobre algoritmos de aprendizado de máquina', 1, 80, 3),
    ('Sistemas Embarcados', 'Desenvolvimento de sistemas integrados de hardware e software', 0, 50, 1);

-- Matrículas
INSERT INTO Enrollments (enrollmentDate, userId, courseId)
VALUES
    ('2025-01-05', 1, 1),
    ('2025-01-05', 1, 2),
    ('2025-01-06', 1, 3),
    ('2025-01-06', 1, 4),
    ('2025-01-07', 2, 1),
    ('2025-01-07', 2, 2),
    ('2025-01-08', 2, 5),
    ('2025-01-08', 2, 6),
    ('2025-01-09', 3, 3),
    ('2025-01-09', 3, 7),
    ('2025-01-10', 4, 5),
    ('2025-01-10', 4, 8),
    ('2025-01-11', 5, 4),
    ('2025-01-11', 5, 9),
    ('2025-01-12', 6, 2),
    ('2025-01-12', 6, 3),
    ('2025-01-13', 7, 1),
    ('2025-01-13', 7, 7),
    ('2025-01-14', 8, 3),
    ('2025-01-14', 8, 8);

-- Etapas
INSERT INTO Steps (`order`, title, description, type, content, courseId)
VALUES
    (1, 'Introdução à Análise de Sistemas', 'Conceitos fundamentais de sistemas', 1, 'Material teórico', 1),
    (2, 'Configuração de Redes', 'Configuração de redes de computadores', 2, 'Vídeo explicativo', 2),
    (3, 'SEO e Mídias Sociais', 'Estratégias de SEO para marketing digital', 3, 'Aula prática', 3),
    (4, 'Fundamentos do Desenvolvimento Web', 'Primeiros passos para criar websites', 1, 'Exercício prático', 4),
    (5, 'Estatísticas e Probabilidade', 'Fundamentos para análise de dados', 2, 'Aulas gravadas', 5),
    (6, 'Metodologias Ágeis', 'Gestão de projetos com Scrum', 3, 'Simulação interativa', 6),
    (7, 'Administração de Banco de Dados', 'Introdução ao gerenciamento de bancos', 1, 'Tutorial passo a passo', 7),
    (8, 'Desenvolvimento de Software', 'Estruturas de dados e algoritmos', 3, 'Exercício aplicado', 8),
    (9, 'Aprendizado de Máquina', 'Introdução ao machine learning', 1, 'Material complementar', 9),
    (10, 'Engenharia de Sistemas Embarcados', 'Desenvolvimento de sistemas para dispositivos', 2, 'Estudo de caso', 10);

-- Progresso dos usuários
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

-- Favoritos dos usuários
INSERT INTO FavoritedCourses (courseId, userId, favoriteDate)
VALUES
    (1, 1, '2025-01-06'),
    (2, 1, '2025-01-06'),
    (3, 1, '2025-01-07'),
    (4, 1, '2025-01-07'),
    (5, 2, '2025-01-08'),
    (6, 2, '2025-01-08'),
    (7, 3, '2025-01-09'),
    (8, 3, '2025-01-09'),
    (9, 4, '2025-01-10'),
    (10, 4, '2025-01-10');






