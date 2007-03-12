-- app=a700
-- version=5.0

-- --------------------------------------------------------

CREATE TABLE `/*db_name*/`.`/*app*/_project` (
  `ID` bigint(20) unsigned NOT NULL auto_increment,
  `ID_entity` bigint(20) unsigned default NULL,
  `ID_charindex` varchar(64) character set ascii collate ascii_bin default NULL,
  `name` varchar(128) character set utf8 collate utf8_unicode_ci NOT NULL default '',
  `name_url` varchar(128) character set ascii NOT NULL default '',
  `datetime_create` datetime NOT NULL default '0000-00-00 00:00:00',
  `status` char(1) character set ascii NOT NULL default 'N',
  PRIMARY KEY  (`ID`,`datetime_create`),
  UNIQUE KEY `UNI_0` (`ID_entity`),
  UNIQUE KEY `UNI_1` (`ID_charindex`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------