/* =========================================================
   RaceDay Database Script
   Part 1 - System Architecture & Database Planning
   Target: Microsoft SQL Server (tested in SSMS)
   Run on a clean SQL Server instance. Safe to re-run.
   ========================================================= */

USE MASTER;
GO
IF DB_ID('RaceDayDB') IS NOT NULL
BEGIN
    ALTER DATABASE RaceDayDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE RaceDayDB;
END
GO

CREATE DATABASE RaceDayDB;
GO

USE RaceDayDB;
GO

/* =========================================================
   TABLES
   ========================================================= */

CREATE TABLE Role (
    RoleId      INT IDENTITY(1,1) PRIMARY KEY,
    RoleName    VARCHAR(20) NOT NULL UNIQUE
        CHECK (RoleName IN ('Organiser', 'Participant'))
);
GO

CREATE TABLE [User] (
    UserId          INT IDENTITY(1,1) PRIMARY KEY,
    FirstName       VARCHAR(50)  NOT NULL,
    LastName        VARCHAR(50)  NOT NULL,
    Email           VARCHAR(100) NOT NULL UNIQUE,
    PasswordHash    VARCHAR(255) NOT NULL,
    RoleId          INT NOT NULL,
    CreatedAt       DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_User_Role FOREIGN KEY (RoleId) REFERENCES Role(RoleId)
);
GO

CREATE TABLE Event (
    EventId         INT IDENTITY(1,1) PRIMARY KEY,
    Name            VARCHAR(100)  NOT NULL,
    Description     VARCHAR(500)  NULL,
    EventDate       DATE          NOT NULL,
    Location        VARCHAR(150)  NOT NULL,
    ImageUrl        VARCHAR(500)  NULL,
    OrganiserId     INT           NOT NULL,
    CreatedAt       DATETIME2      NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_Event_Organiser FOREIGN KEY (OrganiserId) REFERENCES [User](UserId)
);
GO

CREATE TABLE Category (
    CategoryId      INT IDENTITY(1,1) PRIMARY KEY,
    EventId         INT           NOT NULL,
    Name            VARCHAR(50)   NOT NULL,
    DistanceKm      DECIMAL(5,2)  NOT NULL,
    MaxParticipants INT           NOT NULL DEFAULT 100,
    EntryFee        DECIMAL(8,2)  NOT NULL DEFAULT 0,
    CONSTRAINT FK_Category_Event FOREIGN KEY (EventId) REFERENCES Event(EventId) ON DELETE CASCADE,
    CONSTRAINT UQ_Category_EventName UNIQUE (EventId, Name)
);
GO

CREATE TABLE Enrolment (
    EnrolmentId     INT IDENTITY(1,1) PRIMARY KEY,
    ParticipantId   INT           NOT NULL,
    CategoryId      INT           NOT NULL,
    EnrolmentDate   DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    Status          VARCHAR(20)   NOT NULL DEFAULT 'Confirmed'
        CHECK (Status IN ('Confirmed', 'Cancelled')),
    CONSTRAINT FK_Enrolment_Participant FOREIGN KEY (ParticipantId) REFERENCES [User](UserId),
    CONSTRAINT FK_Enrolment_Category FOREIGN KEY (CategoryId) REFERENCES Category(CategoryId),
    CONSTRAINT UQ_Enrolment_Participant_Category UNIQUE (ParticipantId, CategoryId)
);
GO

CREATE TABLE Result (
    ResultId          INT IDENTITY(1,1) PRIMARY KEY,
    EnrolmentId       INT      NOT NULL UNIQUE,
    FinishTime        TIME     NOT NULL,
    Position          INT      NULL,
    RecordedByUserId  INT      NOT NULL,
    RecordedAt        DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_Result_Enrolment FOREIGN KEY (EnrolmentId) REFERENCES Enrolment(EnrolmentId) ON DELETE CASCADE,
    CONSTRAINT FK_Result_RecordedBy FOREIGN KEY (RecordedByUserId) REFERENCES [User](UserId)
);
GO

/* =========================================================
   SEED DATA
   ========================================================= */

INSERT INTO Role (RoleName) VALUES ('Organiser'), ('Participant');
GO

-- 2 Organisers, 2+ Participants
INSERT INTO [User] (FirstName, LastName, Email, PasswordHash, RoleId) VALUES
('Amanda', 'Reyes',   'amanda.reyes@raceday.com',   'AMANDA123', 1),
('Sipho',  'Ndlovu',  'sipho.ndlovu@raceday.com',    'SIPHO123', 1),
('Liam',   'Fischer', 'liam.fischer@example.com',    'LIAM123', 2),
('Priya',  'Naidoo',  'priya.naidoo@example.com',    'PRIYA123', 2),
('Chloe',  'Adams',   'chloe.adams@example.com',     'CHLOE123', 2);
GO

-- 3+ Events (owned by the 2 organisers)
INSERT INTO Event (Name, Description, EventDate, Location,ImageUrl, OrganiserId) VALUES
('City Marathon 2026',        'Annual road running event through the city center.', '2026-11-14', 'Cape Town CBD', 'http://example.com/city_marathon_2026.jpg',      1),
('Riverside Fun Run',         'Family-friendly run along the river trail.',          '2026-10-03', 'Riverside Park','http://example.com/riverside_fun_run.jpg',     1),
('Mountain Trail Challenge',  'Off-road trail race with elevation.',                 '2026-12-05', 'Table Mountain Reserve', 'http://example.com/mountain_trail_challenge.jpg', 2);
GO

-- Multiple categories per event
INSERT INTO Category (EventId, Name, DistanceKm, MaxParticipants, EntryFee) VALUES
(1, '10km',     10.00, 500, 150.00),
(1, '21km',     21.10, 300, 250.00),
(1, 'Marathon', 42.20, 200, 350.00),
(2, '5km',       5.00, 400,  80.00),
(2, '10km',     10.00, 300, 120.00),
(3, '15km Trail',15.00, 150, 200.00),
(3, '30km Trail',30.00, 100, 300.00);
GO

-- Sample enrolments
INSERT INTO Enrolment (ParticipantId, CategoryId, Status) VALUES
(3, 1, 'Confirmed'),  -- Liam in Event1 10km
(4, 2, 'Confirmed'),  -- Priya in Event1 21km
(5, 4, 'Confirmed'),  -- Chloe in Event2 5km
(3, 6, 'Confirmed'),  -- Liam in Event3 15km Trail
(4, 1, 'Confirmed');  -- Priya in Event1 10km
GO


INSERT INTO Result (EnrolmentId, FinishTime, Position, RecordedByUserId) VALUES
(1, '00:52:14', 3, 1),
(2, '01:58:40', 1, 1),
(3, '00:24:05', 2, 1),
(5, '00:49:30', 1, 1);
GO
