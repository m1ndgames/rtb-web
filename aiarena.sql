-- --------------------------------------------------------
-- Host:                         127.0.0.1
-- Server Version:               10.1.26-MariaDB-0+deb9u1 - Debian 9.1
-- Server Betriebssystem:        debian-linux-gnu
-- HeidiSQL Version:             9.5.0.5196
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;


-- Exportiere Datenbank Struktur für aiarena_db_1
CREATE DATABASE IF NOT EXISTS `aiarena` /*!40100 DEFAULT CHARACTER SET utf8mb4 */;
USE `aiarena`;

-- Exportiere Struktur von Tabelle aiarena.bots
CREATE TABLE IF NOT EXISTS `bots` (
  `author_id` int(11) NOT NULL,
  `author_name` varchar(50) NOT NULL,
  `name` varchar(50) NOT NULL,
  `active` tinyint(4) DEFAULT '0',
  `elo` int(11) DEFAULT '1600',
  `first_upload_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_upload_date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `filename` varchar(50) NOT NULL,
  `filesize` int(11) NOT NULL,
  `md5hash` varchar(50) NOT NULL,
  `bottype` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Daten Export vom Benutzer nicht ausgewählt
-- Exportiere Struktur von Tabelle aiarena.elohistory
CREATE TABLE IF NOT EXISTS `elohistory` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `date` int(11) NOT NULL,
  `elo` int(11) NOT NULL,
  `datetime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=685 DEFAULT CHARSET=utf8mb4;

-- Daten Export vom Benutzer nicht ausgewählt
-- Exportiere Struktur von Tabelle aiarena.results
CREATE TABLE IF NOT EXISTS `results` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `bot_a` varchar(50) NOT NULL,
  `bot_b` varchar(50) NOT NULL,
  `result` varchar(50) NOT NULL,
  `mapname` varchar(50) NOT NULL,
  `replayname` varchar(50) NOT NULL,
  `elochange_bot_a` float NOT NULL,
  `elochange_bot_b` float NOT NULL,
  `date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `gametime` int(11) NOT NULL,
  `winner` varchar(50) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=373 DEFAULT CHARSET=utf8mb4;

-- Daten Export vom Benutzer nicht ausgewählt
-- Exportiere Struktur von Tabelle aiarena.users
CREATE TABLE IF NOT EXISTS `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `password` varchar(50) NOT NULL,
  `email` varchar(50) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4;

-- Daten Export vom Benutzer nicht ausgewählt
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IF(@OLD_FOREIGN_KEY_CHECKS IS NULL, 1, @OLD_FOREIGN_KEY_CHECKS) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;

